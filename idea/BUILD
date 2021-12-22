load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_setting")
load(
    "//idea/internal:build_settings.bzl",
    "per_module_ideacopt_flag",
)

package(default_visibility = ["//visibility:public"])

licenses(["notice"])

bzl_library(
    name = "bazel_tools_bzl",
    srcs = ["@bazel_tools//tools:bzl_srcs"],
)

bzl_library(
    name = "repositories",
    srcs = ["repositories.bzl"],
    deps = [
        ":bazel_tools_bzl",
        "//idea/internal:idea_autoconfiguration",
    ],
)

bzl_library(
    name = "idea",
    srcs = ["idea.bzl"],
    deps = [
        "//idea/internal:providers",
        "//idea/internal:idea_binary_test",
        "//idea/internal:idea_c_module",
        "//idea/internal:idea_common",
        "//idea/internal:idea_feature_allowlist",
        "//idea/internal:idea_grpc_library",
        "//idea/internal:idea_import",
        "//idea/internal:idea_library",
        "//idea/internal:idea_module_alias",
        "//idea/internal:idea_proto_library",
        "//idea/internal:idea_usage_aspect",
    ],
)

# Consumed by Bazel integration tests.
filegroup(
    name = "for_bazel_tests",
    testonly = 1,
    srcs = glob(["**"]) + [
        "//idea/internal:for_bazel_tests",
    ],
    visibility = [
        "//:__pkg__",
    ],
)

# User settable flag that specifies additional idea copts on a per-ideamodule basis.
per_module_ideacopt_flag(
    name = "per_module_ideacopt",
    build_setting_default = "",
    visibility = ["//visibility:public"],
)

# Configuration setting for enabling the generation of ideainterface files.
bool_setting(
    name = "emit_ideainterface",
    build_setting_default = False,
)

# Configuration setting for forcing generation of Apple targets.
# NOTE: this is only intended for use with transitions that want to force
# building of an Apple target when building for Linux.
bool_setting(
    name = "force_apple_target",
    build_setting_default = False,
)

# Allows a user to override the default idea driver during a build, if the
# toolchain is using the default.
label_flag(
    name = "default_idea_executable",
    build_setting_default = ":empty",
)

# Empty filegroup used as the default value for `:default_idea_executable`
# since the `build_setting_default` value is required.
filegroup(
    name = "empty",
    visibility = ["//visibility:private"],
)
