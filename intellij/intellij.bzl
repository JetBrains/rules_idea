
load("//intellij/internal/intellij_repo:intellij_repo.bzl", "intellij_repo")
load("//intellij/internal/intellij_defs:intellij_defs.bzl", "intellij_defs")

RULES_INTELLIJ = Label("//:all")
RULES_KOTLIN_REPO = "rules_kotlin_for_rules_intellij"

def intellij(name, **kwargs):
    kotlin_version = kwargs.pop("kotlin_version")
    intellij_repo(
        name = name, 
        rules_intellij_repo = RULES_INTELLIJ.workspace_name,
        rules_kotlin_repo = RULES_KOTLIN_REPO,
        **kwargs
    )
    intellij_defs(
        name = "%s_defs" % name,
        intellij_repo = name,
        kotlin_version = kotlin_version,
        rules_intellij_repo = RULES_INTELLIJ.workspace_name,
        rules_kotlin_repo = RULES_KOTLIN_REPO,
    )
    native.register_toolchains("@%s_defs//:kt_toolchain" % name)
    native.register_execution_platforms("@%s_defs//:platform" % name)
