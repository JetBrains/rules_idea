load("@rules_intellij//intellij:plugins_directory.bzl", "plugins_directory")
load("@rules_intellij//intellij/private:utils.bzl", "label_utils")


Intellij = provider(
    doc = "Information about intellij",
    fields = {
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
            binary = ctx.file.binary,
            binary_path = label_utils.directory_with_name(ctx.attr.binary.label),
            plugins = ctx.files.plugins,
            home_directory = label_utils.directory(ctx.attr.binary.label),
            plugins_directory = label_utils.directory_with_name(ctx.attr.plugins.label),
            files = ctx.files.files,
        ),
    )
    return [toolchain_info]


intellij_toolchain = rule(
    implementation = _intellij_toolchain_impl,
    attrs = {
        "binary": attr.label(
            doc = "Intellij binary",
            allow_single_file = True,
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
        binary = "@%s//:binary_deploy.jar" % ide_repo,
        plugins = ":%s_plugins" % name,
        files = [ 
            "@%s//:runfiles" % ide_repo,
            "@%s//lib:runfiles" % ide_repo,
            "@%s//plugins" % ide_repo,
        ],
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

