IntelliJInfo = provider(
    doc = "Information about intellij toolchain", 
    fields = {
        "bin": "intellij binary",
        "dir": "intellij run directory",
    }
)

def _intellij_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        intellij_info = IntelliJInfo(
            bin = ctx.executable.bin,
        ),
    )
    return [toolchain_info]

intellij_toolchain = rule(
    implementation = _intellij_toolchain_impl,
    attrs = {
        "bin": attr.label(
            doc = "path to main intellij platform binary",
            executable = True,
            cfg = "host",
        ),
    },
)

def define_intellij_filegroups(name):
    native.filegroup(
        name = "%s_bin" % name,
        srcs = select({
            "@bazel_tools//src/conditions:darwin": [
                "Contents/MacOS/%s" % name,
            ],
            "@bazel_tools//src/conditions:windows": [

            ],
            "@bazel_tools//src/conditions:linux": [

            ],
            "//conditions:default": [],
        }),
    )

_INTELLIJ_LOCAL_REPO_BUILD_CONTENT = """
load("@rules_intellij//intellij:intellij_toolchain.bzl", "define_intellij_filegroups", "intellij_toolchain")

define_intellij_filegroups("{type}")

intellij_toolchain(
    name = "{name}",
    bin = ":{type}_bin",
)

toolchain(
    name = "{name}_toolchain",
    exec_compatible_with = [],
    target_compatible_with = [],
    toolchain = ":{name}",
    toolchain_type = "@rules_intellij//intellij:intellij_toolchain_type",
    visibility = ["//visibility:public"],
)

"""

def setup_intellij(name, type, path):
    native.new_local_repository(
        name = name,
        path = path,
        build_file_content = _INTELLIJ_LOCAL_REPO_BUILD_CONTENT.strip().format(name = name, type = type),
    )
    native.register_toolchains("@{name}//:{name}_toolchain".format(name = name))