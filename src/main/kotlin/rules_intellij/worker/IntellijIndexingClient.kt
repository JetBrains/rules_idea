package rules_intellij.worker

import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpcKt.DaemonCoroutineStub
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexRequest
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexResponse
import com.intellij.indexing.shared.ultimate.persistent.rpc.StartupRequest

import java.util.*
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import io.grpc.Deadline
import io.grpc.ManagedChannelBuilder
import java.io.IOException
import java.io.InputStream
import java.io.BufferedReader
import java.util.concurrent.TimeUnit
import kotlin.collections.List

interface IntellijIndexingClientArgs {
    val logger: WorkerLogger
    val endpoint: String
    val projectDir: String
}

abstract class IntellijIndexingClient(args: IntellijIndexingClientArgs) {
    val logger = args.logger.apply {
        log("IntellijIndexingClient", args.endpoint)
    }
    private val projectDir = args.projectDir
    private val channel = ManagedChannelBuilder.forTarget(args.endpoint)
        .usePlaintext()
        .build()
    private val stub = DaemonCoroutineStub(channel)

    internal suspend fun startInternal(): Result<Long> = runCatching {
        val request = StartupRequest.newBuilder()
            .setProjectDir(System.getProperty("user.dir") + "/" + projectDir)
            .build()

        logger.log("StartupRequest", request)

        val response = stub.start(request)

        logger.log("StartupResponse", response)

        response.projectId
    }

    suspend fun index(request: IndexRequest): Result<IndexResponse> = runCatching {
        logger.log("IndexRequest", request)

        val response = stub.index(request)

        logger.log("IndexResponse", request)

        response
    }

    abstract suspend fun start(): Result<Long>
}

class IntellijIndexingClientDebugArgs(
    override val logger: WorkerLogger,
    override val endpoint: String,
    override val projectDir: String
): IntellijIndexingClientArgs

class IntellijIndexingClientDebug(args: IntellijIndexingClientDebugArgs): IntellijIndexingClient(args) {

    override suspend fun start(): Result<Long> = startInternal()
}

class IntellijIndexingClientStarterArgs(
    override val logger: WorkerLogger,
    override val endpoint: String,
    override val projectDir: String,
    val ideRunner: String,
    val pluginsDir: String,
): IntellijIndexingClientArgs

class IntellijIndexingClientStarter(args: IntellijIndexingClientStarterArgs): IntellijIndexingClient(args) {
    private val ideRunner = args.ideRunner
    private val pluginsDir = args.pluginsDir
    private val scope = CoroutineScope(Dispatchers.IO)

    @ExperimentalCoroutinesApi
    fun <T> Flow<T>.throttleCombine(periodMillis: Long): Flow<List<T>> {
        require(periodMillis > 0) { "period should be positive" }

        return channelFlow {
            var values = mutableListOf<T>()
            var timer: Timer? = null

            val sendValues = fun(){
                if (values.isEmpty()) {
                    return
                }
                val curValues = values
                values = mutableListOf<T>()
                scope.launch {
                    send(curValues)
                }
            }

            onCompletion { 
                timer?.cancel()
                sendValues()
            }
            collect { value ->
                values.add(value)

                if (timer == null) {
                    timer = Timer()
                    timer?.scheduleAtFixedRate(
                        object : TimerTask() {
                            override fun run() {
                                sendValues()
                            }
                        },
                        0,
                        periodMillis
                    )
                }
            }
        }
    }

    private fun logStream(tag: String, stream: InputStream) {
        scope.launch {
            stream
                .bufferedReader()
                .lineSequence()
                .asFlow()
                .throttleCombine(1000)
                .flowOn(Dispatchers.IO)
                .collect { values ->
                    logger.log(tag) { out ->
                        for (v in values) {
                            out.println(v)
                        }
                    }
                }
        }
    }

    private suspend fun startIntellij(): Unit = withContext(Dispatchers.IO) {
        val cmdLine = listOf(
            listOf(ideRunner),
            listOf(
                "-Didea.config.path=__config",
                "-Didea.system.path=__system",
                "-Didea.plugins.path=$pluginsDir",
                "-Didea.platform.prefix=Idea",
                "-Didea.initially.ask.config=false",
                "-Didea.skip.indices.initialization=true",
                "-Didea.force.dumb.queue.tasks=true",
                "-Didea.suspend.indexes.initialization=true",
                "-Dintellij.disable.shared.indexes=true",
                "-Dshared.indexes.download=false",
                "-Dintellij.hash.as.local.file.timestamp=true",
                "-Didea.trust.all.projects=true",
            ).map { "--jvm_flag=$it" },
            listOf(
                "dump-shared-index",
                "persistent-project",
            )
        ).flatten()

        logger.log("INTELLIJ") {
            it.println("Starting intellij...")
            for (x in cmdLine) {
                it.println(x)
            }
        }

        val process = ProcessBuilder()
            .command(cmdLine)
            .apply { environment().clear() }
            .start()

        Runtime.getRuntime().addShutdownHook(Thread {
            process.toHandle().descendants().forEach { it.destroyForcibly() }
            process.destroyForcibly()
        })

        logStream("INTELLIJ STDOUT", process.inputStream)
        logStream("INTELLIJ STDERR", process.errorStream)

        val result = process.waitFor()
        val stdout = process.inputStream.bufferedReader().use(BufferedReader::readText)
        val stderr = process.errorStream.bufferedReader().use(BufferedReader::readText)

        throw IOException("Intellij stopped with: $result, \nstdout:\n$stdout\nstderr:\n$stderr}")
    }

    override suspend fun start(): Result<Long> = runCatching {
        scope.launch {
            runCatching { startIntellij() }
                .onFailure { logger.err("INTELLIJ Exception", it) }
        }

        var result: Result<Long>? = null
        for (i in 0..10) {
            delay(1000)
            result = startInternal()
            if (result.isSuccess || i == 9) {
                break
            }
        }
        result!!.getOrThrow()
    }
}

fun createIntellijIndexingClient(args: IndexingWorkerArgs, logger: WorkerLogger): Result<IntellijIndexingClient> =  runCatching{
    val projectDir = args.projectDir ?: throw IllegalArgumentException("No project dir")
    if (args.debugEndpoint != null) {
        IntellijIndexingClientDebug(IntellijIndexingClientDebugArgs(
            logger,
            args.endpoint(),
            projectDir
        ))
    } else {
        IntellijIndexingClientStarter(IntellijIndexingClientStarterArgs(
            logger,
            args.endpoint(),
            projectDir,
            args.ideBinary ?: throw IllegalArgumentException("No ide runner"),
            args.pluginsDirectory ?: throw IllegalArgumentException("No ide runner"),
        ))
    }
}