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
        "indexing-shared-ultimate:intellij.indexing.shared:212.5457.6": 
        "d0dc4254cd961669722febeda81ee6fd480b938efb21a79559b51f8b58500ea6" 
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

def idea_UI_2022_2(
    name = "idea_UI_2022_2", 
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.3345.118":
        "351e41e9ab8604e6a57cc51fb14104593138514ce89dc1b84b109e5beb1f5221"
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2022.2",
        sha256 = "36f4924055cf27cc4d9567d059ade32cf1ae511239b081e6929e62672eff107a",
        kotlin_version = "1.7",
        plugins = plugins,
        **kwargs
    )

def idea_UI_2022_2_1(
    name = "idea_UI_2022_2_1", 
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.3739.24":
        "2e83fab6bd1c290f3ed5623875d47a0c1bdab13a9638aa0bb6d1e0cb02a2225a"
    },
    **kwargs
):
    ideaUI(
        name = name,
        version = "2022.2.1",
        sha256 = "b0bcac5599587450980d2f2c8b8cd49615182fb3a46cba94810953956c49601c",
        kotlin_version = "1.7",
        plugins = plugins,
        **kwargs
    )

def idea_UI_2022_2_2(
    name = "idea_UI_2022_2_2",
    plugins = {
        "indexing-shared-ultimate:intellij.indexing.shared:222.4167.21":
        "6ce957f50f469a26100f2d187f7483b82692afd0f37f20a61db76a8232e94d77"
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
        "indexing-shared-ultimate:intellij.indexing.shared:222.4345.14":
        "9873188a02a0d6cbca59a8777b68a75a6b2308219db05263f34cc5c0ce0a7e35"
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