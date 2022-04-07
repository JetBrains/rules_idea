# For running our own unit tests
load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

load(
    "@rules_intellij//intellij:repositories.bzl", 
    "RULES_INTELLIJ_JAVA_ARTIFACTS"
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

def rules_intellij_deps_repositories():
    # For running our own unit tests
    bazel_skylib_workspace()

    protobuf_deps()
    
    grpc_java_repositories()

    maven_install(
        artifacts = IO_GRPC_GRPC_JAVA_ARTIFACTS + PROTOBUF_MAVEN_ARTIFACTS + RULES_INTELLIJ_JAVA_ARTIFACTS,
        generate_compat_repositories = True,
        override_targets = IO_GRPC_GRPC_JAVA_OVERRIDE_TARGETS,
        repositories = [ 
            "https://repo.maven.apache.org/maven2/",
            "https://cache-redirector.jetbrains.com/repo1.maven.org/maven2",
        ],
        version_conflict_policy = "pinned",
    )

    kotlin_repositories()