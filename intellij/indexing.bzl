load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_intellij//intellij:intellij_project.bzl", "IntellijProject")
load("@rules_intellij//intellij:intellij_toolchain.bzl", "Intellij")
#load("@rules_intellij//intellij:run_intellij.bzl", "run_intellij")

IntellijIndexInfo = provider(
    doc = "Information about intellij target indexes",
    fields = {
        "ijx": "index file",
        "metadata": "metadata json file",
        "sha256": "sha sum"
    },
)


IntellijTransitiveIndexInfo = provider(
    doc = "Transitive information about intellij target indexes",
    fields = {
        "index": "IntellijIndexInfo",
        "transitive": "transitive IntellijIndexInfo",
    },
)


def _map_path(x):
    return x.path

def _run_indexing(ctx, intellij, intellij_project, java_runtime, inputs):
    out_ijx = ctx.actions.declare_file("%s.ijx" % ctx.rule.attr.name)
    out_meta = ctx.actions.declare_file("%s.ijx.metadata.json" % ctx.rule.attr.name)
    out_sha256 = ctx.actions.declare_file("%s.ijx.sha256" % ctx.rule.attr.name)
    outputs = [out_ijx, out_meta, out_sha256]

    args = ctx.actions.args()
    if hasattr(ctx.attr, "_debug_log"):
        args.add_all("--debug_log", [ ctx.attr._debug_log ])

    tools = []
    more_inputs = []
    if hasattr(ctx.attr, "_debug_endpoint"):
        args.add_all("--debug_endpoint", [ ctx.attr._debug_endpoint ])
    elif hasattr(ctx.attr, "_debug_domain_socket"):
        args.add_all("--debug_domain_socket", [ ctx.attr._debug_domain_socket ])
    else:
        args.add_all("--java_binary", [ java_runtime.java_executable_exec_path ])
        tools += java_runtime.files.to_list()
        args.add_all("--ide_home_dir", [ intellij.home_directory ])
        args.add_all("--ide_binary", [ intellij.binary.path ])
        tools += intellij.files + [ intellij.binary ]
        args.add_all("--plugins_directory", [ paths.dirname(intellij.plugins[0].path) ])
        more_inputs += intellij.plugins

    worker_arg_file = ctx.actions.declare_file(ctx.rule.attr.name + ".worker_args")

    args.add_all("--project_dir", [ intellij_project.project_dir ])
    args.add_all("--out_dir", [ paths.dirname(out_ijx.path) ])
    args.add_all("--target", [ str(ctx.label) ])
    args.add_all("--name", [ ctx.rule.attr.name ])
    args.add_all(inputs, map_each=_map_path, before_each="-s")

    ctx.actions.write(
        output = worker_arg_file,
        content = args,
    )
    ctx.actions.run(
        mnemonic = "IntellijIndexing",
        executable = ctx.executable._worker,
        tools = tools,
        inputs = inputs + more_inputs + [ worker_arg_file ] + intellij_project.project_files,
        outputs = outputs,
        execution_requirements = {
            "worker-key-mnemonic": "IntellijIndexing",
            "supports-workers": "1",
            "supports-multiplex-workers": "1",
            "requires-worker-protocol": "proto",
        },
        arguments = [args] + ["@" + worker_arg_file.path],
    )
    return IntellijIndexInfo(
        ijx = out_ijx,
        metadata = out_meta,
        sha256 = out_sha256,
    )


def _collect_sources_to_index(ctx):
    to_index = []
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            to_index.append(src.files)

    return depset(transitive = to_index).to_list()


def _collect_transitive_index_infos(deps):
    cur = []
    transitive = []

    for dep in deps:
        if not IntellijTransitiveIndexInfo in dep:
            continue

        index_info = dep[IntellijTransitiveIndexInfo]
        cur.append(index_info.index)
        transitive.append(index_info.transitive)

    return depset(cur, transitive = transitive)


def _indexing_aspect_impl(target, ctx):
    indexed = _run_indexing(
        ctx = ctx,
        intellij = ctx.toolchains["@rules_intellij//intellij:intellij_toolchain_type"].intellij,
        intellij_project = ctx.toolchains["@rules_intellij//intellij:intellij_project_toolchain_type"].intellij_project,
        java_runtime = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"].java_runtime,
        inputs = _collect_sources_to_index(ctx),
    )
    return [
        IntellijTransitiveIndexInfo(
            index = indexed,
            transitive = _collect_transitive_index_infos(
                ctx.rule.attr.deps if hasattr(ctx.rule.attr, "deps") else []
            ),
        ),
        OutputGroupInfo(indexed_files = depset([
            indexed.ijx,
            indexed.metadata,
            indexed.sha256,
        ])),
    ]


_indexing_aspect = aspect(
    implementation = _indexing_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_worker": attr.label(
            default = "@rules_intellij//src/main/kotlin/rules_intellij/worker",
            executable = True,
            cfg = "exec",
        ),
#        "_debug_log": attr.string(default = "/tmp/indexing_worker_debug.log"),
#        "_debug_domain_socket": attr.string(default = "/tmp/test.sock"),
#        "_debug_endpoint": attr.string(default = "127.0.0.1:9000"),
    },
    toolchains = [
        "@rules_intellij//intellij:intellij_project_toolchain_type",
        "@rules_intellij//intellij:intellij_toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)


def _generate_indexes_impl(ctx):
    index_infos = _collect_transitive_index_infos(ctx.attr.deps).to_list()
    all_indexed_files = []
    for indexed in index_infos:
        all_indexed_files += [
            indexed.ijx,
            indexed.metadata,
            indexed.sha256,
        ]

    return [
        OutputGroupInfo(indexed_files = depset(all_indexed_files)),
    ]


_generate_indexes = rule(
    implementation = _generate_indexes_impl,
    attrs = {
        "deps": attr.label_list(
            allow_empty = False,
            mandatory = True,
            aspects = [ _indexing_aspect ],
            providers = [ IntellijTransitiveIndexInfo ],
        ),
    },
)

def generate_indexes(name, deps):
#    run_intellij(
#        name = "%s_run" % name,
#        config_dir = "__%s_config" % name,
#        system_dir = "__%s_system_dir" % name,
#        jvm_props = {
#            "idea.platform.prefix": "Idea",
#            "idea.initially.ask.config": "false",
#            "idea.skip.indices.initialization": "true",
#            "idea.force.dumb.queue.tasks": "true",
#            "idea.suspend.indexes.initialization": "true",
#            "intellij.disable.shared.indexes": "true",
#            "shared.indexes.download": "false",
#            "intellij.hash.as.local.file.timestamp": "true",
#            "idea.trust.all.projects": "true",
#        },
#        args = [
#            "dump-shared-index",
#            "persistent-project",
#        ],
#    )
    _generate_indexes(
        name = name, 
        deps = deps,
    )