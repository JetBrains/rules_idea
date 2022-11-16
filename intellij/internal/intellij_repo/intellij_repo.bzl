load(":intellij_repo_libs.bzl", "intellij_repo_libs")
load(":intellij_repo_plugins.bzl", "intellij_repo_plugins")

_ROOT = """\
load("@rules_java//java:defs.bzl", "java_binary")

filegroup(
    name = "runfiles",
    srcs = glob([
        "bin/**",
        "Resources/**"
    ]),
    visibility = ["//visibility:public"],
)

java_binary(
    name = "binary",
    main_class = "com.intellij.idea.Main",
    runtime_deps = [ 
        "//lib", 
        "//lib:runtime", 
    ],
    visibility = ["//visibility:public"],
)
"""


def _intellij_repo_impl(rctx):
    rctx.download_and_extract(
        url = "{url}/com/jetbrains/intellij/{type}/{stype}/{version}/{stype}-{version}.zip".format(
            url = rctx.attr.intellij_repo_url,
            type = rctx.attr.type,
            stype = rctx.attr.subtype, 
            version = rctx.attr.version,
        ),
        sha256 = rctx.attr.sha256,
    )

    intellij_repo_libs(rctx)
    intellij_repo_plugins(rctx)

    rctx.file(
        "BUILD.bazel",
        content = _ROOT,
    )

_intellij_repo = repository_rule(
    implementation = _intellij_repo_impl,
    attrs = {
        "version": attr.string(mandatory = True),
        "type": attr.string(mandatory = True),
        "subtype": attr.string(mandatory = True),
        "sha256": attr.string(),
        "plugins": attr.string_dict(default = {}),
        "default_plugins": attr.string_list(default = []),
        "intellij_repo_url": attr.string(default = "https://cache-redirector.jetbrains.com/intellij-repository/releases"),
        "plugins_repo_url": attr.string(default = "https://cache-redirector.jetbrains.com/plugins.jetbrains.com/maven"),
        "rules_intellij_repo": attr.string(),
        "rules_kotlin_repo": attr.string(),
        "compiler_repo_template": attr.label(doc = "compiler repository build file template"),
    },
    local = True,
)

def intellij_repo(rules_intellij_repo, rules_kotlin_repo, **kwargs):
    _intellij_repo(
        rules_intellij_repo = rules_intellij_repo,
        rules_kotlin_repo = rules_kotlin_repo,
        compiler_repo_template = "@%s//src/main/starlark/core/repositories:BUILD.com_github_jetbrains_kotlin.bazel" % rules_kotlin_repo,
        **kwargs
    )
