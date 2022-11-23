load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive", "http_file", "http_jar")
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

_GRPC_JAVA_VERSION = "1.45.1"
_GRPC_JAVA_SHA256 = "ede3d9dcd2438f7e82b2e7f6a436a78bc7f0ebeb982415caec47de8f1bebf303"

_RULES_KOTLIN_VERSION = "1.7.0-RC-3"
_RULES_KOTLIN_SHA256 = "f033fa36f51073eae224f18428d9493966e67c27387728b6be2ebbdae43f140e"

_GRPC_KOTLIN_VERSION = "1.3.0"
_GRPC_KOTLIN_SHA256 = "7d06ab8a87d4d6683ce2dea7770f1c816731eb2a172a7cbb92d113ea9f08e5a7"

_RULES_CC_VERSION = "0.0.1"
_RULES_CC_SHA256 = "4dccbfd22c0def164c8f47458bd50e0c7148f3d92002cdb459c2a96a68498241"

_RULES_PKG_VERSION = "0.7.0"
_RULES_PKG_SHA256 = "8a298e832762eda1830597d64fe7db58178aa84cd5926d76d5b744d6558941c2"

_NETTY_VERSION = "4.1.79.Final"

_KOTLIN_COROUTINES_VERSION = "1.6.4"

RULES_INTELLIJ_JAVA_ARTIFACTS = [
    "io.grpc:grpc-netty-shaded:%s" % _GRPC_JAVA_VERSION,

    "io.netty:netty-transport-native-unix-common:%s" % _NETTY_VERSION,
    "io.netty:netty-transport-native-epoll:%s" % _NETTY_VERSION,
    "io.netty:netty-transport-native-kqueue:%s" % _NETTY_VERSION,

    "com.beust:jcommander:1.82",

    "com.squareup:kotlinpoet:1.5.0",

    "com.google.code.gson:gson:2.8.9",
    "com.google.errorprone:error_prone_annotations:2.9.0",

    "org.jetbrains.kotlinx:kotlinx-coroutines-core:%s" % _KOTLIN_COROUTINES_VERSION,
    "org.jetbrains.kotlinx:kotlinx-coroutines-debug:%s" % _KOTLIN_COROUTINES_VERSION,

    "com.google.protobuf:protobuf-kotlin:%s" % _PROTOBUF_VERSION,
]

_EMPTY_JAR = "@rules_intellij//intellij/internal/misc:empty_jar"

RULES_INTELLIJ_JAVA_OVERRIDE_TARGETS = {
    "org.jetbrains.kotlin:kotlin-stdlib": _EMPTY_JAR,
    "org.jetbrains.kotlin:kotlin-stdlib-jdk7": _EMPTY_JAR,
    "org.jetbrains.kotlin:kotlin-stdlib-jdk8": _EMPTY_JAR,
    "org.jetbrains.kotlin:kotlin-script-runtime": _EMPTY_JAR,
    "org.jetbrains.kotlin:kotlin-reflect": _EMPTY_JAR,
    "org.jetbrains.kotlin:kotlin-stdlib-common": _EMPTY_JAR,
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
        name = "io_bazel_rules_kotlin",
        urls = ["https://github.com/bazelbuild/rules_kotlin/releases/download/v%s/rules_kotlin_release.tgz" % _RULES_KOTLIN_VERSION],
        sha256 = _RULES_KOTLIN_SHA256,
    )
    maybe(
        http_archive,
        name = "com_google_protobuf",
        sha256 = _PROTOBUF_SHA256,
        strip_prefix = "protobuf-%s" % _PROTOBUF_VERSION,
        repo_mapping = { "@maven": "@rules_intellij_maven" },
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
        repo_mapping = { 
            "@maven": "@rules_intellij_maven",
        },
        patches = [ "@rules_intellij//intellij/internal/misc:grpc_kotlin.patch" ],
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
    maybe(
        http_jar,
        name = "io_netty_netty_transport_native_epoll_linux_x86_64",
        url = "https://repo1.maven.org/maven2/io/netty/netty-transport-native-epoll/{v}/netty-transport-native-epoll-{v}-linux-x86_64.jar".format(
            v = _NETTY_VERSION
        ),
        sha256 = "82efdc8c9b0ce6a37e9b43622ce1e3187287dbbe1bd987cbccee964be3fc0706",
    )

    maybe(
        http_jar,
        name = "io_netty_netty_transport_native_epoll_linux_aarch_64",
        url = "https://repo1.maven.org/maven2/io/netty/netty-transport-native-epoll/{v}/netty-transport-native-epoll-{v}-linux-aarch_64.jar".format(
            v = _NETTY_VERSION
        ),
        sha256 = "aec8ba72a9fee5c236058a3fb0b9bd400118ea3fa28152d3c1888392096532f3",
    )

    maybe(
        http_jar,
        name = "io_netty_netty_transport_native_kqueue_osx_x86_64",
        url = "https://repo1.maven.org/maven2/io/netty/netty-transport-native-kqueue/{v}/netty-transport-native-kqueue-{v}-osx-x86_64.jar".format(
            v = _NETTY_VERSION
        ),
        sha256 = "bc28604c466eea6e86f051f85c5ce57a15372667d96cc39242feaa9e0fe52337",
    )

    maybe(
        http_jar,
        name = "io_netty_netty_transport_native_kqueue_osx_aarch_64",
        url = "https://repo1.maven.org/maven2/io/netty/netty-transport-native-kqueue/{v}/netty-transport-native-kqueue-{v}-osx-aarch_64.jar".format(
            v = _NETTY_VERSION
        ),
        sha256 = "993270798773cf51454710c55fe5efa35108260af3394b6285933d9a6af033dd",
    )