_INTELLIJ_RUN_TP = """\
load("@{rules_intellij_repo}//intellij/internal/intellij_toolchain:run_intellij.bzl", "run_intellij")

def run(**kwargs):
    run_intellij(
        exec_compatible_with = [ "//:constraint_value" ],
        **kwargs
    )

"""

def intellij_run(rctx):
    rctx.file(
        "run.bzl",
        _INTELLIJ_RUN_TP.format(
            rules_intellij_repo = rctx.attr.rules_intellij_repo,
        ),
    )