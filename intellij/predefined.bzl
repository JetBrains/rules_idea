load("@rules_intellij//intellij:intellij.bzl", "intellij")

# Shared Project Indexes versions are from - https://plugins.jetbrains.com/plugin/14437-shared-project-indexes/versions

_default_idea_plugins = [
    "indexing-shared:intellij.indexing.shared.core",
]

def ideaUI(
    default_plugins = _default_idea_plugins, 
    **kwargs
):
    intellij(
        type = "idea",
        subtype = "ideaIU",
        default_plugins = default_plugins,
        **kwargs
    )


def idea_UI_2021_2_4(
    name = "idea_UI_2021_2_4", 
    plugins = { 
        "indexing-shared-ultimate:intellij.indexing.shared:221.6008.13": "",
        "ijwb:com.google.idea.bazel.ijwb:2022.10.18.0.1-api-version-221": "",
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2021.2.4",
        sha256 = "f5e942e090693c139dda22e798823285e22d7b31aaad5d52c23a370a6e91ec7d",
        kotlin_version = "1.5",
        plugins = plugins,
        **kwargs
    )

def idea_UI_2022_2_2(
    name = "idea_UI_2022_2_2",
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.4167.21": "",
        "ijwb:com.google.idea.bazel.ijwb:2022.10.18.0.1-api-version-222": "",
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2022.2.2",
        sha256 = "289fed82133fef1b7f6eadc2988c88f45eb9913d06e59033c6b59b8496c269e2",
        kotlin_version = "1.7",
        plugins = plugins,
        **kwargs
    )

def idea_UI_2022_2_3(
    name = "idea_UI_2022_2_3",
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.4345.14": "",
        "ijwb:com.google.idea.bazel.ijwb:2022.10.18.0.1-api-version-222": "",
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2022.2.3",
        sha256 = "7f1b02c76dd0acccd6bf4f71fe06d75b4e0b286def020962ed85ff5068579bee",
        kotlin_version = "1.7",
        plugins = plugins,
        **kwargs
    )
