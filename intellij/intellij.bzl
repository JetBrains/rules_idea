load("@bazel_skylib//lib:paths.bzl", "paths")

_PLUGIN_TPL = """\
java_import(
    name = "{plugin}",
    jars = glob([ "{plugin}/lib/*.jar" ]),
    visibility = ["//visibility:public"],
)
"""

_ALL_PLUGINS = """\
filegroup(
    name = "plugins",
    srcs = glob([
        "**/*.jar",
    ]),
    visibility = ["//visibility:public"],
)
"""

_LIBS = """\
load("@rules_java//java:defs.bzl", "java_import")

java_import(
    name = "binary_libs",
    jars = glob([
        "tools.jar",
        "3rd-party-rt.jar",
        "util.jar",
        "jna.jar",
        "jdom.jar",
        "log4j.jar",
        "bootstrap.jar",
        "extensions.jar",
        "trove4j.jar",
    ]),
    visibility = ["//visibility:public"],
)

java_import(
    name = "api",
    jars = glob([
        "openapi.jar",
        "platform-api.jar",
        "dom-openapi.jar",
        "jsp-base-openapi.jar",
        "rt/xml-apis.jar",
        "platform-impl.jar",
        "3rd-party.jar",
        "stats.jar",
    ]),
    visibility = ["//visibility:public"],
)

filegroup(
    name = "runfiles",
    srcs = glob([ "**" ], exclude = [ "src/**" ]),
    visibility = ["//visibility:public"],
)
"""

_ROOT = """\
load("@rules_java//java:defs.bzl", "java_binary")
load("@io_bazel_rules_kotlin//kotlin:core.bzl", "define_kt_toolchain")

filegroup(
    name = "runfiles",
    srcs = glob([
        "bin/**",
        "Resources/**"
    ]),
    visibility = ["//visibility:public"],
)

java_binary(
    name = "binary",
    main_class = "com.intellij.idea.Main",
    runtime_deps = [ "//lib:binary_libs" ],
    visibility = ["//visibility:public"],
)
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

    plugins = [ paths.basename(str(x)) for x in rctx.path("plugins").readdir() ]

    rctx.file(
        "plugins/BUILD.bazel",
        content = "\n".join([
                'load("@rules_java//java:defs.bzl", "java_import")',
                _ALL_PLUGINS,
            ] + [ _PLUGIN_TPL.format(plugin = x) for x in plugins ]
        ),
    )

    rctx.file(
        "lib/BUILD.bazel",
        content = _LIBS,
    )

    rctx.file(
        "BUILD.bazel",
        content = _ROOT,
    )

    rctx.file(
        "indexing/BUILD.bazel",
        "\n".join([
            'load("@rules_intellij//src/main/kotlin/rules_intellij/indexing:indexing_plugin.bzl", "inject_indexing")',
            'inject_indexing(name = "indexing", ide_repo = "%s")' % rctx.attr.name,
        ])
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
