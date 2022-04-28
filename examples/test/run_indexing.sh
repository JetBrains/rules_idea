#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"

bazel build //:indexes --output_groups indexed_files