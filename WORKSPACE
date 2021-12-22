workspace(name = "build_flare_rules_idea")

load(
    "@build_flare_rules_idea//idea:repositories.bzl",
    "idea_rules_dependencies",
)

idea_rules_dependencies()

load(
    "@build_flare_rules_idea//idea:extras.bzl",
    "idea_rules_extra_dependencies",
)

idea_rules_extra_dependencies()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

# For API doc generation
# This is a dev dependency, users should not need to install it
# so we declare it in the WORKSPACE
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "io_bazel_stardoc",
    patches = ["//doc:stardoc.pr103.patch"],
    sha256 = "f89bda7b6b696c777b5cf0ba66c80d5aa97a6701977d43789a9aee319eef71e8",
    strip_prefix = "stardoc-d93ee5347e2d9c225ad315094507e018364d5a67",
    urls = [
        "https://github.com/bazelbuild/stardoc/archive/d93ee5347e2d9c225ad315094507e018364d5a67.tar.gz",
    ],
)

http_archive(
    name = "com_github_nlohmann_json",
    build_file = "//third_party:json.BUILD", # see below
    sha256 = "4cf0df69731494668bdd6460ed8cb269b68de9c19ad8c27abc24cd72605b2d5b",
    strip_prefix = "json-3.9.1",
    urls = ["https://github.com/nlohmann/json/archive/v3.9.1.tar.gz"],
)

