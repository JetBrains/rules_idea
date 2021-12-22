# Copyright 2018 The Bazel Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

"""Definitions for handling Bazel repositories used by the idea rules."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load(
    "@build_flare_rules_idea//idea/internal:idea_autoconfiguration.bzl",
    "idea_autoconfiguration",
)

def _maybe(repo_rule, name, **kwargs):
    """Executes the given repository rule if it hasn't been executed already.

    Args:
      repo_rule: The repository rule to be executed (e.g., `http_archive`.)
      name: The name of the repository to be defined by the rule.
      **kwargs: Additional arguments passed directly to the repository rule.
    """
    if not native.existing_rule(name):
        repo_rule(name = name, **kwargs)

def idea_rules_dependencies():
    """Fetches repositories that are dependencies of `rules_idea`.

    Users should call this macro in their `WORKSPACE` to ensure that all of the
    dependencies of the idea rules are downloaded and that they are isolated
    from changes to those dependencies.
    """
    _maybe(
        http_archive,
        name = "bazel_skylib",
        urls = [
            "https://github.com/bazelbuild/bazel-skylib/releases/download/1.0.3/bazel-skylib-1.0.3.tar.gz",
        ],
        sha256 = "1c531376ac7e5a180e0237938a2536de0c54d93f5c278634818e0efc952dd56c",
    )

    _maybe(
        http_archive,
        name = "com_github_apple_idea_protobuf",
        urls = ["https://github.com/apple/idea-protobuf/archive/1.12.0.zip"],
        sha256 = "a9c1c14d81df690ed4c15bfb3c0aab0cb7a3f198ee95620561b89b1da7b76a9f",
        strip_prefix = "idea-protobuf-1.12.0/",
        type = "zip",
        build_file = "@build_flare_rules_idea//third_party:com_github_apple_idea_protobuf/BUILD.overlay",
    )

    _maybe(
        http_archive,
        name = "com_github_grpc_grpc_idea",
        urls = ["https://github.com/grpc/grpc-idea/archive/0.9.0.zip"],
        sha256 = "b9818134f497df073cb49e0df59bfeea801291230d6fc048fdc6aa76e453a3cb",
        strip_prefix = "grpc-idea-0.9.0/",
        type = "zip",
        build_file = "@build_flare_rules_idea//third_party:com_github_grpc_grpc_idea/BUILD.overlay",
    )

    _maybe(
        http_archive,
        name = "com_github_nlohmann_json",
        urls = [
            "https://github.com/nlohmann/json/releases/download/v3.6.1/include.zip",
        ],
        sha256 = "69cc88207ce91347ea530b227ff0776db82dcb8de6704e1a3d74f4841bc651cf",
        type = "zip",
        build_file = "@build_flare_rules_idea//third_party:com_github_nlohmann_json/BUILD.overlay",
    )

    _maybe(
        http_archive,
        name = "rules_proto",
        # latest as of 2021-11-16
        urls = [
            "https://github.com/bazelbuild/rules_proto/archive/11bf7c25e666dd7ddacbcd4d4c4a9de7a25175f8.zip",
        ],
        sha256 = "810d02d1c016bea9743161f42323e59000c0690e4bf18d94e4f44e361b48645b",
        strip_prefix = "rules_proto-11bf7c25e666dd7ddacbcd4d4c4a9de7a25175f8",
        type = "zip",
    )

    # It relies on `index-import` to import indexes into Bazel's remote
    # cache and allow using a global index internally in workers.
    # Note: this is only loaded if idea.index_while_building_v2 is enabled
    _maybe(
        http_archive,
        name = "build_flare_rules_idea_index_import",
        build_file = "@build_flare_rules_idea//third_party:build_flare_rules_idea_index_import/BUILD.overlay",
        canonical_id = "index-import-5.3.2.6",
        urls = ["https://github.com/MobileNativeFoundation/index-import/releases/download/5.3.2.6/index-import.zip"],
        sha256 = "61a58363f56c5fd84d4ebebe0d9b5dd90c74ae170405a7b9018e8cf698e679de",
    )

    _maybe(
        idea_autoconfiguration,
        name = "build_flare_rules_idea_local_config",
    )
