load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

load(
    "@rules_kotlin_for_rules_intellij//src/main/starlark/core/repositories:configured_rules.bzl", 
    "rules_repository"
)

load(
    "@rules_kotlin_for_rules_intellij//src/main/starlark/core/repositories:versions.bzl", 
    "versions"
)

# For running our own unit tests
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

load(
    "@rules_intellij//intellij:repositories.bzl", 
    "RULES_INTELLIJ_JAVA_ARTIFACTS",
    "RULES_INTELLIJ_JAVA_OVERRIDE_TARGETS",
)

# Protobuf
load(
    "@com_google_protobuf//:protobuf_deps.bzl",
    "PROTOBUF_MAVEN_ARTIFACTS",
    "protobuf_deps"
)

# GRPC
load(
    "@io_grpc_grpc_java//:repositories.bzl",
    "IO_GRPC_GRPC_JAVA_ARTIFACTS",
    "IO_GRPC_GRPC_JAVA_OVERRIDE_TARGETS",
    "grpc_java_repositories",
)

load("@rules_jvm_external//:defs.bzl", "maven_install")

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

def rules_intellij_deps_repositories(
    maven_install_name = "rules_intellij_maven",
    # self_repo_name = "rules_intellij",
):
    bazel_skylib_workspace()

    protobuf_deps()
    
    grpc_java_repositories()

    overrides = {}
    overrides.update(IO_GRPC_GRPC_JAVA_OVERRIDE_TARGETS)
    overrides.update(RULES_INTELLIJ_JAVA_OVERRIDE_TARGETS)

    maven_install(
        name = maven_install_name,
        artifacts = IO_GRPC_GRPC_JAVA_ARTIFACTS + PROTOBUF_MAVEN_ARTIFACTS + RULES_INTELLIJ_JAVA_ARTIFACTS,
        generate_compat_repositories = True,
        override_targets = overrides,
        repositories = [  "https://repo.maven.apache.org/maven2/", ],
        version_conflict_policy = "pinned",
        # maven_install_json = "@%s//intellij/private:maven_install.json" % self_repo_name,
    )

    rules_pkg_dependencies()

    maybe(
        rules_repository,
        name = "io_bazel_rules_kotlin_configured",
        archive = "@rules_kotlin_for_rules_intellij//:rkt_1_7.tgz",
        parent = "@rules_kotlin_for_rules_intellij//:all",
        repo_mapping = {
            "@dev_io_bazel_rules_kotlin": "@rules_kotlin_for_rules_intellij",
        },
    )
    maybe(
        http_file,
        name = "kt_java_stub_template",
        urls = [("https://raw.githubusercontent.com/bazelbuild/bazel/" +
                 versions.BAZEL_JAVA_LAUNCHER_VERSION +
                 "/src/main/java/com/google/devtools/build/lib/bazel/rules/java/" +
                 "java_stub_template.txt")],
        sha256 = "ab1370fd990a8bff61a83c7bd94746a3401a6d5d2299e54b1b6bc02db4f87f68",
    )
