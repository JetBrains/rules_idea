package rules_intellij.indexing

import com.intellij.indexing.shared.download.SharedIndexCompression
import com.intellij.indexing.shared.generator.ConsoleLog
import com.intellij.indexing.shared.generator.IndexesExporter
import com.intellij.indexing.shared.generator.IndexesExporterRequest
import com.intellij.indexing.shared.generator.importOrOpenProject
import com.intellij.indexing.shared.ultimate.persistent.rpc.*
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.text.StringHash
import com.intellij.util.io.exists
import io.grpc.Status
import io.grpc.StatusException
import java.nio.file.Paths

class IndexingService(
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