package rules_intellij.indexing

import com.intellij.indexing.shared.download.SharedIndexCompression
import com.intellij.indexing.shared.generator.*
import com.intellij.indexing.shared.ultimate.persistent.rpc.*
import com.intellij.indexing.shared.ultimate.project.ProjectSharedIndexes
import com.intellij.indexing.shared.util.ArgsParser
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.project.Project
import com.intellij.openapi.roots.ContentIterator
import com.intellij.openapi.util.text.StringHash
import com.intellij.openapi.vfs.LocalFileSystem
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.openapi.vfs.VirtualFileFilter
import com.intellij.util.SystemProperties
import com.intellij.util.indexing.roots.IndexableFilesIterator
import com.intellij.util.indexing.roots.kind.IndexableSetOrigin
import com.intellij.util.io.exists
import io.grpc.ServerBuilder
import io.grpc.Status
import io.grpc.StatusException
import java.nio.file.Path
import java.nio.file.Paths

internal class PersistentProjectArgs(parser: ArgsParser) {
  val port by parser.arg(
    "port",
    "port to listen on"
  ).int { 9000 }
}

fun StartupRequest.toOpenProjectArgs(): OpenProjectArgs {
  val projectPath = Path.of(getProjectDir())
  return object : OpenProjectArgs {
    override val projectDir: Path
      get() = projectPath
    override val convertProject: Boolean
      get() = false
    override val configureProject: Boolean
      get() = false
    override val disabledConfigurators: Set<String>
      get() = emptySet()
  }
}

class ProjectPartialIndexChunk(private val request: IndexRequest) : IndexChunk {
  override val name = request.indexId
  override val kind = ProjectSharedIndexes.KIND

  class IndexRequestOrigin(val request: IndexRequest): IndexableSetOrigin
  class ByRequestFileIterator(private val request: IndexRequest): IndexableFilesIterator {
    val sources: List<VirtualFile> = request.sourcesList
      .map { Paths.get(request.projectRoot, it).toString() }
      .map { LocalFileSystem.getInstance().findFileByPath(it) }
      .map { it ?: throw StatusException(Status.NOT_FOUND) }

    override fun getDebugName(): String = request.indexDebugName

    override fun getIndexingProgressText() = "Indexing $debugName"

    override fun getRootsScanningProgressText() =  "Scanning $debugName"

    override fun getOrigin(): IndexableSetOrigin =  IndexRequestOrigin(request)

    override fun iterateFiles(project: Project, fileIterator: ContentIterator, fileFilter: VirtualFileFilter): Boolean {
      sources.forEach(fileIterator::processFile)
      return true
    }
  }

  override val rootIterators: List<IndexableFilesIterator> = listOf(ByRequestFileIterator(request))

  override fun toString() = "Project Index Chunk for '$name'"
}

internal class PersistentProjectIndexesGenerator: DumpSharedIndexCommand<PersistentProjectArgs> {
  override val commandName: String
    get() = "persistent-project"
  override val commandDescription: String
    get() = "Runs persistent indexes generator for a project"

  override fun parseArgs(parser: ArgsParser): PersistentProjectArgs = PersistentProjectArgs(parser)

  override fun executeCommand(args: PersistentProjectArgs, indicator: ProgressIndicator) {
    val server = ServerBuilder
      .forPort(args.port)
      .addService(IndexingService(indicator, args))
      .build()

    server.start()
    ConsoleLog.info("Indexing Server started, listening on ${args.port}")
    server.awaitTermination()
    ConsoleLog.info("Indexing Server shutdown")
  }

  private class IndexingService(
    private val indicator: ProgressIndicator,
    private val args: PersistentProjectArgs
  ): DaemonGrpcKt.DaemonCoroutineImplBase() {
    private val projectsByIds = hashMapOf<Long, Project>()

    override suspend fun start(request: StartupRequest): StartupResponse {
      val projectPathHash = StringHash.calc(request.projectDir)

      synchronized(this) {
        if (!projectsByIds.contains(projectPathHash)) {
          return@synchronized
        }
        return StartupResponse.newBuilder()
          .setProjectId(projectPathHash)
          .build()
      }

      val project = importOrOpenProject(request.toOpenProjectArgs(), indicator)

      synchronized(this) {
        projectsByIds.putIfAbsent(projectPathHash, project)
      }
      return StartupResponse.newBuilder()
        .setProjectId(projectPathHash)
        .build()
    }
    override suspend fun index(request: IndexRequest): IndexResponse {
      val project = synchronized(this) {
        projectsByIds[request.projectId]
      } ?: throw StatusException(Status.NOT_FOUND)

      ConsoleLog.info("Collecting files to index...")
      val chunk = ProjectPartialIndexChunk(request)

      val outputDir = Paths.get(PathManager.getTempPath())
        .resolve(java.lang.Long.toHexString(request.projectId))
        .resolve(java.lang.Long.toHexString(StringHash.calc(request.indexId)))

      if (!outputDir.exists() && !outputDir.toFile().mkdirs()) {
        throw StatusException(Status.INTERNAL)
      }

      val exportedRequest = IndexesExporterRequest(
        chunk = chunk,
        //additionalMetadata = SharedIndexMetadataInfo(),
        compression = SharedIndexCompression.PLAIN,
        outputDir = outputDir,
        excludeFilesWithHashCollision = false,
      )

      ConsoleLog.info("Indexing $chunk...")
      IndexesExporter.exportIndexesChunk(
        project = project,
        indicator = indicator,
        request = exportedRequest
      )

      return IndexResponse.newBuilder()
        .setIjxPath(outputDir.resolve("shared-index-project-${request.indexId}-.ijx").toString())
        .setIjxMetadataPath(outputDir.resolve("shared-index-project-${request.indexId}-.metadata.json").toString())
        .setIjxSha256Path(outputDir.resolve("shared-index-project-${request.indexId}-.sha256").toString())
        .build();
    }
  }
}