load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

licenses(["notice"])

bzl_library(
    name = "actions",
    srcs = ["actions.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":features",
        ":toolchain_config",
        "@bazel_skylib//lib:partial",
        "@bazel_skylib//lib:types",
    ],
)

bzl_library(
    name = "attrs",
    srcs = ["attrs.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":providers",
        "@bazel_skylib//lib:dicts",
    ],
)

bzl_library(
    name = "autolinking",
    srcs = ["autolinking.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":actions",
        ":toolchain_config",
    ],
)

bzl_library(
    name = "compiling",
    srcs = ["compiling.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":actions",
        ":autolinking",
        ":debugging",
        ":derived_files",
        ":providers",
        ":toolchain_config",
        ":utils",
        ":vfsoverlay",
        "@bazel_skylib//lib:collections",
        "@bazel_skylib//lib:partial",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:types",
    ],
)

bzl_library(
    name = "debugging",
    srcs = ["debugging.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":actions",
        ":derived_files",
        ":toolchain_config",
    ],
)

bzl_library(
    name = "derived_files",
    srcs = ["derived_files.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":utils",
        "@bazel_skylib//lib:paths",
    ],
)

bzl_library(
    name = "linking",
    srcs = ["linking.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":derived_files",
        "@bazel_skylib//lib:collections",
        "@bazel_skylib//lib:partial",
        "@bazel_tools//tools/build_defs/cc:action_names.bzl",
    ],
)

bzl_library(
    name = "module_maps",
    srcs = ["module_maps.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = ["@bazel_skylib//lib:paths"],
)

bzl_library(
    name = "proto_gen_utils",
    srcs = ["proto_gen_utils.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        ":utils",
        "@bazel_skylib//lib:paths",
    ],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    visibility = ["//swift:__subpackages__"],
    deps = [
        "@bazel_skylib//lib:sets",
        "@bazel_skylib//lib:types",
    ],
)

# Consumed by Bazel integration tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]) + [
        # We should be depending on a filegroup here that represents this file
        # and its dependencies, but it doesn't exist yet.
        "@bazel_tools//tools/cpp:toolchain_utils.bzl",
        "@bazel_tools//tools/build_defs/cc:action_names_test_files",
    ],
)
