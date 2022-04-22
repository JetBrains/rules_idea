load("@bazel_skylib//lib:paths.bzl", "paths")

IntelliJIndexInfo = provider(
    doc = "Information about intellij indexing",
    fields = {
        "ijx": "index file",
        "metadata": "metadata json file",
        "sha256": "sha sum"
    },
)

def _map_path(x):
    return x.path

def _run_indexing(ctx, intellij_project, inputs):
    out_ijx = ctx.actions.declare_file("%s.ijx" % ctx.rule.attr.name)
    out_meta = ctx.actions.declare_file("%s.ijx.metadata.json" % ctx.rule.attr.name)
    out_sha256 = ctx.actions.declare_file("%s.ijx.sha256" % ctx.rule.attr.name)
    outputs = [out_ijx, out_meta, out_sha256]

    args = ctx.actions.args()
    if ctx.attr._debug_log:
        args.add_all("--debug_log", [ctx.attr._debug_log])
    if ctx.attr._debug_endpoint:
        args.add_all("--debug_endpoint", [ctx.attr._debug_endpoint])
    worker_arg_file = ctx.actions.declare_file(ctx.rule.attr.name + ".worker_args")

    args.add_all("--project_dir", [intellij_project.project_dir])
    args.add_all("--out_dir", [paths.dirname(out_ijx.path)])
    args.add_all("--target", [str(ctx.label)])
    args.add_all("--name", [ctx.rule.attr.name])
    args.add_all(inputs, map_each=_map_path, before_each="-s")

    ctx.actions.write(
        output = worker_arg_file,
        content = args,
    )
    ctx.actions.run(
        mnemonic = "IntellijIndexing",
        executable = ctx.executable._worker,
        inputs = inputs + [worker_arg_file] + intellij_project.project_files,
        outputs = outputs,
        execution_requirements = {
            "worker-key-mnemonic": "IntellijIndexing",
            "supports-workers": "1",
            "supports-multiplex-workers": "1",
            "requires-worker-protocol": "proto",
        },
        arguments = [args] + ["@" + worker_arg_file.path],
    )
    return IntelliJIndexInfo(
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

def _indexing_aspect_impl(target, ctx):
    indexed = _run_indexing(
        ctx = ctx,
        intellij_project = ctx.toolchains["@rules_intellij//intellij:intellij_project_toolchain_type"].intellij_project,
        inputs = _collect_sources_to_index(ctx),
    )
    return [
        indexed,
        OutputGroupInfo(indexed_files = depset([
            indexed.ijx,
            indexed.metadata,
            indexed.sha256,
        ])),
    ]

indexing_aspect = aspect(
    implementation = _indexing_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_worker": attr.label(
            default = "@rules_intellij//src/main/java/rules_intellij/worker:indexing",
            executable = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_intellij//intellij:intellij_project_toolchain_type"],
)

debug_indexing_aspect = aspect(
    implementation = _indexing_aspect_impl,
    attr_aspects = ["deps"],
    attrs = {
        "_worker": attr.label(
            default = "@rules_intellij//src/main/java/rules_intellij/worker:indexing",
            executable = True,
            cfg = "exec",
        ),
        "_debug_log": attr.string(default = "/tmp/indexing_worker_debug.log"),
        "_debug_endpoint": attr.string(default = "127.0.0.1:9000"),
    },
    toolchains = ["@rules_intellij//intellij:intellij_project_toolchain_type"],
)
