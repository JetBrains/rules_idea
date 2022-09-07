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

load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")

load("@rules_pkg//:deps.bzl", "rules_pkg_dependencies")

def rules_intellij_deps_repositories(
    maven_install_name = "rules_intellij_maven",
    self_repo_name = "rules_intellij",
):
    # For running our own unit tests
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
        maven_install_json = "@%s//intellij/private:maven_install.json" % self_repo_name,
    )

    kotlin_repositories()

    rules_pkg_dependencies()