IntellijProject = provider(
    doc = "Information about intellij project",
    fields = {
        "project_dir": "intellij run directory",
        "project_files": "intellij project",
    },
)

def _intellij_project_toolchain_impl(ctx):
    toolchain_info = platform_common.ToolchainInfo(
        intellij_project = IntellijProject(
            project_dir = ctx.attr.project_dir,
            project_files = ctx.files.project_files,
        ),
    )
    return [toolchain_info]

intellij_project = rule(
    implementation = _intellij_project_toolchain_impl,
    attrs = {
        "project_dir": attr.string(
            doc = "path to main intellij project",
            default = ".ijwb"
        ),
        "project_files": attr.label_list(
            doc = "intellij project files",
            allow_files = True,
        ),
    },
    provides = [ platform_common.ToolchainInfo ],
)

def setup_intellij_project(name, project_dir = ".ijwb"):
    intellij_project(
        name = "%s_toolchain" % name,
        project_dir = project_dir,
        project_files = native.glob([project_dir + "/**"]),
        visibility = ["//visibility:public"],
    )
    native.toolchain(
        name = name,
        exec_compatible_with = [],
        target_compatible_with = [],
        toolchain = ":%s_toolchain" % name,
        toolchain_type = "@rules_intellij//intellij:intellij_project_toolchain_type",
        visibility = ["//visibility:public"],
    )
