#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

bazel build //foo \
  --aspects @rules_intellij//intellij:indexing.bzl%debug_indexing_aspect \
  --output_groups index_zip