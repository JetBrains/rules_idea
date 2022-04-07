workspace(name = "rules_intellij")

load("@rules_intellij//intellij:repositories.bzl", "rules_intellij_repositories")
rules_intellij_repositories()

load("@rules_intellij//intellij:deps_repositories.bzl", "rules_intellij_deps_repositories")
rules_intellij_deps_repositories()

load("@rules_intellij//intellij:toolchains.bzl", "rules_intellij_deps_toolchains", "intellij")
rules_intellij_deps_toolchains()
intellij(
    name = "idea_ultimate",
    version = "2021.2.3",
    sha256 = "89ad86c940ab1cc7dc13882cd705919830ccfb02814789c0f9389fff26af1ad1",
    type = "ideaIU",
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:212.5457.6": "d0dc4254cd961669722febeda81ee6fd480b938efb21a79559b51f8b58500ea6", 
        "indexing-shared:intellij.indexing.shared.core": "",
    },
)

############################################
# Gazelle, for generating bzl_library targets
load("@io_bazel_rules_go//go:deps.bzl", "go_register_toolchains", "go_rules_dependencies")
load("@bazel_gazelle//:deps.bzl", "gazelle_dependencies")

go_rules_dependencies()

go_register_toolchains(version = "1.17.2")

gazelle_dependencies()

