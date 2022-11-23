load("@bazel_skylib//lib:paths.bzl", "paths")

def _plugins_directory_impl(ctx):
    all_out = []
    for archive, name in ctx.attr.plugins.items():
        archive_files = archive[DefaultInfo].files.to_list()
        if len(archive_files) != 1:
            fail("Should be exactly one plugin zip for: %s" % name)

        out = ctx.actions.declare_file("%s/%s" % (ctx.attr.name, name))
        ctx.actions.run(
            mnemonic = "UnzipPlugin",
            executable = ctx.executable._unzipper,
            outputs = [ out ],
            inputs = [ archive_files[0] ],
            arguments = [
                archive_files[0].path,
                paths.dirname(out.path),
            ],
        )
        all_out.append(out)

    return DefaultInfo(
        files = depset(all_out),
        runfiles = ctx.runfiles(files = all_out),
    )

plugins_directory = rule(
    implementation = _plugins_directory_impl,
    attrs = {
        "plugins": attr.label_keyed_string_dict(
            allow_empty = False,
            mandatory = True,
        ),
        "_unzipper": attr.label(
            default = "@rules_intellij//src/main/java/rules_intellij/unzip_plugin",
            executable = True,
            cfg = "exec",
        ),
    }
)