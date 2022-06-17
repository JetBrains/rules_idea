package rules_intellij.indexing

import com.intellij.indexing.shared.download.SharedIndexCompression
import com.intellij.indexing.shared.generator.*
import com.intellij.indexing.shared.ultimate.persistent.rpc.*
import com.intellij.openapi.application.PathManager
import com.intellij.openapi.project.Project
import com.intellij.openapi.util.text.StringHash
import com.intellij.util.io.exists
import io.grpc.Status
import io.grpc.StatusException
import io.grpc.stub.StreamObserver
import kotlinx.coroutines.*
import java.nio.file.Path
import kotlin.io.path.createTempFile
import java.nio.file.Paths

fun statusFromThrowable(e: Throwable): StatusException {
    var sts = Status.fromThrowable(e)
    if (sts.description?.isEmpty() != false) {
        sts = Status.UNKNOWN.withDescription(e.message)
    }
    return StatusException(sts)
}

fun StartupRequest.toOpenProjectArgs(): OpenProjectArgs {
    val projectPath = Path.of(projectDir)
    if (!projectPath.toFile().exists()) {
        throw StatusException(Status.NOT_FOUND.withDescription("project path $projectDir does not exist"))
    }

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

class IndexingService: DaemonGrpc.DaemonImplBase() {
    private val deferredStarts = hashMapOf<Long, Deferred<StartupResponse>>()
    private val projectsByIds = hashMapOf<Long, Project>()
    private val ioScope = CoroutineScope(Dispatchers.IO)

    override fun start(request: StartupRequest, responseObserver: StreamObserver<StartupResponse>) {

        val onError = { e: Throwable ->
            ConsoleLog.info("Indexing Server Startup Exception: $e\n${e.stackTraceToString()}")
            responseObserver.onError(statusFromThrowable(e))
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



        val indicator = DummyIndicator()
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
            responseObserver.onError(statusFromThrowable(e))
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
        val indicator = DummyIndicator()

        try {
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
        } catch (e: Exception) {
            if (e.message?.contains("shared index is empty") == true) {
                return IndexResponse.newBuilder()
                    .setIjxPath(createTempFile().toString())
                    .setIjxMetadataPath(createTempFile().toString())
                    .setIjxSha256Path(createTempFile().toString())
                    .build()
            }
            throw e
        }
    }
}