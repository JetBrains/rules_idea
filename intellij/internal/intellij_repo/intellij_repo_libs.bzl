
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
    ]),
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