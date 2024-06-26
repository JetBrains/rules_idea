load(":plugins_directory.bzl", "plugins_directory")
load("//intellij/internal:utils.bzl", "label_utils")


Intellij = provider(
    doc = "Information about intellij",
    fields = {
        "id": "Intellij Id",
        "binary": "Intellij binary",
        "binary_path": "Intellij binary path",
        "plugins": "Plugins",
        "home_directory": "Intellij home directory",
        "plugins_directory": "Plugins Directory",
        "files": "Runfiles for intellij",
    }
)


def _intellij_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        intellij = Intellij(
            id = ctx.attr.id,
            binary = ctx.attr.binary,
            binary_path = label_utils.directory_with_name(ctx.attr.binary.label),
            plugins = ctx.files.plugins,
            home_directory = label_utils.directory(ctx.attr.binary.label),
            plugins_directory = label_utils.directory_with_name(ctx.attr.plugins.label),
            files = ctx.files.files,
        ),
    )
    return [toolchain_info]


_intellij_toolchain = rule(
    implementation = _intellij_toolchain_impl,
    attrs = {
        "id": attr.string(
            doc = "Some unique Intellij Id",
            mandatory = True,
        ),
        "binary": attr.label(
            doc = "Intellij binary",
        ),
        "plugins": attr.label(
            doc = "Plugins files",
            allow_files = True,
        ),
        "files": attr.label_list(
            doc = "Runfiles for intellij",
            allow_files = True,
        ),
    },
    provides = [ platform_common.ToolchainInfo ],
)


def intellij_toolchain(name, intellij_repo, plugins = {}):
    reverse_plugins = {}
    for pname, archive in plugins.items():
        reverse_plugins[archive] = pname

    if "indexing" not in plugins:
        reverse_plugins["@%s//indexing" % intellij_repo] = "indexing"

    plugins_directory(
        name = "%s_plugins" % name,
        plugins = reverse_plugins,
    )

    _intellij_toolchain(
        name = name,
        id = intellij_repo,
        binary = "@%s//:binary" % intellij_repo,
        plugins = ":%s_plugins" % name,
        files = [ 
            "@%s//:runfiles" % intellij_repo,
            "@%s//lib:runfiles" % intellij_repo,
            "@%s//plugins:runfiles" % intellij_repo,
        ],
        visibility = ["//visibility:public"],
    )