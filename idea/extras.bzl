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

"""Definitions for handling Bazel transitive repositories used by the 
dependencies of the idea rules.
"""
load(
    "@rules_proto//proto:repositories.bzl",
    "rules_proto_dependencies",
    "rules_proto_toolchains",
)

def idea_rules_extra_dependencies():
    """Fetches transitive repositories of the dependencies of `rules_idea`.

    Users should call this macro in their `WORKSPACE` following the use of
    `idea_rules_dependencies` to ensure that all of the dependencies of
    the idea rules are downloaded and that they are isolated from changes
    to those dependencies.
    """

    rules_proto_dependencies()

    rules_proto_toolchains()
