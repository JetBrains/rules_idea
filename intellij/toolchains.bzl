load("@maven//:compat.bzl", "compat_repositories")
load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")

def rules_intellij_deps_toolchains():
    compat_repositories()
    kt_register_toolchains()
