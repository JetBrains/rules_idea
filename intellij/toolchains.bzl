load("@rules_intellij_maven//:defs.bzl", "pinned_maven_install")
load("@rules_intellij_maven//:compat.bzl", "compat_repositories")
# load("@io_bazel_rules_kotlin//kotlin:core.bzl", "kt_register_toolchains")

def rules_intellij_deps_toolchains():
    pinned_maven_install()
    compat_repositories()
    # kt_register_toolchains()
