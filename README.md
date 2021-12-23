[![CI](https://github.com/kigster/rules_idea/actions/workflows/bazel.yml/badge.svg)](https://github.com/kigster/rules_idea/actions/workflows/bazel.yml)

# IntelliJ Idea Rules for [Bazel](https://bazel.build)

This repository contains rules for [Bazel](https://bazel.build) that can be used to build and use IDEA's shared indexes.

If you run into any problems with these rules, please [file an issue!](https://github.com/flarebuild/rules_idea/issues/new)

## Reference Documentation

[Click here](https://github.com/flarebuild/rules_idea/tree/master/doc) for the reference documentation for the rules and other definitions in this repository.

## Compatibility

Please refer to the [release notes](https://github.com/flarebuild/rules_idea/releases) for a given release to see which version of Bazel it is compatible with.

## Quick Setup

### 1. Install idea

Before getting started, make sure that you have a idea toolchain installed.

**Apple users:** Install [Xcode](https://developer.apple.com/xcode/downloads/). If this is your first time installing it, make sure to open it once after installing so that the command line tools are correctly configured.

**Linux users:** Follow the instructions on the [idea download page](https://idea.org/download/) to download and install the appropriate idea toolchain for your platform. Take care to ensure that you have all of idea's dependencies installed (such as ICU, Clang, and so forth), and also ensure that the idea compiler is available on your system path.

### 2. Configure your workspace

Add the following to your `WORKSPACE` file to add the external repositories, replacing the `urls` and `sha256` attributes with the values from the release you wish to depend on:

```python
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_idea",
    sha256 = "4f167e5dbb49b082c5b7f49ee688630d69fb96f15c84c448faa2e97a5780dbbc",
    url = "https://github.com/flarebuild/rules_idea/releases/download/0.1.0/rules_idea.0.1.0.tar.gz",
)

load(
    "@build_bazel_rules_idea//idea:repositories.bzl",
    "idea_rules_dependencies",
)

idea_rules_dependencies()

load(
    "@build_bazel_rules_idea//idea:extras.bzl",
    "idea_rules_extra_dependencies",
)

idea_rules_extra_dependencies()
```

The `idea_rules_dependencies` macro creates a toolchain appropriate for your platform,(either by locating an installation of Xcode on macOS, or looking for `idea` on the system path on Linux).

