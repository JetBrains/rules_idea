load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_WORKER_PROTO_COMMIT = "c17f1b7f9b93bf034046d0973bf2b7e9a64815bf"
_WORKER_PROTO_SHA256 = "9e628d17d5e6ee0f9925576c0346ab1c452f94b6219bee00dbee3ff21d13b341"

_BAZEL_SKYLIB_VERSION = "1.1.1"
_BAZEL_SKYLIB_SHA256 = "c6966ec828da198c5d9adbaa94c05e3a1c7f21bd012a0b29ba8ddbccb2c93b0d"
_BAZEL_SKYLIB_URLS = [ x.format(version = _BAZEL_SKYLIB_VERSION) for x in [
    "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/{version}/bazel-skylib-{version}.tar.gz",
    "https://github.com/bazelbuild/bazel-skylib/releases/download/{version}/bazel-skylib-{version}.tar.gz",
]]

_PROTOBUF_VERSION = "3.19.2"
_PROTOBUF_SHA256 = "9ceef0daf7e8be16cd99ac759271eb08021b53b1c7b6edd399953a76390234cd"

_RULES_JVM_EXTERNAL_VERSION = "4.2"
_RULES_JVM_EXTERNAL_SHA256 = "cd1a77b7b02e8e008439ca76fd34f5b07aecb8c752961f9640dea15e9e5ba1ca"

_GRPC_JAVA_VERSION = "1.45.0"
_GRPC_JAVA_SHA256 = "0a2aebd9b4980c3d555246a27d365349aa9327acf1bc3ed3b545c3cc9594f2e9"

_RULES_KOTLIN_VERSION = "1.5.0"
_RULES_KOTLIN_SHA256 = "12d22a3d9cbcf00f2e2d8f0683ba87d3823cb8c7f6837568dd7e48846e023307"

_GRPC_KOTLIN_VERSION = "1.2.1"
_GRPC_KOTLIN_SHA256 = "9d9b09a7dcc8cee1adf1e5c79a3b68d9a45e8b6f1e5b7f5a31b6410eea7d8ad0"

_RULES_CC_VERSION = "0.0.1"
_RULES_CC_SHA256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241"

_RULES_PKG_VERSION = "0.7.0"
_RULES_PKG_SHA256 = "8a298e832762eda1830597d64fe7db58178aa84cd5926d76d5b744d6558941c2"

RULES_INTELLIJ_JAVA_ARTIFACTS = [
    "io.grpc:grpc-netty-shaded:%s" % _GRPC_JAVA_VERSION,

    "io.netty:netty-transport-native-epoll:4.1.77.Final",
    "io.netty:netty-transport-native-kqueue:4.1.77.Final",

    "com.beust:jcommander:1.82",

    "com.squareup:kotlinpoet:1.5.0",

    "com.google.code.gson:gson:2.8.9",
    "com.google.errorprone:error_prone_annotations:2.9.0",

    "org.jetbrains.kotlinx:kotlinx-coroutines-core:1.5.2",
    "org.jetbrains.kotlinx:kotlinx-coroutines-debug:1.5.2",

    "org.jetbrains.kotlin:kotlin-stdlib-common:1.5.32",

    "com.google.protobuf:protobuf-kotlin:%s" % _PROTOBUF_VERSION,
]

RULES_INTELLIJ_JAVA_OVERRIDE_TARGETS = {
    "org.jetbrains.kotlin:kotlin-stdlib": "@com_github_jetbrains_kotlin//:kotlin-stdlib",
    "org.jetbrains.kotlin:kotlin-stdlib-jdk7": "@com_github_jetbrains_kotlin//:kotlin-stdlib-jdk7",
    "org.jetbrains.kotlin:kotlin-stdlib-jdk8": "@com_github_jetbrains_kotlin//:kotlin-stdlib-jdk8",
    "org.jetbrains.kotlin:kotlin-script-runtime": "@com_github_jetbrains_kotlin//:kotlin-script-runtime",
    "org.jetbrains.kotlin:kotlin-reflect": "@com_github_jetbrains_kotlin//:kotlin-reflect",
}

def rules_intellij_repositories():
    maybe(
        http_archive,
        name = "bazel_skylib",
        sha256 = _BAZEL_SKYLIB_SHA256,
        urls = _BAZEL_SKYLIB_URLS,
    )

    maybe(
        http_archive,
        name = "build_bazel_integration_testing",
        urls = [
            "https://github.com/bazelbuild/bazel-integration-testing/archive/165440b2dbda885f8d1ccb8d0f417e6cf8c54f17.zip",
        ],
        strip_prefix = "bazel-integration-testing-165440b2dbda885f8d1ccb8d0f417e6cf8c54f17",
        sha256 = "2401b1369ef44cc42f91dc94443ef491208dbd06da1e1e10b702d8c189f098e3",
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_go",
        sha256 = "2b1641428dff9018f9e85c0384f03ec6c10660d935b750e3fa1492a281a53b0f",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/rules_go/releases/download/v0.29.0/rules_go-v0.29.0.zip",
            "https://github.com/bazelbuild/rules_go/releases/download/v0.29.0/rules_go-v0.29.0.zip",
        ],
    )

    maybe(
        http_archive,
        name = "bazel_gazelle",
        sha256 = "de69a09dc70417580aabf20a28619bb3ef60d038470c7cf8442fafcf627c21cb",
        urls = [
            "https://mirror.bazel.build/github.com/bazelbuild/bazel-gazelle/releases/download/v0.24.0/bazel-gazelle-v0.24.0.tar.gz",
            "https://github.com/bazelbuild/bazel-gazelle/releases/download/v0.24.0/bazel-gazelle-v0.24.0.tar.gz",
        ],
    )

    maybe(
        http_archive,
        name = "io_bazel_rules_kotlin",
        urls = ["https://github.com/bazelbuild/rules_kotlin/releases/download/v%s/rules_kotlin_release.tgz" % _RULES_KOTLIN_VERSION],
        sha256 = _RULES_KOTLIN_SHA256,
    )
    maybe(
        http_archive,
        name = "com_google_protobuf",
        sha256 = _PROTOBUF_SHA256,
        strip_prefix = "protobuf-%s" % _PROTOBUF_VERSION,
        urls = ["https://github.com/protocolbuffers/protobuf/archive/v%s.zip" % _PROTOBUF_VERSION],
    )
    maybe(
        http_archive,
        name = "rules_jvm_external",
        sha256 = _RULES_JVM_EXTERNAL_SHA256,
        strip_prefix = "rules_jvm_external-%s" % _RULES_JVM_EXTERNAL_VERSION,
        url = "https://github.com/bazelbuild/rules_jvm_external/archive/%s.zip" % _RULES_JVM_EXTERNAL_VERSION,
    )

    maybe(
        http_archive,
        name = "io_grpc_grpc_java",
        sha256 = _GRPC_JAVA_SHA256,
        strip_prefix = "grpc-java-%s" % _GRPC_JAVA_VERSION,
        url = "https://github.com/grpc/grpc-java/archive/refs/tags/v%s.zip" % _GRPC_JAVA_VERSION,
    )

    maybe(
        http_archive,
        name = "com_github_grpc_grpc_kotlin",
        sha256 = _GRPC_KOTLIN_SHA256,
        strip_prefix = "grpc-kotlin-%s" % _GRPC_KOTLIN_VERSION,
        url = "https://github.com/grpc/grpc-kotlin/archive/refs/tags/v%s.zip" % _GRPC_KOTLIN_VERSION,
    )

    maybe(
        http_archive,
        name = "rules_cc",
        url = "https://github.com/bazelbuild/rules_cc/releases/download/{v}/rules_cc-{v}.tar.gz".format(v = _RULES_CC_VERSION),
        sha256 = _RULES_CC_SHA256,
    )

    maybe(
        http_archive,
        name = "rules_pkg",
        url = "https://github.com/bazelbuild/rules_pkg/releases/download/{version}/rules_pkg-{version}.tar.gz".format(version = _RULES_PKG_VERSION),
        sha256 = _RULES_PKG_SHA256,
    )

    http_file(
        name = "workers_proto",
        urls = ["https://raw.githubusercontent.com/bazelbuild/bazel/%s/src/main/protobuf/worker_protocol.proto" % _WORKER_PROTO_COMMIT ],
        sha256 = _WORKER_PROTO_SHA256,
    )
