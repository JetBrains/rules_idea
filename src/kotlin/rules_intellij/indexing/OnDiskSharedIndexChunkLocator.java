// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package rules_intellij.indexing;

import com.intellij.indexing.shared.message.SharedIndexesBundle;
import com.intellij.indexing.shared.metadata.SharedIndexMetadata;
import com.intellij.indexing.shared.platform.api.ChunkDescriptor;
import com.intellij.indexing.shared.platform.api.SharedIndexInfrastructureVersion;
import com.intellij.indexing.shared.platform.impl.ChunkStorageOption;
import com.intellij.indexing.shared.platform.impl.SharedIndexChunkConfiguration;
import com.intellij.indexing.shared.platform.impl.SharedIndexesFusCollector;
import com.intellij.indexing.shared.util.zipFs.UncompressedZipFileSystem;
import com.intellij.indexing.shared.util.zipFs.UncompressedZipFileSystemProvider;
import com.intellij.openapi.application.PathManager;
import com.intellij.openapi.diagnostic.ControlFlowException;
import com.intellij.openapi.diagnostic.Logger;
import com.intellij.openapi.extensions.ExtensionPointName;
import com.intellij.openapi.progress.ProgressIndicator;
import com.intellij.openapi.project.DumbModeTask;
import com.intellij.openapi.project.DumbService;
import com.intellij.openapi.project.Project;
import com.intellij.openapi.startup.StartupActivity;
import com.intellij.openapi.util.io.FileUtil;
import com.intellij.openapi.util.text.StringUtil;
import com.intellij.util.ExceptionUtil;
import com.intellij.util.containers.ContainerUtil;
import com.intellij.util.io.PathKt;
import org.jetbrains.annotations.NotNull;
import org.jetbrains.annotations.Nullable;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Collections;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.stream.Stream;

public class OnDiskSharedIndexChunkLocator implements StartupActivity.RequiredForSmartMode {
  private static final Logger LOG = Logger.getInstance(OnDiskSharedIndexChunkLocator.class);
  private static final String LOCAL_SHARED_INDEX_DIR = "shared-index";
  private static final ExtensionPointName<SharedIndexLocalFinder> LOCAL_FINDER_EP_NAME =
    ExtensionPointName.create("com.intellij.sharedIndexLocalFinderBazel");

  public static final String ROOT_PROP = "on.disk.shared.index.root";

  @Override
  public void runActivity(@NotNull Project project) {
    DumbService.getInstance(project).queueTask(new MyDumbModeTask(project));
  }

  private static void scanAndAttachLocalSharedIndexes(@NotNull Project project,
                                                      @NotNull ProgressIndicator indicator) {
    Path root = getSharedIndexRoot();
    LOG.debug("Scanning " + root + " for manually prepared shared indexes...");

    Set<Path> predefinedPaths = listPredefinedIndexFiles(root);
    Set<Path> customPaths = listCustomIndexFiles(project);

    for (Path ijxPath : ContainerUtil.union(predefinedPaths, customPaths)) {
      ChunkDescriptor chunk = tryLoadCompatibleSharedIndex(ijxPath, SharedIndexInfrastructureVersion.getIdeVersion());
      if (chunk == null) continue;

      try {
        SharedIndexChunkConfiguration.getInstance().downloadChunk(chunk, project, indicator);
      }
      catch (Throwable t) {
        if (t instanceof ControlFlowException) ExceptionUtil.rethrow(t);
        LOG.error("Failed to preload shared index: " + chunk + ". " + t.getMessage(), t);
      }
    }
  }

  @NotNull
  private static Set<Path> listCustomIndexFiles(@NotNull Project project) {
    return LOCAL_FINDER_EP_NAME.extensions().flatMap(finder -> finder.findSharedIndexChunks(project).stream()).collect(Collectors.toSet());
  }

  @NotNull
  private static Set<Path> listPredefinedIndexFiles(@NotNull Path root) {
    if (Files.isRegularFile(root)) {
      return Collections.singleton(root);
    }

    if (Files.isDirectory(root)) {
      try (Stream<Path> pathStream = Files.list(root)) {
        return pathStream
          .filter(f -> f.getFileName().toString().endsWith(".ijx"))
          .collect(Collectors.toSet());
      }
      catch (Exception e) {
        LOG.error("Failed to scan share index file home from " + root + ". " + e.getMessage(), e);
      }
    }

    return Collections.emptySet();
  }

  @NotNull
  private static Path getSharedIndexRoot() {
    String indexRoot = System.getProperty(ROOT_PROP, FileUtil.join(PathManager.getSystemPath(), LOCAL_SHARED_INDEX_DIR));
    return Paths.get(indexRoot);
  }

  private static @Nullable ChunkDescriptor tryLoadCompatibleSharedIndex(@NotNull Path filePath,
                                                                        @NotNull SharedIndexInfrastructureVersion ideVersion) {
    if (!Files.isRegularFile(filePath)) return null;

    LOG.info("Checking local shared index " + filePath);

    @NotNull SharedIndexMetadata version;
    try {
      version = Objects.requireNonNull(getVersion(filePath), "Shared index " + filePath + " contains incompatible metadata");
    }
    catch (Throwable e) {
      LOG.error("Can't fetch shared index version for " + filePath + ". " + e.getMessage(), e);
      return null;
    }

    String fileSize = "(no file size)";
    try {
      fileSize = StringUtil.formatFileSize(Files.size(filePath));
    }
    catch (Exception e) {
      LOG.warn("Can't get size of shared index file " + filePath + ". " + e.getMessage(), e);
    }

    if (!ideVersion.isSuitableMetadata(version)) {
      LOG.warn("Local shared index " + filePath + " is incompatible with current IDE version:\n " +
               "IDE Version: " + ideVersion + "\n" +
               "Index Version: " + version);
      return null;
    }

    LOG.info("Detected local shared index " + filePath + ", " +
             "size " + fileSize + ", " +
             "IDE Version " + ideVersion + ", " +
             "Index Version " + version);

    return new MyChunkDescriptor(filePath, version);
  }

  private static final class MyChunkDescriptor implements ChunkDescriptor {
    private final Path myIndexZip;
    private final @NotNull SharedIndexMetadata myVersion;

    private MyChunkDescriptor(@NotNull Path indexZip, @NotNull SharedIndexMetadata version) {
      myIndexZip = indexZip;
      myVersion = version;
    }

    @Override
    public @NotNull String getChunkUniqueId() {
      return "local-" + myIndexZip.getFileName().toString();
    }

    @NotNull
    @Override
    public String getKind() {
      return myVersion.getIndexKind();
    }

    @Override
    public boolean downloadChunk(@NotNull Path targetFile,
                                 @Nullable Project project,
                                 @NotNull ProgressIndicator indicator) {
      indicator.setText(SharedIndexesBundle.message("configuring.shared.indexes"));
      indicator.setIndeterminate(true);
      LOG.warn("Shared Index " + myIndexZip + " is requested by the IDE");

      try {
        PathKt.copy(myIndexZip, targetFile);
        long size = Files.size(targetFile);

        SharedIndexesFusCollector.INSTANCE.
          reportLocalIndexLoaded(
            project,
            "project", // We don't have kinds for local indexes. Let's consider it is "project"
            getChunkUniqueId(),
            size
          );
        return true;
      }
      catch (Throwable t) {
        if (t instanceof ControlFlowException) ExceptionUtil.rethrow(t);
        LOG.warn("Failed to copy shared index from " + myIndexZip + " to " + targetFile);
        return false;
      }
    }

    @Override
    public String toString() {
      return "Shared Index (" + myVersion + ") from " + myIndexZip;
    }

    @NotNull
    @Override
    public ChunkStorageOption getChunkStorageOption() {
      return ChunkStorageOption.APPEND;
    }
  }

  @Nullable
  private static SharedIndexMetadata getVersion(@NotNull Path indexZip) throws IOException {
    try (UncompressedZipFileSystem fs = UncompressedZipFileSystemProvider.INSTANCE.newFileSystem(indexZip)) {
      return SharedIndexMetadata.readIndexesVersion(fs.getRootDirectory());
    }
  }

  private static class MyDumbModeTask extends DumbModeTask {
    private final @NotNull Project myProject;

    private MyDumbModeTask(@NotNull Project project) {
      super(project);
      myProject = project;
    }

    @Override
    public void performInDumbMode(@NotNull ProgressIndicator indicator) {
      scanAndAttachLocalSharedIndexes(myProject, indicator);
    }

    @Override
    public String toString() {
      return "OnDiskSharedIndexChunkLocator";
    }
  }
}
