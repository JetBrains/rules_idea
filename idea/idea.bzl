# Copyright 2021 Flare.Build Authors. All rights reserved.
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

"""BUILD rules to define idea libraries and executable binaries.

This file is the public interface that users should import to use the idea
rules. Do not import definitions from the `internal` subdirectory directly.

To use the idea build rules in your BUILD files, load them from
`@build_bazel_rules_idea//idea:idea.bzl`.

For example:

```build
load("@build_bazel_rules_idea//idea:idea.bzl", "idea_library")
```
"""

load(
    "@build_bazel_rules_idea//idea/internal:providers.bzl",
    _ideaInfo = "ideaInfo",
    _ideaProtoInfo = "ideaProtoInfo",
    _ideaToolchainInfo = "ideaToolchainInfo",
    _ideaUsageInfo = "ideaUsageInfo",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_binary_test.bzl",
    _idea_binary = "idea_binary",
    _idea_test = "idea_test",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_c_module.bzl",
    _idea_c_module = "idea_c_module",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_clang_module_aspect.bzl",
    _idea_clang_module_aspect = "idea_clang_module_aspect",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_common.bzl",
    _idea_common = "idea_common",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_feature_allowlist.bzl",
    _idea_feature_allowlist = "idea_feature_allowlist",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_grpc_library.bzl",
    _idea_grpc_library = "idea_grpc_library",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_import.bzl",
    _idea_import = "idea_import",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_library.bzl",
    _idea_library = "idea_library",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_module_alias.bzl",
    _idea_module_alias = "idea_module_alias",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_proto_library.bzl",
    _idea_proto_library = "idea_proto_library",
)
load(
    "@build_bazel_rules_idea//idea/internal:idea_usage_aspect.bzl",
    _idea_usage_aspect = "idea_usage_aspect",
)

# Re-export providers.
ideaInfo = _ideaInfo
ideaProtoInfo = _ideaProtoInfo
ideaToolchainInfo = _ideaToolchainInfo
ideaUsageInfo = _ideaUsageInfo

# Re-export public API module.
idea_common = _idea_common

# Re-export rules.
idea_binary = _idea_binary
idea_feature_allowlist = _idea_feature_allowlist
idea_grpc_library = _idea_grpc_library
idea_shared_index = _idea_shared_index
idea_proto_library = _idea_proto_library
idea_test = _idea_test

# Re-export public aspects.
idea_clang_module_aspect = _idea_clang_module_aspect
idea_usage_aspect = _idea_usage_aspect
