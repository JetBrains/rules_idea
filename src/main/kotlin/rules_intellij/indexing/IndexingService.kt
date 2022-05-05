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
import io.grpc.stub.StreamObserver
import kotlinx.coroutines.*
import java.nio.file.Paths

class IndexingService(
    private val indicator: ProgressIndicator,
    private val args: PersistentProjectArgs
): DaemonGrpc.DaemonImplBase() {
    private val deferredStarts = hashMapOf<Long, Deferred<StartupResponse>>()
    private val projectsByIds = hashMapOf<Long, Project>()
    private val ioScope = CoroutineScope(Dispatchers.IO)

    override fun start(request: StartupRequest, responseObserver: StreamObserver<StartupResponse>) {

        val onError = { e: Throwable ->
            ConsoleLog.info("Indexing Server Startup Exception: $e\n${e.stackTraceToString()}")
            responseObserver.onError(e)
        }

        try {
            ConsoleLog.info("Indexing Server: StartupRequest: $request")
            val projectPathHash = StringHash.calc(request.projectDir)
            val deferredResponse = synchronized(this) {
                deferredStarts.getOrPut(projectPathHash) {
                    ioScope.async { start(request) }
                }
            }
            ioScope.launch {
                try {
                    ConsoleLog.info("Indexing Server: StartupResponse: $request")
                    responseObserver.onNext(deferredResponse.await())
                    responseObserver.onCompleted()
                } catch (e: Throwable) { onError(e) }
            }
        } catch (e: Throwable) { onError(e) }
    }

    fun start(request: StartupRequest): StartupResponse {
        val projectPathHash = StringHash.calc(request.projectDir)

        synchronized(this) {
            if (!projectsByIds.contains(projectPathHash)) {
                return@synchronized
            }

            return StartupResponse.newBuilder()
                .setProjectId(projectPathHash)
                .build()
        }

        indicator.isIndeterminate = false
        val project = importOrOpenProject(request.toOpenProjectArgs(), indicator)

        synchronized(this) {
            projectsByIds.putIfAbsent(projectPathHash, project)
        }

        return StartupResponse.newBuilder()
            .setProjectId(projectPathHash)
            .build()
    }

    override fun index(request: IndexRequest, responseObserver: StreamObserver<IndexResponse>) {
        try {
            ConsoleLog.info("Indexing Server: IndexRequest: $request")
            val response = index(request)
            ConsoleLog.info("Indexing Server: IndexResponse: $request")
            responseObserver.onNext(response)
            responseObserver.onCompleted()
        } catch (e: Throwable) {
            ConsoleLog.info("Indexing Server Index Exception: $e\n${e.stackTraceToString()}")
            responseObserver.onError(e)
        }
    }

    fun index(request: IndexRequest): IndexResponse {
        ConsoleLog.info("Indexing Server: IndexRequest: $request")

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
        indicator.isIndeterminate = false
        val result = IndexesExporter.exportIndexesChunk(
            project = project,
            indicator = indicator,
            request = exportedRequest
        )

        return IndexResponse.newBuilder()
            .setIjxPath(result.files.indexPath.toString())
            .setIjxMetadataPath(result.files.metadataPath.toString())
            .setIjxSha256Path(result.files.sha256Path.toString())
            .build()
    }
}