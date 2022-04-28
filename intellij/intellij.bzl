load("@bazel_skylib//lib:paths.bzl", "paths")

_JAVA_LIBS = """
java_import(
    name = "libs",
    jars = glob([
        "lib/*.jar",
    ], exclude = [
        "lib/kotlin-*",
    ]),
    visibility = ["//visibility:public"],
)
"""

_KOTLIN_LIBS = """
java_import(
    name = "kotlin_libs",
    jars = glob([ "lib/kotlin-*.jar", ]),
    visibility = ["//visibility:public"],
)
"""

_ANT_LIBS = """
java_import(
    name = "ant_libs",
    jars = glob([ "lib/ant/lib/*.jar" ]),
    visibility = ["//visibility:public"],
)
"""

_PLUGIN_TPL = """
java_import(
    name = "{plugin}",
    jars = glob([ "{plugin}/lib/*.jar" ]),
    visibility = ["//visibility:public"],
)
"""

_ALL_PLUGINS_TPL = """
java_library(
    name = "plugins",
    runtime_deps = %s,
    visibility = ["//visibility:public"],
)
"""

_BIN = """
java_binary(
    name = "binary",
    main_class = "com.intellij.idea.Main",
    runtime_deps = [
        ":libs",
        ":kotlin_libs",
        ":ant_libs",
        ":plugins",
    ],
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
        content = "\n".join([ _PLUGIN_TPL.format(plugin = x) for x in plugins ]),
    )

    build_content = [
        'load("@rules_java//java:defs.bzl", "java_binary", "java_import")',
        _JAVA_LIBS,
        _KOTLIN_LIBS,
        _ANT_LIBS,
        _ALL_PLUGINS_TPL % str([ "//plugins:%s" % x for x in plugins]),
        _BIN,
    ]

    rctx.file(
        "BUILD.bazel",
        content = "\n".join(build_content),
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
