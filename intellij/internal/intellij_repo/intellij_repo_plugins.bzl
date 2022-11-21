load("@bazel_skylib//lib:paths.bzl", "paths")

_PLUGIN_TPL = """\
java_import(
    name = "{plugin}",
    jars = glob([ "{plugin}/lib/*.jar" ]),
    neverlink = 1,
    visibility = ["//visibility:public"],
)
"""

_ALL_PLUGINS = """\
filegroup(
    name = "runfiles",
    srcs = glob(
        include = ["**"],
        exclude = [
            "**/*.tmLanguage",
            "*.bazel",
        ],
    ),
    visibility = ["//visibility:public"],
)
"""

def download_plugins(rctx):
    """Downloads specified plugins"""
    for plugin, sha256 in rctx.attr.plugins.items():
        split_arr =  plugin.split(":")

        if len(split_arr) != 3:
            fail("Wrong plugin format: %s" % plugin)

        id = split_arr[0]
        plugin_dir = "plugins/%s" % id

        artifact, version = split_arr[1:]
        if rctx.path(plugin_dir).exists:
            rctx.delete(plugin_dir)

        rctx.download(
            url = "{url}/com/jetbrains/plugins/{artifact}/{version}/{artifact}-{version}.zip".format(
                url = rctx.attr.plugins_repo_url,
                artifact = artifact,
                version = version,
            ),
            output = "plugins/plugin.zip",
            sha256 = sha256,
        )
        rctx.execute(
            [ "unzip", "plugin.zip" ],
            working_directory = "plugins",
        )
        rctx.delete("plugins/plugin.zip")


def check_default_plugins(rctx):
    """Checks plugins directory for existence of listed ones, fails otherwise"""
    for plugin in rctx.attr.default_plugins:
        split_arr =  plugin.split(":")

        if len(split_arr) != 2:
            fail("Wrong default plugin format: %s" % plugin)

        id = split_arr[0]
        plugin_dir = "plugins/%s" % id

        if not rctx.path(plugin_dir).exists:
            fail("No such builtin plugin: %s" % id)


def declare_plugins(rctx):
    """Declare targets for each plugin"""
    plugins = [ paths.basename(str(x)) for x in rctx.path("plugins").readdir() ]

    rctx.file(
        "plugins/BUILD.bazel",
        content = "\n".join([
                'load("@rules_java//java:defs.bzl", "java_import")',
                _ALL_PLUGINS,
            ] + [ _PLUGIN_TPL.format(plugin = x) for x in plugins ]
        ),
    )


def intellij_repo_plugins(rctx):
    download_plugins(rctx)
    check_default_plugins(rctx)
    declare_plugins(rctx)
