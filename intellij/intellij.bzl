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
        "util_rt.jar",
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
        "app.jar",
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
        url = "{url}/com/jetbrains/intellij/{type}/{stype}/{version}/{stype}-{version}.zip".format(
            url = rctx.attr.intellij_repo_url,
            type = rctx.attr.type,
            stype = rctx.attr.subtype, 
            version = rctx.attr.version,
        ),
        sha256 = rctx.attr.sha256,
    )

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
        rctx.delete( "plugins/plugin.zip")

    for plugin in rctx.attr.default_plugins:
        split_arr =  plugin.split(":")

        if len(split_arr) != 2:
            fail("Wrong default plugin format: %s" % plugin)

        id = split_arr[0]
        plugin_dir = "plugins/%s" % id

        if not rctx.path(plugin_dir).exists:
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


_intellij = repository_rule(
    implementation = _intellij_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "type": attr.string(mandatory = True),
        "subtype": attr.string(mandatory = True),
        "sha256": attr.string(),
        "plugins": attr.string_dict(default = {}),
        "default_plugins": attr.string_list(default = []),
        "intellij_repo_url": attr.string(default = "https://cache-redirector.jetbrains.com/intellij-repository/releases"),
        "plugins_repo_url": attr.string(default = "https://cache-redirector.jetbrains.com/plugins.jetbrains.com/maven"),
    },
    local = True,
)


_TOOLCHAINS_DEFS = """\
load("@io_bazel_rules_kotlin//kotlin:core.bzl", "define_kt_toolchain")
load("@io_bazel_rules_kotlin//kotlin/internal:defs.bzl", _KT_TOOLCHAIN_TYPE = "TOOLCHAIN_TYPE")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

define_kt_toolchain(
    name = "_kt_toolchain",
    api_version = "{kotlin_version}",
    language_version = "{kotlin_version}",
)

constraint_value(
    name = "constraint_value",
    constraint_setting = "@rules_intellij//:intellij_constraint_setting",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "kt_toolchain",
    toolchain_type = _KT_TOOLCHAIN_TYPE,
    toolchain = "_kt_toolchain_impl",
    exec_compatible_with = [ ":constraint_value" ] + HOST_CONSTRAINTS,
    visibility = ["//visibility:public"],
)

platform(
    name = "platform",
    constraint_values = [ ":constraint_value" ] + HOST_CONSTRAINTS,
    visibility = ["//visibility:public"],
)
"""

def _intellij_defs_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        content = _TOOLCHAINS_DEFS.format(
            kotlin_version = rctx.attr.kotlin_version,
        ),
    )


_intellij_defs = repository_rule(
    implementation = _intellij_defs_impl,
    attrs = {
        "kotlin_version": attr.string(mandatory = True),
    },
    local = True,   
)


def intellij(name, **kwargs):
    _intellij_defs(
        name = "%s_defs" % name,
        kotlin_version = kwargs.pop("kotlin_version"),
    )
    native.register_toolchains("@%s_defs//:kt_toolchain" % name)
    native.register_execution_platforms("@%s_defs//:platform" % name)
    _intellij(name = name, **kwargs)


_default_idea_plugins = [
    "indexing-shared:intellij.indexing.shared.core",
]

def ideaUI(
    default_plugins = _default_idea_plugins, 
    **kwargs
):
    intellij(
        type = "idea",
        subtype = "ideaIU",
        default_plugins = default_plugins,
        **kwargs
    )

def idea_UI_2021_2_4(
    name = "idea_UI_2021_2_4", 
    plugins = { 
        "indexing-shared-ultimate:intellij.indexing.shared:212.5457.6": 
        "d0dc4254cd961669722febeda81ee6fd480b938efb21a79559b51f8b58500ea6" 
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2021.2.4",
        sha256 = "f5e942e090693c139dda22e798823285e22d7b31aaad5d52c23a370a6e91ec7d",
        kotlin_version = "1.5",
        plugins = plugins,
        **kwargs
    )

def idea_UI_2022_2(
    name = "idea_UI_2022_2", 
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.3345.118":
        "351e41e9ab8604e6a57cc51fb14104593138514ce89dc1b84b109e5beb1f5221"
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2022.2",
        sha256 = "36f4924055cf27cc4d9567d059ade32cf1ae511239b081e6929e62672eff107a",
        kotlin_version = "1.7",
        plugins = plugins,
        **kwargs
    )

def idea_UI_2022_2_1(
    name = "idea_UI_2022_2_1", 
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.3739.24":
        "2e83fab6bd1c290f3ed5623875d47a0c1bdab13a9638aa0bb6d1e0cb02a2225a"
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2022.2.1",
        sha256 = "b0bcac5599587450980d2f2c8b8cd49615182fb3a46cba94810953956c49601c",
        kotlin_version = "1.7",
        plugins = plugins,
        **kwargs
    )