load("@rules_java//java:defs.bzl", "java_library")
load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("@bazel_skylib//rules/private:copy_file_private.bzl", "copy_bash", "copy_cmd")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "cc_binary")

def _plugin_layout_impl(ctx):
    java_info = ctx.attr.src[JavaInfo]
    all_outs = []

    for jar in [ x for x in java_info.transitive_runtime_deps.to_list() + java_info.compile_jars.to_list() ]:
        if jar.owner.workspace_name in ctx.attr.to_skip:
            print("Skip - %s" % jar)
            continue

        out = ctx.actions.declare_file("plugins/%s/lib/%s" % (
            ctx.attr.name,
            jar.basename
        ))
        if ctx.attr.is_windows:
            copy_cmd(ctx, jar, out)
        else:
            copy_bash(ctx, jar, out)
        all_outs.append(out)

    return DefaultInfo(
        files = depset(all_outs),
        runfiles = ctx.runfiles(files = all_outs),
    )

_plugin_layout = rule(
    implementation = _plugin_layout_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            providers=[ JavaInfo ],
        ),
        "to_skip": attr.string_list(default = []),
        "is_windows": attr.bool(mandatory = True),
    },
)


def _run_with_ide_src_impl(ctx):
    out = ctx.actions.declare_file("ide_with_plugin_runner.cpp")

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out,
        substitutions = {
            "{ide_repo}": ctx.attr.ide_repo,
            "{plugins_dir}": "%s/plugins" % paths.dirname(ctx.build_file_path),
        },
    )
    return DefaultInfo(files = depset([out]))


_run_with_ide_src = rule(
    implementation = _run_with_ide_src_impl,
    attrs = {
        "ide_repo": attr.string(mandatory = True),
        "_template": attr.label(
            default = "@rules_intellij//src/main/cpp/ide_with_plugin_runner:ide_with_plugin_runner.cpp.tp",
            allow_single_file = True,
        ),
    },
)

def wrap_plugin(
    name, 
    ide_repo, 
    srcs, 
    deps, 
    resources = [], 
    ide_plugins = []
):
    java_library(
        name = "%s_ide_deps" % name,
        exports = 
            [ "@%s//:libs" % ide_repo ] + 
            [ "@%s//plugins:%s" % (ide_repo, x) for x in ide_plugins ],
        neverlink = 1,
    )
    kt_jvm_library(
        name = "%s_lib" % name,
        srcs = srcs,
        deps = deps + [ "%s_ide_deps" % name, ],
        resources = resources,
        visibility = ["//visibility:public"],
    )
    _plugin_layout(
        name = name,
        src =  "%s_lib" % name,
        to_skip = [ ide_repo ],
        is_windows = select({
            "@bazel_tools//src/conditions:host_windows": True,
            "//conditions:default": False,
        }),
        visibility = ["//visibility:public"],
    )
    _run_with_ide_src(
        name = "_%s_run_src" % name,
        ide_repo = ide_repo,
    )
    cc_binary(
        name =  "%s_run" % name,
        srcs = [  ":_%s_run_src" % name ],
        data = [  ":%s" % name ] + [ "@%s//:bin" % ide_repo ],
        visibility = ["//visibility:public"],
    )