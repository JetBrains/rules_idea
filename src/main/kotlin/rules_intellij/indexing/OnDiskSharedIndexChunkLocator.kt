// Copyright 2000-2020 JetBrains s.r.o. Use of this source code is governed by the Apache 2.0 license that can be found in the LICENSE file.
package rules_intellij.indexing

import com.intellij.indexing.shared.message.SharedIndexesBundle
import com.intellij.indexing.shared.metadata.SharedIndexMetadata
import com.intellij.indexing.shared.platform.api.ChunkDescriptor
import com.intellij.indexing.shared.platform.api.SharedIndexInfrastructureVersion
import com.intellij.indexing.shared.platform.impl.ChunkStorageOption
import com.intellij.indexing.shared.platform.impl.SharedIndexChunkConfiguration
import com.intellij.indexing.shared.platform.impl.SharedIndexesFusCollector.reportLocalIndexLoaded
import com.intellij.indexing.shared.util.zipFs.UncompressedZipFileSystemProvider
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.diagnostic.ControlFlowException
import com.intellij.openapi.diagnostic.Logger
import com.intellij.openapi.extensions.ExtensionPointName
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.project.DumbModeTask
import com.intellij.openapi.project.DumbService
import com.intellij.openapi.project.Project
import com.intellij.openapi.startup.StartupActivity.RequiredForSmartMode
import com.intellij.openapi.util.io.FileUtil
import com.intellij.openapi.util.text.StringUtil
import com.intellij.util.ExceptionUtil
import com.intellij.util.containers.ContainerUtil
import com.intellij.util.io.copy
import java.io.IOException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.*
import java.util.stream.Collectors

class OnDiskSharedIndexChunkLocator : RequiredForSmartMode {
    override fun runActivity(project: Project) {
        DumbService.getInstance(project).queueTask(MyDumbModeTask(project))
    }

    private class MyChunkDescriptor(private val myIndexZip: Path, private val myVersion: SharedIndexMetadata) : ChunkDescriptor {
        override val chunkUniqueId: String
            get() = "local-" + myIndexZip.fileName.toString()


        override val kind: String
            get() = myVersion.indexKind

        override fun downloadChunk(targetFile: Path,
                                   project: Project?,
                                   indicator: ProgressIndicator): Boolean {
            indicator.text = SharedIndexesBundle.message("configuring.shared.indexes")
            indicator.isIndeterminate = true
            LOG.warn("Shared Index $myIndexZip is requested by the IDE")
            return try {
                myIndexZip.copy(targetFile)
                val size = Files.size(targetFile)
                // We don't have kinds for local indexes. Let's consider it is "project"
                reportLocalIndexLoaded(project, "project", chunkUniqueId, size)
                true
            } catch (t: Throwable) {
                if (t is ControlFlowException) ExceptionUtil.rethrow(t)
                LOG.warn("Failed to copy shared index from $myIndexZip to $targetFile")
                false
            }
        }

        override fun toString(): String {
            return "Shared Index ($myVersion) from $myIndexZip"
        }

        override val chunkStorageOption: ChunkStorageOption
            get() = if (enumContains<ChunkStorageOption>("APPEND"))
                enumValueOf<ChunkStorageOption>("APPEND")
            else
                enumValueOf<ChunkStorageOption>("APPENDABLE")
    }

    private class MyDumbModeTask(private val project: Project) : DumbModeTask(project) {
        override fun performInDumbMode(indicator: ProgressIndicator) {
            scanAndAttachLocalSharedIndexes(project, indicator)
        }

        override fun toString(): String {
            return "OnDiskSharedIndexChunkLocator"
        }
    }

    companion object {
        private val LOG = Logger.getInstance(OnDiskSharedIndexChunkLocator::class.java)
        private const val LOCAL_SHARED_INDEX_DIR = "shared-index"
        private val LOCAL_FINDER_EP_NAME = ExtensionPointName.create<SharedIndexLocalFinder>("com.intellij.sharedIndexLocalFinderBazel")
        const val ROOT_PROP = "on.disk.shared.index.root"
        private fun scanAndAttachLocalSharedIndexes(project: Project, indicator: ProgressIndicator) {
            val root = getSharedIndexRoot()
            LOG.debug("Scanning $root for manually prepared shared indexes...")
            val predefinedPaths = listPredefinedIndexFiles(root)
            val customPaths = listCustomIndexFiles(project)
            for (ijxPath in ContainerUtil.union(predefinedPaths, customPaths)) {
                val chunk = tryLoadCompatibleSharedIndex(ijxPath, SharedIndexInfrastructureVersion.getIdeVersion())
                        ?: continue
                try {
                    SharedIndexChunkConfiguration.getInstance().downloadChunk(chunk, project, indicator)
                } catch (t: Throwable) {
                    if (t is ControlFlowException) ExceptionUtil.rethrow(t)
                    LOG.error("Failed to preload shared index: " + chunk + ". " + t.message, t)
                }
            }
        }

        private fun listCustomIndexFiles(project: Project): Set<Path> {
            return LOCAL_FINDER_EP_NAME.extensions().flatMap { finder: SharedIndexLocalFinder -> finder.findSharedIndexChunks(project).stream() }.collect(Collectors.toSet())
        }

        private fun listPredefinedIndexFiles(root: Path): Set<Path> {
            if (Files.isRegularFile(root)) {
                return setOf(root)
            }
            if (Files.isDirectory(root)) {
                try {
                    Files.list(root).use { pathStream ->
                        return pathStream
                                .filter { f: Path -> f.fileName.toString().endsWith(".ijx") }
                                .collect(Collectors.toSet())
                    }
                } catch (e: Exception) {
                    LOG.error("Failed to scan share index file home from " + root + ". " + e.message, e)
                }
            }
            return emptySet()
        }

        private fun getSharedIndexRoot(): Path {
            val indexRoot = System.getProperty(ROOT_PROP, FileUtil.join(PathManager.getSystemPath(), LOCAL_SHARED_INDEX_DIR))
            return Paths.get(indexRoot)
        }

        private fun tryLoadCompatibleSharedIndex(filePath: Path,
                                                 ideVersion: SharedIndexInfrastructureVersion): ChunkDescriptor? {
            if (!Files.isRegularFile(filePath)) return null
            LOG.info("Checking local shared index $filePath")
            val version = try {
                getVersion(filePath) ?: throw RuntimeException("Shared index $filePath contains incompatible metadata")
            } catch (e: Throwable) {
                LOG.error("Can't fetch shared index version for " + filePath + ". " + e.message, e)
                return null
            }
            var fileSize = "(no file size)"
            try {
                fileSize = StringUtil.formatFileSize(Files.size(filePath))
            } catch (e: Exception) {
                LOG.warn("Can't get size of shared index file " + filePath + ". " + e.message, e)
            }
            if (!ideVersion.isSuitableMetadata(version)) {
                LOG.warn("""Local shared index $filePath is incompatible with current IDE version:
 IDE Version: $ideVersion
Index Version: $version""")
                return null
            }
            LOG.info("Detected local shared index " + filePath + ", " +
                    "size " + fileSize + ", " +
                    "IDE Version " + ideVersion + ", " +
                    "Index Version " + version)
            return MyChunkDescriptor(filePath, version)
        }

        @Throws(IOException::class)
        private fun getVersion(indexZip: Path): SharedIndexMetadata? {
            UncompressedZipFileSystemProvider.INSTANCE.newFileSystem(indexZip).use {
//                fs -> return SharedIndexMetadata.readIndexesVersion(fs.rootDirectory)
                fs -> return SharedIndexMetadata.readSharedIndexMetadata(fs.rootDirectory)
            }
        }
    }
}