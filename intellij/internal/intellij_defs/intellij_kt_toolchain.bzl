_KT_TOOLCHAIN_TP = """\
load("@{rules_kotlin_repo}//kotlin/internal:opts.bzl", "JavacOptions", "KotlincOptions")
load("@{rules_kotlin_repo}//kotlin/internal:defs.bzl", "KtJsInfo")

def _kt_toolchain_impl(ctx):
    compile_time_providers = [
        JavaInfo(
            output_jar = jar,
            compile_jar = jar,
            neverlink = True,
        )
        for jar in ctx.files.jvm_stdlibs
    ]
    runtime_providers = [
        JavaInfo(
            output_jar = jar,
            compile_jar = jar,
        )
        for jar in ctx.files.jvm_runtime
    ]

    toolchain = dict(
        language_version = {kotlin_version},
        api_version = {kotlin_version},
        debug = [],
        jvm_target = "1.8",
        kotlinbuilder = ctx.attr.kotlinbuilder,
        jdeps_merger = ctx.attr.jdeps_merger,
        kotlin_home = ctx.attr.kotlin_home,
        jvm_stdlibs = java_common.merge(compile_time_providers + runtime_providers),
        js_stdlibs = [],
        execution_requirements = {{
            "supports-workers": "1",
            "supports-multiplex-workers": "0",
        }},
        # experimental_use_abi_jars = False,
        experimental_use_abi_jars = True,
        experimental_strict_kotlin_deps = "off",
        # experimental_strict_kotlin_deps = "warn",
        # experimental_report_unused_deps = "off",
        experimental_report_unused_deps = "warn",
        experimental_reduce_classpath_mode = "NONE",
        # experimental_reduce_classpath_mode = "KOTLINBUILDER_REDUCED",
        javac_options = ctx.attr.javac_options[JavacOptions] if ctx.attr.javac_options else None,
        kotlinc_options = ctx.attr.kotlinc_options[KotlincOptions] if ctx.attr.kotlinc_options else None,
        empty_jar = ctx.file.empty_jar,
        empty_jdeps = ctx.file.empty_jdeps,
        jacocorunner = ctx.attr.jacocorunner,
    )

    return [
        platform_common.ToolchainInfo(**toolchain),
    ]

kt_toolchain = rule(
    attrs = {{
        "kotlin_home": attr.label(
            doc = "the filegroup defining the kotlin home",
            allow_files = True,
            default = "@{kt_compiler_repo}//:home",
        ),
        "kotlinbuilder": attr.label(
            doc = "the kotlin builder executable",
            executable = True,
            allow_files = True,
            cfg = "exec",
            default = "@{rules_kotlin_repo}//src/main/kotlin:build",
        ),
        "jdeps_merger": attr.label(
            doc = "the jdeps merger executable",
            executable = True,
            allow_files = True,
            cfg = "exec",
            default = "@{rules_kotlin_repo}//src/main/kotlin:jdeps_merger",
        ),
        "jvm_runtime": attr.label(
            doc = "The implicit jvm runtime libraries. This is internal.",
            providers = [JavaInfo],
            cfg = "target",
            default = "@{intellij_repo}//lib:no_link_runtime",
        ),
        "jvm_stdlibs": attr.label_list(
            doc = "The jvm stdlibs. This is internal.",
            providers = [JavaInfo],
            cfg = "target",
            default = [
                "@{intellij_repo}//lib:no_link_runtime",
            ],
        ),
        "javac_options": attr.label(
            doc = "Compiler options for javac",
            providers = [JavacOptions],
            default = "@{rules_kotlin_repo}//kotlin/internal:default_javac_options",
        ),
        "empty_jar": attr.label(
            doc = "Empty jar for exporting JavaInfos.",
            allow_single_file = True,
            cfg = "target",
            default = "@{rules_kotlin_repo}//third_party:empty.jar",
        ),
        "kotlinc_options": attr.label(
            doc = "Compiler options for kotlinc",
            providers = [KotlincOptions],
            default = "@{rules_kotlin_repo}//kotlin/internal:default_kotlinc_options",
        ),
        "empty_jdeps": attr.label(
            doc = "Empty jdeps for exporting JavaInfos.",
            allow_single_file = True,
            cfg = "target",
            default = "@{rules_kotlin_repo}//third_party:empty.jdeps",
        ),
        "jacocorunner": attr.label(
            default = "@bazel_tools//tools/jdk:JacocoCoverage",
        ),
    }},
    implementation = _kt_toolchain_impl,
    provides = [platform_common.ToolchainInfo],
)

"""


_KT_TOOLCHAIN_BUILD_TP = """\
load("@rules_java//java:defs.bzl", "java_binary")
load(":kt_toolchain.bzl", "kt_toolchain")

kt_toolchain(
    name = "kt_toolchain",
    visibility = ["//visibility:public"],    
)
"""


def intellij_kt_toolchain(rctx):
    # Original here - https://github.com/bazelbuild/rules_kotlin/blob/v1.7.0-RC-3/kotlin/internal/toolchains.bzl
    """The kotlin toolchain used among with specific intellij"""
    rctx.file(
        "kt_toolchain/kt_toolchain.bzl", 
        _KT_TOOLCHAIN_TP.format(
            intellij_repo = rctx.attr.intellij_repo,
            kotlin_version = rctx.attr.kotlin_version,
            rules_kotlin_repo = rctx.attr.rules_kotlin_repo,
            kt_compiler_repo = rctx.attr.kt_compiler_repo,
        ),
    )
    rctx.file(
        "kt_toolchain/BUILD.bazel", 
        _KT_TOOLCHAIN_BUILD_TP,
    )