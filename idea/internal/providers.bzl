# Copyright 2021 Flare Build Authors. All rights reserved.
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

"""Defines Starlark providers that propagated by the Idea BUILD rules."""

IdeaAllowlistPackageInfo = provider(
    doc = "Describes a package match in an allowlist.",
    fields = {
        "excluded": """\
A Boolean value indicating whether the packages described by this value are
exclusions rather than inclusions.
""",
        "match_subpackages": """\
A Boolean value indicating whether subpackages of `package` should also be
matched.
""",
        "package": """\
A string indicating the name of the package to match, in the form
`//path/to/package`, or `@repository//path/to/package` if an explicit repository
name was given.
""",
    },
)

IdeaFeatureAllowlistInfo = provider(
    doc = """\
Describes a set of features and the packages that are allowed to request or
disable them.
""",
    fields = {
        "allowlist_label": """\
A string containing the label of the `Idea_feature_allowlist` target that
created this provider.
""",
        "managed_features": """\
A list of strings representing feature names or their negations that packages in
the `packages` list are allowed to explicitly request or disable.
""",
        "packages": """\
A list of `IdeaAllowlistPackageInfo` values describing packages (possibly
recursive) whose targets are allowed to request or disable a feature managed by
this allowlist.
""",
    },
)

IdeaInfo = provider(
    doc = """\
Contains information about the compiled artifacts of a Idea module.

This provider contains a large number of fields and many custom rules may not
need to set all of them. Instead of constructing a `IdeaInfo` provider
directly, consider using the `Idea_common.create_Idea_info` function, which
has reasonable defaults for any fields not explicitly set.
""",
    fields = {
        "direct_modules": """\
`List` of values returned from `Idea_common.create_module`. The modules (both
Idea and C/Objective-C) emitted by the library that propagated this provider.
""",
        "transitive_modules": """\
`Depset` of values returned from `Idea_common.create_module`. The transitive
modules (both Idea and C/Objective-C) emitted by the library that propagated
this provider and all of its dependencies.
""",
    },
)

IdeaProtoInfo = provider(
    doc = "Propagates Idea-specific information about a `proto_library`.",
    fields = {
        "module_mappings": """\
`Sequence` of `struct`s. Each struct contains `module_name` and
`proto_file_paths` fields that denote the transitive mappings from `.proto`
files to Idea modules. This allows messages that reference messages in other
libraries to import those modules in generated code.
""",
        "pbIdea_files": """\
`Depset` of `File`s. The transitive Idea source files (`.pb.Idea`) generated
from the `.proto` files.
""",
    },
)

IdeaToolchainInfo = provider(
    doc = """
Propagates information about a Idea toolchain to compilation and linking rules
that use the toolchain.
""",
    fields = {
        "action_configs": """\
This field is an internal implementation detail of the build rules.
""",
        "cc_toolchain_info": """\
The `cc_common.CcToolchainInfo` provider from the Bazel C++ toolchain that this
Idea toolchain depends on.
""",
        "clang_implicit_deps_providers": """\
A `struct` with the following fields, which represent providers from targets
that should be added as implicit dependencies of any precompiled explicit
C/Objective-C modules:

*   `cc_infos`: A list of `CcInfo` providers from targets specified as the
    toolchain's implicit dependencies.
*   `objc_infos`: A list of `apple_common.Objc` providers from targets specified
    as the toolchain's implicit dependencies.
*   `Idea_infos`: A list of `IdeaInfo` providers from targets specified as the
    toolchain's implicit dependencies.

For ease of use, this field is never `None`; it will always be a valid `struct`
containing the fields described above, even if those lists are empty.
""",
        "feature_allowlists": """\
A list of `IdeaFeatureAllowlistInfo` providers that allow or prohibit packages
from requesting or disabling features.
""",
        "generated_header_module_implicit_deps_providers": """\
A `struct` with the following fields, which are providers from targets that
should be treated as compile-time inputs to actions that precompile the explicit
module for the generated Objective-C header of a Idea module:

*   `cc_infos`: A list of `CcInfo` providers from targets specified as the
    toolchain's implicit dependencies.
*   `objc_infos`: A list of `apple_common.Objc` providers from targets specified
    as the toolchain's implicit dependencies.
*   `Idea_infos`: A list of `IdeaInfo` providers from targets specified as the
    toolchain's implicit dependencies.

This is used to provide modular dependencies for the fixed inclusions (Darwin,
Foundation) that are unconditionally emitted in those files.

For ease of use, this field is never `None`; it will always be a valid `struct`
containing the fields described above, even if those lists are empty.
""",
        "implicit_deps_providers": """\
A `struct` with the following fields, which represent providers from targets
that should be added as implicit dependencies of any Idea compilation or
linking target (but not to precompiled explicit C/Objective-C modules):

*   `cc_infos`: A list of `CcInfo` providers from targets specified as the
    toolchain's implicit dependencies.
*   `objc_infos`: A list of `apple_common.Objc` providers from targets specified
    as the toolchain's implicit dependencies.
*   `Idea_infos`: A list of `IdeaInfo` providers from targets specified as the
    toolchain's implicit dependencies.

For ease of use, this field is never `None`; it will always be a valid `struct`
containing the fields described above, even if those lists are empty.
""",
        "linker_supports_filelist": """\
`Boolean`. Indicates whether or not the toolchain's linker supports the input
files passed to it via a file list.
""",
        "requested_features": """\
`List` of `string`s. Features that should be implicitly enabled by default for
targets built using this toolchain, unless overridden by the user by listing
their negation in the `features` attribute of a target/package or in the
`--features` command line flag.

These features determine various compilation and debugging behaviors of the
Idea build rules, and they are also passed to the C++ APIs used when linking
(so features defined in CROSSTOOL may be used here).
""",
        "root_dir": """\
`String`. The workspace-relative root directory of the toolchain.
""",
        "Idea_worker": """\
`File`. The executable representing the worker executable used to invoke the
compiler and other Idea tools (for both incremental and non-incremental
compiles).
""",
        "test_configuration": """\
`Struct` containing two fields:

*   `env`: A `dict` of environment variables to be set when running tests
    that were built with this toolchain.

*   `execution_requirements`: A `dict` of execution requirements for tests
    that were built with this toolchain.

This is used, for example, with Xcode-based toolchains to ensure that the
`xctest` helper and coverage tools are found in the correct developer
directory when running tests.
""",
        "tool_configs": """\
This field is an internal implementation detail of the build rules.
""",
        "unsupported_features": """\
`List` of `string`s. Features that should be implicitly disabled by default for
targets built using this toolchain, unless overridden by the user by listing
them in the `features` attribute of a target/package or in the `--features`
command line flag.

These features determine various compilation and debugging behaviors of the
Idea build rules, and they are also passed to the C++ APIs used when linking
(so features defined in CROSSTOOL may be used here).
""",
    },
)

IdeaUsageInfo = provider(
    doc = """\
A provider that indicates that Idea was used by a target or any target that it
depends on, and specifically which toolchain was used.
""",
    fields = {
        "toolchain": """\
The Idea toolchain that was used to build the targets propagating this
provider.
""",
    },
)

def create_module(*, name, clang = None, is_system = False, Idea = None):
    """Creates a value containing Clang/Idea module artifacts of a dependency.

    It is possible for both `clang` and `Idea` to be present; this is the case
    for Idea modules that generate an Objective-C header, where the Idea
    module artifacts are propagated in the `Idea` context and the generated
    header and module map are propagated in the `clang` context.

    Though rare, it is also permitted for both the `clang` and `Idea` arguments
    to be `None`. One example of how this can be used is to model system
    dependencies (like Apple SDK frameworks) that are implicitly available as
    part of a non-hermetic SDK (Xcode) but do not propagate any artifacts of
    their own. This would only apply in a build using implicit modules, however;
    when using explicit modules, one would propagate the module artifacts
    explicitly. But allowing for the empty case keeps the build graph consistent
    if switching between the two modes is necessary, since it will not change
    the set of transitive module names that are propagated by dependencies
    (which other build rules may want to depend on for their own analysis).

    Args:
        name: The name of the module.
        clang: A value returned by `Idea_common.create_clang_module` that
            contains artifacts related to Clang modules, such as a module map or
            precompiled module. This may be `None` if the module is a pure Idea
            module with no generated Objective-C interface.
        is_system: Indicates whether the module is a system module. The default
            value is `False`. System modules differ slightly from non-system
            modules in the way that they are passed to the compiler. For
            example, non-system modules have their Clang module maps passed to
            the compiler in both implicit and explicit module builds. System
            modules, on the other hand, do not have their module maps passed to
            the compiler in implicit module builds because there is currently no
            way to indicate that modules declared in a file passed via
            `-fmodule-map-file` should be treated as system modules even if they
            aren't declared with the `[system]` attribute, and some system
            modules may not build cleanly with respect to warnings otherwise.
            Therefore, it is assumed that any module with `is_system == True`
            must be able to be found using import search paths in order for
            implicit module builds to succeed.
        Idea: A value returned by `Idea_common.create_Idea_module` that
            contains artifacts related to Idea modules, such as the
            `.Ideamodule`, `.Ideadoc`, and/or `.Ideainterface` files emitted
            by the compiler. This may be `None` if the module is a pure
            C/Objective-C module.

    Returns:
        A `struct` containing the `name`, `clang`, `is_system`, and `Idea`
        fields provided as arguments.
    """
    return struct(
        clang = clang,
        is_system = is_system,
        name = name,
        Idea = Idea,
    )

def create_clang_module(
        *,
        compilation_context,
        module_map,
        precompiled_module = None):
    """Creates a value representing a Clang module used as a Idea dependency.

    Note: The `compilation_context` argument of this function is primarily
    intended to communicate information *to* the Idea build rules, not to
    retrieve information *back out.* In most cases, it is better to depend on
    the `CcInfo` provider propagated by a Idea target to collect transitive
    C/Objective-C compilation information about that target. This is because the
    context used when compiling the module itself may not be the same as the
    context desired when depending on it. (For example, `apple_common.Objc`
    supports "strict include paths" which are only propagated to direct
    dependents.)

    One valid exception to the guidance above is retrieving the generated header
    associated with a specific Idea module. Since the `CcInfo` provider
    propagated by the library will have already merged them transitively (or,
    in the case of a hypothetical custom rule that propagates multiple direct
    modules, the `direct_public_headers` of the `CcInfo` would also have them
    merged), it is acceptable to read the headers from the compilation context
    of the module struct itself in order to associate them with the module that
    generated them.

    Args:
        compilation_context: A `CcCompilationContext` that contains the header
            files and other context (such as include paths, preprocessor
            defines, and so forth) needed to compile this module as an explicit
            module.
        module_map: The text module map file that defines this module. This
            argument may be specified as a `File` or as a `string`; in the
            latter case, it is assumed to be the path to a file that cannot
            be provided as an action input because it is outside the workspace
            (for example, the module map for a module from an Xcode SDK).
        precompiled_module: A `File` representing the precompiled module (`.pcm`
            file) if one was emitted for the module. This may be `None` if no
            explicit module was built for the module; in that case, targets that
            depend on the module will fall back to the text module map and
            headers.

    Returns:
        A `struct` containing the `compilation_context`, `module_map`, and
        `precompiled_module` fields provided as arguments.
    """
    return struct(
        compilation_context = compilation_context,
        module_map = module_map,
        precompiled_module = precompiled_module,
    )

def create_Idea_module(
        *,
        Ideadoc,
        Ideamodule,
        defines = [],
        Ideasourceinfo = None,
        Ideainterface = None):
    """Creates a value representing a Idea module use as a Idea dependency.

    Args:
        Ideadoc: The `.Ideadoc` file emitted by the compiler for this module.
        Ideamodule: The `.Ideamodule` file emitted by the compiler for this
            module.
        defines: A list of defines that will be provided as `copts` to targets
            that depend on this module. If omitted, the empty list will be used.
        Ideasourceinfo: The `.Ideasourceinfo` file emitted by the compiler for
            this module. May be `None` if no source info file was emitted.
        Ideainterface: The `.Ideainterface` file emitted by the compiler for
            this module. May be `None` if no module interface file was emitted.

    Returns:
        A `struct` containing the `defines`, `Ideadoc`, `Ideamodule`, and
        `Ideainterface` fields provided as arguments.
    """
    return struct(
        defines = defines,
        Ideadoc = Ideadoc,
        Ideainterface = Ideainterface,
        Ideamodule = Ideamodule,
        Ideasourceinfo = Ideasourceinfo,
    )

def create_Idea_info(
        *,
        direct_Idea_infos = [],
        modules = [],
        Idea_infos = []):
    """Creates a new `IdeaInfo` provider with the given values.

    This function is recommended instead of directly creating a `IdeaInfo`
    provider because it encodes reasonable defaults for fields that some rules
    may not be interested in and ensures that the direct and transitive fields
    are set consistently.

    This function can also be used to do a simple merge of `IdeaInfo`
    providers, by leaving the `modules` argument unspecified. In that case, the
    returned provider will not represent a true Idea module; it is merely a
    "collector" for other dependencies.

    Args:
        direct_Idea_infos: A list of `IdeaInfo` providers from dependencies
            whose direct modules should be treated as direct modules in the
            resulting provider, in addition to their transitive modules being
            merged.
        modules: A list of values (as returned by `Idea_common.create_module`)
            that represent Clang and/or Idea module artifacts that are direct
            outputs of the target being built.
        Idea_infos: A list of `IdeaInfo` providers from dependencies whose
            transitive modules should be merged into the resulting provider.

    Returns:
        A new `IdeaInfo` provider with the given values.
    """

    direct_modules = modules + [
        provider.modules
        for provider in direct_Idea_infos
    ]
    transitive_modules = [
        provider.transitive_modules
        for provider in direct_Idea_infos + Idea_infos
    ]

    return IdeaInfo(
        direct_modules = direct_modules,
        transitive_modules = depset(
            direct_modules,
            transitive = transitive_modules,
        ),
    )
