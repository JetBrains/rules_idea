_HOME_PATH = "idea.home.path"
_CONFIG_PATH = "idea.config.path"
_SYSTEM_PATH = "idea.system.path"
_PLUGINS_PATH = "idea.plugins.path"
_INDEXES_JSON_PATH = "local.project.shared.index.json.path"

def _run_intellij_impl(ctx):
    out = ctx.actions.declare_file("%s.sh" % ctx.attr.name)

    intellij = ctx.toolchains["@rules_intellij//intellij:intellij_toolchain_type"].intellij
    intellij_project = ctx.toolchains["@rules_intellij//intellij:intellij_project_toolchain_type"].intellij_project
    java_runtime = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"].java_runtime
    jvm_props = {
        "java.system.class.loader": "com.intellij.util.lang.PathClassLoader",
    } 
    jvm_props.update(ctx.attr.jvm_props)

    if not _HOME_PATH in jvm_props:
        jvm_props[_HOME_PATH] = intellij.home_directory

    if not _PLUGINS_PATH in jvm_props:
        jvm_props[_PLUGINS_PATH] = intellij.plugins_directory

    if _CONFIG_PATH in jvm_props and ctx.attr.config_dir:
        fail("%s already in jvm_props, but also config_dir attribute specified" % _CONFIG_PATH)
    elif ctx.attr.config_dir:
        jvm_props[_CONFIG_PATH] = ctx.attr.config_dir
    else:
        jvm_props[_CONFIG_PATH] = "~/.rules_intellij/%s/config" % intellij.id

    if _SYSTEM_PATH in jvm_props and ctx.attr.system_dir:
        fail("%s already in jvm_props, but also system_dir attribute specified" % _SYSTEM_PATH)
    elif ctx.attr.system_dir:
        jvm_props[_SYSTEM_PATH] = ctx.attr.system_dir
    else:
        jvm_props[_SYSTEM_PATH] = "~/.rules_intellij/%s/system" % intellij.id

    if _INDEXES_JSON_PATH in jvm_props and ctx.file.indexes:
        fail("%s already in jvm_props, but also indexes attribute specified" % _INDEXES_JSON_PATH)
    elif ctx.attr.indexes:
        jvm_props[_INDEXES_JSON_PATH] = ctx.file.indexes.path

    ctx.actions.expand_template(
        template = ctx.file._template,
        output = out,
        substitutions = {
            "%%binary%%": intellij.binary_path,
            "%%project_dir%%": intellij_project.project_dir,
            "%%jvm_flags%%": " \\\n    ".join(['"--jvm_flag=-D%s=%s"' % (k, v) for k,v in jvm_props.items()])
        },
        is_executable = True,
    )

    return DefaultInfo(
        files = depset([out]),
        executable = out,
        runfiles = ctx.runfiles(files =
            intellij.binary.files.to_list()
            + intellij.plugins 
            + intellij.files 
            + java_runtime.files.to_list()
        )
    )


_run_intellij = rule(
    implementation = _run_intellij_impl,
    attrs = {
        "indexes": attr.label(allow_single_file = True),
        "config_dir": attr.string(),
        "system_dir": attr.string(),
        "jvm_props": attr.string_dict(),
        "_template": attr.label(
            default = "@rules_intellij//intellij/internal/misc:run_intellij.sh.tp",
            allow_single_file = True,
        ),
    },
    toolchains = [
        "@rules_intellij//intellij:intellij_toolchain_type",
        "@rules_intellij//intellij:intellij_project_toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    executable = True,
)

def run_intellij(**kwargs):
    _run_intellij(
        tags = [ "local" ],
        **kwargs
    )