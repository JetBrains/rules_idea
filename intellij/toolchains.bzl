load("@maven//:compat.bzl", "compat_repositories")
load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")
load("@rules_java//java:defs.bzl", "java_binary", "java_import")

def rules_intellij_deps_toolchains():
    compat_repositories()
    kt_register_toolchains()

def define_intellij():
    java_import(
        name = "libs",
        jars = native.glob([ "lib/*.jar" ]),
    )

    java_import(
        name = "ant_libs",
        jars = native.glob([ "lib/ant/lib/*.jar" ]),
    )

    java_import(
        name = "plugins",
        jars = native.glob([ "plugins/**/*.jar" ]),
    )

    java_binary(
        name = "bin",
        main_class = "com.intellij.idea.Main",
        runtime_deps = [
            ":libs",
            ":ant_libs",
            ":plugins",
        ],
        visibility = ["//visibility:public"],
    )

_INTELLIJ_BUILD_CONTENT = """\
load("@rules_intellij//intellij:toolchains.bzl", "define_intellij")

define_intellij()
"""

def _intellij_impl(rctx):
    rctx.download_and_extract(
        url = "{url}/com/jetbrains/intellij/idea/{type}/{version}/{type}-{version}.zip".format(
            url = rctx.attr.intellij_repo_url,
            type = rctx.attr.type,
            version = rctx.attr.version,
        ),
        sha256 = rctx.attr.sha256,
    )
    for plugin, sha256 in rctx.attr.plugins.items():
        split_arr =  plugin.split(":", 2)
        id = split_arr[0]
        plugin_dir = "plugins/%s" % id

        if len(split_arr) == 3:
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
            rctx.delete( "plugins/plugin.zip")
        elif not rctx.path(plugin_dir).exists:
            fail("No such builtin plugin: %s" % id)

    rctx.file(
        "BUILD.bazel",
        content = _INTELLIJ_BUILD_CONTENT,
    )


intellij = repository_rule(
    implementation = _intellij_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "type": attr.string(mandatory = True),
        "sha256": attr.string(),
        "plugins": attr.string_dict(mandatory = True),
        "intellij_repo_url": attr.string(default = "https://cache-redirector.jetbrains.com/intellij-repository/releases"),
        "plugins_repo_url": attr.string(default = "https://cache-redirector.jetbrains.com/plugins.jetbrains.com/maven"),
    },
    local = True,
)
