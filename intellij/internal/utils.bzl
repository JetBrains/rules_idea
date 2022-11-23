def _add_postf_if_not_empty(data, postf = "/"):
    if not data:
        return ""
    return "%s%s" % (data, postf)


def _label_directory(l):
    return "%s%s" % (
        _add_postf_if_not_empty(l.workspace_root),
        l.package
    )


def _label_directory_with_name(l):
    return "%s%s%s" % (
        _add_postf_if_not_empty(l.workspace_root),
        _add_postf_if_not_empty(l.package),
        l.name
    )


label_utils = struct(
    directory = _label_directory,
    directory_with_name = _label_directory_with_name,
)
