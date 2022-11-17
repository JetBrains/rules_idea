
_LIBS = """\
load("@rules_java//java:defs.bzl", "java_import")

_JARS = glob([
    "tools.jar",
    "jna.jar",
    "jdom.jar",
    "log4j.jar",
    "bootstrap.jar",
    "extensions.jar",
    "trove4j.jar",
    "app.jar",
    "resources.jar",
    "idea.jar",
    "openapi.jar",
    "platform-api.jar",
    "dom-openapi.jar",
    "jsp-base-openapi.jar",
    "rt/xml-apis.jar",
    "platform-impl.jar",
    "3rd-party.jar",
    "stats.jar",
    "util.jar",
    "util_rt.jar",
])

java_import(
    name = "lib",
    jars = _JARS,
    visibility = ["//visibility:public"],
)

java_import(
    name = "no_link_lib",
    jars = _JARS,
    neverlink = 1,
    visibility = ["//visibility:public"],
)

_RUNTIME_JARS = glob([
    "3rd-party-rt.jar",
])

java_import(
    name = "runtime",
    jars = _RUNTIME_JARS,
    visibility = ["//visibility:public"],
)

java_import(
    name = "no_link_runtime",
    jars = _RUNTIME_JARS,
    neverlink = 1,
    visibility = ["//visibility:public"],
)

filegroup(
    name = "runfiles",
    srcs = glob([ "**" ], exclude = [ "src/**" ]),
    visibility = ["//visibility:public"],
)
"""

def intellij_repo_libs(rctx):
    rctx.file(
        "lib/BUILD.bazel",
        content = _LIBS,
    )