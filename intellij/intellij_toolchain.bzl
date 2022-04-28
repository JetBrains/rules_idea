load("@rules_intellij//intellij:plugins_directory.bzl", "plugins_directory")

Intellij = provider(
    doc = "Information about intellij",
    fields = {
        "binary": "Intellij binary",
        "plugins": "Plugins",
    }
)

def _intellij_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        intellij = Intellij(
            binary = ctx.executable.binary,
            plugins = ctx.files.plugins,
        ),
    )
    return [toolchain_info]

intellij_toolchain = rule(
    implementation = _intellij_toolchain_impl,
    attrs = {
        "binary": attr.label(
            doc = "Intellij binary",
            executable = True,
            cfg = "exec",
        ),
        "plugins": attr.label(
            doc = "Plugins directory",
            allow_files = True,
        ),
    },
)

def setup_intellij_toolchain(name, ide_repo, plugins = {}):
    reverse_plugins = {}
    for pname, archive in plugins.items():
        reverse_plugins[archive] = pname

    if "indexing" not in plugins:
        reverse_plugins["@%s//indexing" % ide_repo] = "indexing"

    plugins_directory(
        name = "%s_plugins" % name,
        plugins = reverse_plugins,
    )

    intellij_toolchain(
        name = "%s_toolchain" % name,
        binary = "@%s//:binary" % ide_repo,
        plugins = ":%s_plugins" % name,
        visibility = ["//visibility:public"],
    )

    native.toolchain(
        name = name,
        exec_compatible_with = [],
        target_compatible_with = [],
        toolchain = ":%s_toolchain" % name,
        toolchain_type = "@rules_intellij//intellij:intellij_toolchain_type",
        visibility = ["//visibility:public"],
    )

