### How to test:

Run:

    cd examples/test && ./run_indexing.sh

The output should be:

    INFO: Analyzed target //:indexes (0 packages loaded, 0 targets configured).
    INFO: Found 1 target...
    Target //:indexes up-to-date:
    bazel-bin/common/common.ijx
    bazel-bin/common/common.ijx.metadata.json
    bazel-bin/common/common.ijx.sha256
    bazel-bin/foo/foo.ijx
    bazel-bin/foo/foo.ijx.metadata.json
    bazel-bin/foo/foo.ijx.sha256
    bazel-bin/bar/bar.ijx
    bazel-bin/bar/bar.ijx.metadata.json
    bazel-bin/bar/bar.ijx.sha256
    bazel-bin/baz/baz.ijx
    bazel-bin/baz/baz.ijx.metadata.json
    bazel-bin/baz/baz.ijx.sha256
    INFO: Elapsed time: 1.206s, Critical Path: 1.13s
    INFO: 9 processes: 5 internal, 4 worker.
    INFO: Build completed successfully, 9 total actions

To run Idea with generated indexes loaded:

    bazel run :idea_run

You should see in logs:

    .OnDiskSharedIndexChunkLocator - Shared Index /home/gleyba/develop/flarebuild/rules_idea/examples/test/bazel-out/k8-fastbuild/bin/common/common.ijx is requested by the IDE 
    .OnDiskSharedIndexChunkLocator - Shared Index /home/gleyba/develop/flarebuild/rules_idea/examples/test/bazel-out/k8-fastbuild/bin/foo/foo.ijx is requested by the IDE
    .OnDiskSharedIndexChunkLocator - Shared Index /home/gleyba/develop/flarebuild/rules_idea/examples/test/bazel-out/k8-fastbuild/bin/baz/baz.ijx is requested by the IDE
    .OnDiskSharedIndexChunkLocator - Shared Index /home/gleyba/develop/flarebuild/rules_idea/examples/test/bazel-out/k8-fastbuild/bin/bar/bar.ijx is requested by the IDE


### More examples:

- Indexing inside Bazel's codebase itself:
[Bazel](https://github.com/flarebuild/bazel/tree/gleb/indexing_sample)