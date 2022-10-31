_BUILD_TP = """\
load("@bazel_skylib//rules:copy_file.bzl", "copy_file")

package(default_visibility = ["//visibility:public"])

copy_file(
    name = "copy_compiler_jar",
    src = "@{intellij_repo}//plugins/Kotlin/kotlinc:lib/kotlin-compiler.jar",
    out = "lib/kotlin-compiler.jar",
)

copy_file(
    name = "copy_abi_gen_jar",
    src = "@{intellij_repo}//plugins/Kotlin/kotlinc:lib/jvm-abi-gen.jar",
    out = "lib/jvm-abi-gen.jar",
)

alias(
    name = "kotlin-compiler",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-compiler",
)

alias(
    name = "kotlin-preloader",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-preloader",
)

alias(
    name = "kotlin-annotation-processing",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-annotation-processing",
)

alias(
    name = "kotlin-script-runtime",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-script-runtime",
)

alias(
    name = "jvm-abi-gen",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:jvm-abi-gen",
)

alias(
    name = "compiler_jar",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:compiler_jar",
)

alias(
    name = "annotations",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:annotations",
)

alias(
    name = "kotlin-stdlib",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-stdlib",
)

alias(
    name = "kotlin-stdlib-jdk7",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-stdlib-jdk7",
)

alias(
    name = "kotlin-stdlib-jdk8",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:kotlin-stdlib-jdk8",
)


alias(
    name = "home",
    actual = "@{intellij_repo}//plugins/Kotlin/kotlinc:home",
)

"""

def _intellij_compiler_link_impl(rctx):
    rctx.file(
        "BUILD.bazel",
        _BUILD_TP.format(
            intellij_repo = rctx.attr.intellij_repo,
        ),
    )

intellij_compiler_link  = repository_rule(
    implementation = _intellij_compiler_link_impl,
    attrs = {
        "intellij_repo": attr.string(mandatory = True),
    },
)