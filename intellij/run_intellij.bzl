load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "cc_binary")


def _run_with_ide_src_impl(ctx):
    out = ctx.actions.declare_file("ide_with_plugin_runner.cpp")

    intellij = ctx.toolchains["@rules_intellij//intellij:intellij_toolchain_type"].intellij

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out,
        substitutions = {
            "{binary}": "external/idea_ultimate/binary", #intellij.binary.short_path,
            "{plugins_dir}": "ide_plugins", #paths.dirname(intellij.plugins[0].short_path),
            "{jvm_flags}": "\n".join(['"%s",' % x for x in ctx.attr.jvm_flags])
        },
    )
    return DefaultInfo(
        files = depset([out]),
        runfiles = ctx.runfiles(files= intellij.plugins + [ intellij.binary ])
    )


_run_with_ide_src = rule(
    implementation = _run_with_ide_src_impl,
    attrs = {
        "jvm_flags": attr.string_list(),
        "_template": attr.label(
            default = "@rules_intellij//src/main/cpp/ide_with_plugin_runner:ide_with_plugin_runner.cpp.tp",
            allow_single_file = True,
        ),
    },
    toolchains = [
        "@rules_intellij//intellij:intellij_toolchain_type",
    ],
)


def run_intellij(name, jvm_flags, args):
   _run_with_ide_src(
       name = "_%s_run_src" % name,
       jvm_flags = jvm_flags,
   )
   cc_binary(
       name = name,
       args = args,
       srcs = [ ":_%s_run_src" % name ],
       data = [ "@idea_ultimate//:binary", ],
       deps = [ "@bazel_tools//tools/cpp/runfiles"],
       tags = [ "local" ],
       visibility = ["//visibility:public"],
   )