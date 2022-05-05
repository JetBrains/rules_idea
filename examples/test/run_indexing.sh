#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

rm -rf bazel-bin/common bazel-bin/bar bazel-bin/foo bazel-bin/baz
bazel build //:indexes --output_groups indexed_files