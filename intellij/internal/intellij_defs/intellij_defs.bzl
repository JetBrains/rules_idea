load(":intellij_kt_toolchain.bzl", "intellij_kt_toolchain")
load(":intellij_indexing.bzl", "intellij_indexing")

_DEFS = """\
load("@{rules_intellij_repo}//intellij/internal/intellij_toolchain:intellij_toolchain.bzl", "intellij_toolchain")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

constraint_value(
    name = "constraint_value",
    constraint_setting = "@{rules_intellij_repo}//:intellij_constraint_setting",
    visibility = ["//visibility:public"],
)

platform(
    name = "platform",
    constraint_values = [ ":constraint_value" ] + HOST_CONSTRAINTS,
    visibility = ["//visibility:public"],
)

intellij_toolchain(
    name = "intellij_toolchain",
    intellij_repo = "{intellij_repo}",
    plugins = {{
        "indexing": "//indexing",
    }},
)
"""

_TOOLCHAINS_DEFS = """\
load("@io_bazel_rules_kotlin//kotlin/internal:defs.bzl", _KT_TOOLCHAIN_TYPE = "TOOLCHAIN_TYPE")
load("@local_config_platform//:constraints.bzl", "HOST_CONSTRAINTS")

toolchain(
    name = "kt_toolchain",
    toolchain_type = _KT_TOOLCHAIN_TYPE,
    toolchain = "//kt_toolchain",
    exec_compatible_with = [ "//:constraint_value" ] + HOST_CONSTRAINTS,
    visibility = ["//visibility:public"],
)

toolchain(
    name = "toolchain",
    toolchain_type = "@{rules_intellij_repo}//intellij:intellij_toolchain_type",
    toolchain = "//:intellij_toolchain",
    exec_compatible_with = [ "//:constraint_value" ] + HOST_CONSTRAINTS,
    visibility = ["//visibility:public"],
)
"""



def _intellij_defs_impl(rctx):
    intellij_kt_toolchain(rctx)
    intellij_indexing(rctx)

    subs = {
        "kotlin_version": rctx.attr.kotlin_version,
        "rules_intellij_repo": rctx.attr.rules_intellij_repo,
        "rules_kotlin_repo": rctx.attr.rules_kotlin_repo,
        "intellij_repo": rctx.attr.intellij_repo,
    }

    rctx.file(
        "BUILD.bazel",
        content = _DEFS.format(**subs),
    )
    rctx.file(
        "toolchains/BUILD.bazel",
        content = _TOOLCHAINS_DEFS.format(**subs),
    )


intellij_defs = repository_rule(
    implementation = _intellij_defs_impl,
    attrs = {
        "kotlin_version": attr.string(mandatory = True),
        "intellij_repo": attr.string(mandatory = True),
        "rules_intellij_repo": attr.string(mandatory = True),
        "rules_kotlin_repo": attr.string(mandatory = True),
        "kt_compiler_repo": attr.string(mandatory = True),
    },
    local = True,   
)