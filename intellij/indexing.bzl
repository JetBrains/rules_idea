load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_intellij//intellij:intellij_project.bzl", "IntellijProject")
load("@rules_intellij//intellij:intellij_toolchain.bzl", "Intellij")

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


def _stringify_label(l):
    result = str(l)
    if result.startswith("@"):
        return result[1:]
    return result

def _stringify_name(n):
    return n.replace("/", "_")

def _create_worker_defs(ctx, intellij, intellij_project, java_runtime):
    env = {}
    if hasattr(ctx.attr, "_debug_log"):
        env["INTELLIJ_WORKER_DEBUG"] = ctx.attr._debug_log

    worker_args = ctx.actions.args()
    worker_args.add_all("--project_dir", [ intellij_project.project_dir ])

    tools = []
    tools += intellij_project.project_files

    if hasattr(ctx.attr, "_debug_endpoint"):
        worker_args.add_all("--debug_endpoint", [ ctx.attr._debug_endpoint ])
    elif hasattr(ctx.attr, "_debug_domain_socket"):
        worker_args.add_all("--debug_domain_socket", [ ctx.attr._debug_domain_socket ])
    else:
        worker_args.add_all("--java_binary", [ java_runtime.java_executable_exec_path ])
        worker_args.add_all("--ide_home_dir", [ intellij.home_directory ])
        worker_args.add_all("--ide_binary", [ intellij.binary.path ])
        worker_args.add_all("--plugins_directory", [ paths.dirname(intellij.plugins[0].path) ])

        tools += java_runtime.files.to_list()
        tools += intellij.files + [ intellij.binary ]
        tools += intellij.plugins

    return struct(
        tools = tools,
        args = [ worker_args ],
        env = env,
    )


def _create_indexing_defs(ctx, inputs):
    name = _stringify_name(ctx.rule.attr.name)

    info = IntellijIndexInfo(
       ijx = ctx.actions.declare_file("%s.ijx" % name),
       metadata = ctx.actions.declare_file("%s.ijx.metadata.json" % name),
       sha256 = ctx.actions.declare_file("%s.ijx.sha256" % name),
    )

    args_file = ctx.actions.declare_file(ctx.rule.attr.name + "_args_file")

    indexing_args = ctx.actions.args()
    indexing_args.add_all("--out_dir", [ paths.dirname(info.ijx.path) ])
    indexing_args.add_all("--target", [ _stringify_label(ctx.label) ])
    indexing_args.add_all("--name", [ name ])
    indexing_args.add_all(inputs, map_each=_map_path, before_each="-s")

    ctx.actions.write(
        output = args_file,
        content = indexing_args,
    )

    return struct(
        info = info,
        args_file = args_file,
        inputs = inputs + [ args_file ],
        outputs = [
            info.ijx,
            info.metadata,
            info.sha256,
        ],
    )


def _run_indexing(ctx, intellij, intellij_project, java_runtime, inputs):
    worker_defs = _create_worker_defs(ctx, intellij, intellij_project, java_runtime)
    indexing_defs = _create_indexing_defs(ctx, inputs)

    ctx.actions.run(
        mnemonic = "IntellijIndexing",
        executable = ctx.executable._worker,
        tools = worker_defs.tools,
        inputs = indexing_defs.inputs,
        outputs = indexing_defs.outputs,
        env = worker_defs.env,
        execution_requirements = {
            "worker-key-mnemonic": "IntellijIndexing",
            "supports-multiplex-workers": "1",
            "requires-worker-protocol": "proto",
        },
        arguments = worker_defs.args + ["@" + indexing_defs.args_file.path],
    )
    return indexing_defs.info


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
#        "_debug_log": attr.string(default = "/tmp/intellij_debug"),
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

    return [ OutputGroupInfo(indexed_files = depset(all_indexed_files)), ]


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
    _generate_indexes(
        name = name, 
        deps = deps,
    )