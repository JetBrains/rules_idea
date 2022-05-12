package rules_intellij.worker

//import io.grpc.netty.NettyChannelBuilder;
//import io.netty.channel.epoll.Epoll
//import io.netty.channel.epoll.EpollDomainSocketChannel
//import io.netty.channel.epoll.EpollEventLoopGroup;
//import io.netty.channel.kqueue.KQueue
//import io.netty.channel.kqueue.KQueueDomainSocketChannel
//import io.netty.channel.kqueue.KQueueEventLoopGroup
//import io.netty.channel.unix.DomainSocketAddress

import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpcKt.DaemonCoroutineStub
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexRequest
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexResponse
import com.intellij.indexing.shared.ultimate.persistent.rpc.StartupRequest
import io.grpc.ManagedChannel
import io.grpc.ManagedChannelBuilder
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.io.File
import java.io.*
import java.nio.channels.FileChannel
import java.nio.channels.OverlappingFileLockException
import java.nio.file.Path
import java.nio.file.Paths
import java.util.*
import kotlin.io.path.createTempDirectory


interface IntellijIndexingClientArgs {
    val logger: WorkerLogger
    val projectDir: String
    val channel: ManagedChannel
}

abstract class IntellijIndexingClient(args: IntellijIndexingClientArgs) {
    val logger = args.logger.apply {
        log("IntellijIndexingClient", args.projectDir)
    }
    private val projectDir = args.projectDir
    private val stub = DaemonCoroutineStub(args.channel)

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
    override val projectDir: String,
    val endpoint: String
): IntellijIndexingClientArgs {
    override val channel: ManagedChannel
        get() = ManagedChannelBuilder.forTarget(endpoint)
            .usePlaintext()
            .build()
}

class IntellijIndexingClientDebug(args: IntellijIndexingClientDebugArgs): IntellijIndexingClient(args) {

    override suspend fun start(): Result<Long> = startInternal()
}

class IntellijIndexingClientStarterArgs(
    override val logger: WorkerLogger,
    override val projectDir: String,
    val javaBin: String,
    val ideHomeDir: String,
    val ideRunner: String,
    val pluginsDir: String,
): IntellijIndexingClientArgs {
    val dir: Path = createTempDirectory()
    val port = 9000 + (0..999).random()
//    val socket = dir.resolve("intellij.socket")

    override val channel: ManagedChannel
        get() = ManagedChannelBuilder.forTarget("0.0.0.0:$port")
            .usePlaintext()
            .build()
//        get() {
//            if (Epoll.isAvailable()) {
//                return NettyChannelBuilder
//                    .forAddress(DomainSocketAddress(socket.toAbsolutePath().toString()))
//                    .eventLoopGroup(EpollEventLoopGroup())
//                    .channelType(EpollDomainSocketChannel::class.java)
//                    .build()
//            } else if (KQueue.isAvailable()) {
//                return NettyChannelBuilder
//                    .forAddress(DomainSocketAddress(socket.toAbsolutePath().toString()))
//                    .eventLoopGroup(KQueueEventLoopGroup())
//                    .channelType(KQueueDomainSocketChannel::class.java)
//                    .build()
//            }
//            throw RuntimeException("Unsupported OS '" + System.getProperty("os.name") + "', only Unix and Mac are supported")
//        }
}

class IntellijIndexingClientStarter(args: IntellijIndexingClientStarterArgs): IntellijIndexingClient(args) {
    private val dir = args.dir
//    private val socket = args.socket
    private val port = args.port
    private val javaBin = args.javaBin
    private val ideHomeDir = args.ideHomeDir
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
        val path = Paths.get("").toAbsolutePath().toString()
        val cmdLine = listOf(
            listOf(javaBin),
            listOf(
                "idea.home.path=$path/$ideHomeDir",
                "idea.config.path=$dir/config",
                "idea.system.path=$dir/system",
                "idea.plugins.path=$path/$pluginsDir",
                "idea.platform.prefix=Idea",
                "idea.initially.ask.config=false",
                "idea.skip.indices.initialization=true",
                "idea.force.dumb.queue.tasks=true",
                "idea.suspend.indexes.initialization=true",
                "intellij.disable.shared.indexes=true",
                "shared.indexes.download=false",
                "intellij.hash.as.local.file.timestamp=true",
                "idea.trust.all.projects=true",
            ).map { "-D$it" },
            listOf(
                "-jar",
                ideRunner,
                "dump-shared-index",
                "persistent-project",
                "--port=$port",
            )
        ).flatten()

        logger.log("INTELLIJ") {
            it.println("Starting intellij...")
            it.println("Working Directory = $path")
            for (x in cmdLine) {
                it.println(x)
            }
        }

        val process = ProcessBuilder()
            .command(cmdLine)
//            .apply { environment().clear() }
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
            args.debugEndpoint!!,
            projectDir
        ))
    } else {
        IntellijIndexingClientStarter(IntellijIndexingClientStarterArgs(
            logger,
            projectDir,
            args.javaBinary ?: throw IllegalArgumentException("No java binary"),
            args.ideHomeDir ?: throw IllegalArgumentException("No ide home dir"),
            args.ideBinary ?: throw IllegalArgumentException("No ide runner"),
            args.pluginsDirectory ?: throw IllegalArgumentException("No ide runner"),
        ))
    }
}