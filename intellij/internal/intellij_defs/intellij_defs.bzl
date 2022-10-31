load(":intellij_kt_toolchain.bzl", "intellij_kt_toolchain")

_TOOLCHAINS_DEFS = """\
load("@rules_kotlin_for_rules_intellij//kotlin/internal:defs.bzl", _KT_TOOLCHAIN_TYPE = "TOOLCHAIN_TYPE")
# load("@{rules_kotlin_repo}//kotlin:core.bzl", "define_kt_toolchain")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")


# define_kt_toolchain(
#     name = "_kt_toolchain",
#     api_version = "{kotlin_version}",
#     language_version = "{kotlin_version}",
# )

constraint_value(
    name = "constraint_value",
    constraint_setting = "@{rules_intellij_repo}//:intellij_constraint_setting",
    visibility = ["//visibility:public"],
)

toolchain(
    name = "kt_toolchain",
    toolchain_type = _KT_TOOLCHAIN_TYPE,
    toolchain = "//kt_toolchain",
    # toolchain = "//_kt_toolchain_impl",
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
    intellij_kt_toolchain(rctx)
    rctx.file(
        "BUILD.bazel",
        content = _TOOLCHAINS_DEFS.format(
            kotlin_version = rctx.attr.kotlin_version,
            rules_intellij_repo = rctx.attr.rules_intellij_repo,
            rules_kotlin_repo = rctx.attr.rules_kotlin_repo,
        ),
    )


intellij_defs = repository_rule(
    implementation = _intellij_defs_impl,
    attrs = {
        "kotlin_version": attr.string(mandatory = True),
        "intellij_repo": attr.string(mandatory = True),
        "rules_intellij_repo": attr.string(mandatory = True),
        "rules_kotlin_repo": attr.string(mandatory = True),
    },
    local = True,   
)