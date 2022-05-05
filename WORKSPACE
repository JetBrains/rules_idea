workspace(name = "rules_intellij")

load("@rules_intellij//intellij:repositories.bzl", "rules_intellij_repositories")
rules_intellij_repositories()

load("@rules_intellij//intellij:deps_repositories.bzl", "rules_intellij_deps_repositories")
rules_intellij_deps_repositories()

load("@rules_intellij//intellij:toolchains.bzl", "rules_intellij_deps_toolchains")
rules_intellij_deps_toolchains()

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()

