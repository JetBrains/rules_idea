load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_file")

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

load("@io_bazel_rules_kotlin//kotlin:repositories.bzl", "kotlin_repositories")


def rules_intellij_deps_repositories():
    bazel_skylib_workspace()

    protobuf_deps()
    
    grpc_java_repositories()

    overrides = {}
    overrides.update(IO_GRPC_GRPC_JAVA_OVERRIDE_TARGETS)
    overrides.update(RULES_INTELLIJ_JAVA_OVERRIDE_TARGETS)

    maven_install(
        name = "rules_intellij_maven",
        artifacts = IO_GRPC_GRPC_JAVA_ARTIFACTS + PROTOBUF_MAVEN_ARTIFACTS + RULES_INTELLIJ_JAVA_ARTIFACTS,
        generate_compat_repositories = True,
        override_targets = overrides,
        repositories = [  "https://repo.maven.apache.org/maven2/", ],
        version_conflict_policy = "pinned",
        # maven_install_json = "@%s//intellij/internal/misc:maven_install.json" % self_repo_name,
    )

    maven_install(
        name = "kotlin_rules_maven",
        fetch_sources = True,
        artifacts = [
            "com.google.code.findbugs:jsr305:3.0.2",
            "junit:junit:4.13-beta-3",
            "com.google.protobuf:protobuf-java:3.6.0",
            "com.google.protobuf:protobuf-java-util:3.6.0",
            "com.google.guava:guava:27.1-jre",
            "com.google.truth:truth:0.45",
            "com.google.auto.service:auto-service:1.0-rc5",
            "com.google.auto.service:auto-service-annotations:1.0-rc5",
            "com.google.auto.value:auto-value:1.6.5",
            "com.google.auto.value:auto-value-annotations:1.6.5",
            "com.google.dagger:dagger:2.43.2",
            "com.google.dagger:dagger-compiler:2.43.2",
            "com.google.dagger:dagger-producers:2.43.2",
            "javax.annotation:javax.annotation-api:1.3.2",
            "javax.inject:javax.inject:1",
            "org.pantsbuild:jarjar:1.7.2",
            "org.jetbrains.kotlinx:atomicfu-js:0.15.2",
            "org.jetbrains.kotlinx:kotlinx-serialization-runtime:1.0-M1-1.4.0-rc",
        ],
        repositories = [
            "https://maven-central.storage.googleapis.com/repos/central/data/",
            "https://maven.google.com",
            "https://repo1.maven.org/maven2",
        ],
    )

    rules_pkg_dependencies()

    kotlin_repositories()
