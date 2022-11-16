load("@rules_java//java:defs.bzl", "java_binary")
load("@io_bazel_rules_kotlin//kotlin:jvm.bzl", "kt_jvm_library")
load("@rules_pkg//:pkg.bzl", "pkg_zip")

def _collect_plugin_jars_impl(ctx):
    java_info = ctx.attr.src[JavaInfo]
    all_jars = [ x for x in java_info.transitive_runtime_deps.to_list() + java_info.compile_jars.to_list() ]
    return DefaultInfo(
        files = depset(all_jars),
        runfiles = ctx.runfiles(files = all_jars),
    )


_collect_plugin_jars = rule(
    implementation = _collect_plugin_jars_impl,
    attrs = {
        "src": attr.label(
            mandatory = True,
            providers=[ JavaInfo ],
        ),
    },
)


def wrap_plugin(
    name, 
    ide_repo,
    srcs, 
    deps,
    resources = [],
    ide_plugins = [],
):
    kt_jvm_library(
        name = "%s_lib" % name,
        srcs = srcs,
        deps = deps + [ "@%s//lib" % ide_repo ] + [ "@%s//plugins:%s" % (ide_repo, x) for x in ide_plugins ],
        resources = resources,
        exec_compatible_with = [ "//:constraint_value" ],
        visibility = ["//visibility:public"],
    )
    java_binary(
        name = "%s_bin" % name,
        main_class = "__DUMMY",
        runtime_deps = [ "%s_lib" % name, ],
    )
    pkg_zip(
        name = name,
        srcs = [  "%s_bin_deploy.jar" % name, ],
        package_dir = "%s/lib" % name,
        visibility = ["//visibility:public"],
    )
    _collect_plugin_jars(
        name = "%s_plugin_jars" % name,
        src =  "%s_lib" % name,
    )
    pkg_zip(
        name = "%s_not_single_jar" % name,
        srcs = [  "%s_plugin_jars" % name, ],
        package_dir = "%s/lib" % name,
        visibility = ["//visibility:public"],
    )