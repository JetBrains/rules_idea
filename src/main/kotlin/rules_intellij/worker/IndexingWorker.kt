package rules_intellij.worker

import com.google.devtools.build.lib.worker.WorkerProtocol.WorkRequest
import com.google.devtools.build.lib.worker.WorkerProtocol.WorkResponse
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexRequest
import kotlinx.coroutines.*
import java.io.File
import java.io.IOException
import java.nio.file.Paths

object IndexingWorker {

    @JvmStatic
    fun main(args: Array<String>) = runBlocking {
        val logger = WorkerLogger(System.getenv("INTELLIJ_WORKER_DEBUG"))
        onStartup(args, logger)

        val startupArgs = IndexingWorkerArgs()
            .also { it.parseArgs(args) }

        if (!startupArgs.isPersistent) {
            throw UnsupportedOperationException("Only persistent workers supported")
        }

        try {
            val ioScope = CoroutineScope(Dispatchers.IO)
            val client = createIntellijIndexingClient(startupArgs, logger).getOrThrow()
            client.start().getOrThrow()

            while (true) {
                val request = WorkRequest.parseDelimitedFrom(System.`in`)
                    ?: break

                ioScope.launch {
                    logger.log("WorkRequest", request)
                    try {
                        val projectId = client.getProjectId().getOrThrow()
                        processWorkRequest(client, projectId, request)
                            .also { logger.log("WorkResponse", it) }
                            .apply { synchronized(IndexingWorker) {
                                writeDelimitedTo(System.out)
                            } }

                    } catch (e: Exception) {
                        logger.err("UnrecoverableError", e)
                    }
                }
            }
        } catch (e: Exception) {
            logger.err("UnrecoverableError", e)
        }
    }

    private fun onStartup(rawArgs: Array<String>, logger: WorkerLogger) {
        logger.log("ARGS") {
            for (arg in rawArgs) {
                it.println(arg)
            }
        }
        logger.log("ENV") {
            for ((key, value) in System.getenv()) {
                it.println("$key : $value")
            }
        }
    }

    private suspend fun processWorkRequest(
        client: IntellijIndexingClient,
        projectId: Long,
        workRequest: WorkRequest
    ): WorkResponse {
        try {
            val args = IndexingRequestArgs()
                .also { it.parseArgs(workRequest.argumentsList.toTypedArray()) }

            val name = args.name ?: throw IllegalArgumentException("No name")
            val target = args.target ?: throw IllegalArgumentException("No target")
            val outPath = Paths.get(args.outDir ?: throw IllegalArgumentException("No output path"))

            val request = IndexRequest.newBuilder()
                .setProjectId(projectId)
                .setIndexDebugName(target)
                .setIndexId(
                    target
                        .replace("//", "")
                        .replace("/", "_")
                        .replace(":", "_")
                )
                .addAllSources(args.sources)
                .setProjectRoot(System.getProperty("user.dir"))
                .build()

            val response = client.index(request).getOrThrow()

            val moveOrThrow = { input: String, postfix: String ->
                val output = outPath.resolve(name + postfix).toFile()
                if (!File(input).renameTo(output)) {
                    throw IOException("Can't move $input to $output")
                }
            }

            moveOrThrow(response.ijxPath, ".ijx")
            moveOrThrow(response.ijxMetadataPath, ".ijx.metadata.json")
            moveOrThrow(response.ijxSha256Path, ".ijx.sha256")

            return WorkResponse.newBuilder()
                .setRequestId(workRequest.requestId)
                .build()
        } catch (e: Exception) {
            return WorkResponse.newBuilder()
                .setExitCode(1)
                .setOutput(e.toString())
                .setRequestId(workRequest.requestId)
                .build()
        }
    }
}