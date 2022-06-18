load("@bazel_skylib//lib:paths.bzl", "paths")
load("@rules_cc//cc:defs.bzl", "cc_binary")


_HOME_PATH = "idea.home.path"
_CONFIG_PATH = "idea.config.path"
_SYSTEM_PATH = "idea.system.path"
_PLUGINS_PATH = "idea.plugins.path"
_INDEXES_JSON_PATH = "local.project.shared.index.json.path"

def _run_with_ide_src_impl(ctx):
    out = ctx.actions.declare_file("ide_with_plugin_runner.cpp")

    intellij = ctx.toolchains["@rules_intellij//intellij:intellij_toolchain_type"].intellij
    intellij_project = ctx.toolchains["@rules_intellij//intellij:intellij_project_toolchain_type"].intellij_project
    java_runtime = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"].java_runtime
    jvm_props = {} 
    jvm_props.update(ctx.attr.jvm_props)

    if not _HOME_PATH in jvm_props:
        jvm_props[_HOME_PATH] = intellij.home_directory

    if not _PLUGINS_PATH in jvm_props:
        jvm_props[_PLUGINS_PATH] = intellij.plugins_directory

    if _CONFIG_PATH in jvm_props and ctx.attr.config_dir:
        fail("%s already in jvm_props, but also config_dir attribute specified" % _CONFIG_PATH)
    elif ctx.attr.config_dir:
        jvm_props[_CONFIG_PATH] = ctx.attr.config_dir

    if _SYSTEM_PATH in jvm_props and ctx.attr.system_dir:
        fail("%s already in jvm_props, but also system_dir attribute specified" % _SYSTEM_PATH)
    elif ctx.attr.config_dir:
        jvm_props[_SYSTEM_PATH] = ctx.attr.system_dir

    if _INDEXES_JSON_PATH in jvm_props and ctx.file.indexes:
        fail("%s already in jvm_props, but also indexes attribute specified" % _INDEXES_JSON_PATH)
    elif ctx.attr.indexes:
        jvm_props[_INDEXES_JSON_PATH] = ctx.file.indexes.path

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out,
        substitutions = {
            "{java}": java_runtime.java_executable_exec_path,
            "{binary}": intellij.binary_path,
            "{jvm_flags}": "\n".join(['"-D%s=%s",' % (k, v) for k,v in jvm_props.items()])
        },
    )
    return DefaultInfo(
        files = depset([out]),
        runfiles = ctx.runfiles(files =
            [intellij.binary] 
            + intellij.plugins 
            + intellij.files 
            + java_runtime.files.to_list()
        )
    )


_run_with_ide_src = rule(
    implementation = _run_with_ide_src_impl,
    attrs = {
        "indexes": attr.label(allow_single_file = True),
        "config_dir": attr.string(),
        "system_dir": attr.string(),
        "jvm_props": attr.string_dict(),
        "_template": attr.label(
            default = "@rules_intellij//src/main/cpp/intellij_runner:intellij_runner.cpp.tp",
            allow_single_file = True,
        ),
    },
    toolchains = [
        "@rules_intellij//intellij:intellij_toolchain_type",
        "@rules_intellij//intellij:intellij_project_toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
)


def run_intellij(
    name,
    jvm_props = {},
    args = [],
    indexes = None,
    config_dir = None,
    system_dir = None
):
    _run_with_ide_src(
        name = "_%s_run_src" % name,
        indexes = indexes,
        config_dir = config_dir,
        system_dir = system_dir,
        jvm_props = jvm_props,
    )
    cc_binary(
        name = name,
        args = args,
        srcs = [ ":_%s_run_src" % name ],
        data = [ ":_%s_run_src" % name ] + [ indexes ] if indexes else [],
        tags = [ "local" ],
        visibility = ["//visibility:public"],
    )