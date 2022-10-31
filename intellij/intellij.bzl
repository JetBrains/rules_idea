load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("//intellij:repositories.bzl", "RULES_KOTLIN_VERSION", "RULES_KOTLIN_SRC_SHA256")
load("//intellij/internal/intellij_repo:intellij_repo.bzl", "intellij_repo")
load("//intellij/internal/intellij_compiler_link:intellij_compiler_link.bzl", "intellij_compiler_link")
load("//intellij/internal/intellij_defs:intellij_defs.bzl", "intellij_defs")

RULES_INTELLIJ = Label("//:all")

def intellij(name, **kwargs):
    kotlin_version = kwargs.pop("kotlin_version")
    rules_kotlin_repo = "%s_rules_kotlin" % name
    intellij_repo_name = "%s_distr" % name
    intellij_repo(
        name = intellij_repo_name, 
        rules_intellij_repo = RULES_INTELLIJ.workspace_name,
        rules_kotlin_repo = rules_kotlin_repo,
        **kwargs
    )
    intellij_compiler_link(
        name = "%s_compiler_link" % name,
        intellij_repo = intellij_repo_name,
    )
    http_archive(
        name = rules_kotlin_repo,
        sha256 = RULES_KOTLIN_SRC_SHA256,
        urls = [ "https://github.com/bazelbuild/rules_kotlin/archive/refs/tags/v%s.tar.gz" % RULES_KOTLIN_VERSION ],
        strip_prefix = "rules_kotlin-%s" % RULES_KOTLIN_VERSION,
        repo_mapping = { 
            "@dev_io_bazel_rules_kotlin": "@%s" % rules_kotlin_repo,
            "@io_bazel_rules_kotlin": "@%s" % rules_kotlin_repo,
            "@com_github_jetbrains_kotlin": "@%s_compiler_link" % name,
            "@rkt_1_7": "@io_bazel_rules_kotlin_configured",
            # "@kotlin_rules_maven": "@rules_intellij_maven",
        },
    )
    intellij_defs(
        name = name,
        intellij_repo = intellij_repo_name,
        kotlin_version = kotlin_version,
        rules_intellij_repo = RULES_INTELLIJ.workspace_name,
        rules_kotlin_repo = rules_kotlin_repo,
    )

    native.register_toolchains("@%s//:kt_toolchain" % name)
    native.register_execution_platforms("@%s//:platform" % name)
