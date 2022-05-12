package rules_intellij.indexing

import com.intellij.indexing.shared.generator.*
import com.intellij.indexing.shared.ultimate.persistent.rpc.*
import com.intellij.indexing.shared.ultimate.project.ProjectSharedIndexes
import com.intellij.indexing.shared.util.ArgsParser
import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.project.Project
import com.intellij.openapi.roots.ContentIterator
import com.intellij.openapi.vfs.LocalFileSystem
import com.intellij.openapi.vfs.VirtualFile
import com.intellij.openapi.vfs.VirtualFileFilter
import com.intellij.util.indexing.roots.IndexableFilesIterator
import com.intellij.util.indexing.roots.kind.IndexableSetOrigin
import io.grpc.Server
import io.grpc.netty.NettyServerBuilder
import io.grpc.Status
import io.grpc.StatusException

import io.netty.channel.epoll.Epoll
import io.netty.channel.epoll.EpollServerDomainSocketChannel
import io.netty.channel.epoll.EpollEventLoopGroup;
import io.netty.channel.kqueue.KQueue
import io.netty.channel.kqueue.KQueueServerDomainSocketChannel
import io.netty.channel.kqueue.KQueueEventLoopGroup
import io.netty.channel.unix.DomainSocketAddress

import java.nio.file.Path
import java.nio.file.Paths

class PersistentProjectArgs(parser: ArgsParser) {
  val port by parser.arg(
    "port",
    "port to listen on"
  ).int { 9000 }

  val domainSocket by parser.arg(
    "socket",
    "unix domain socket to listen on",
  ).stringOrNull()
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

  fun run(server: Server, descr: String) {
    server.start()
    ConsoleLog.info("Indexing Server started: " + descr)
    server.awaitTermination()
    ConsoleLog.info("Indexing Server shutdown")
  }

  override fun executeCommand(args: PersistentProjectArgs, indicator: ProgressIndicator) {
    System.setProperty("idea.skip.indices.initialization", "true")
    System.setProperty("idea.force.dumb.queue.tasks", "true")
    System.setProperty("idea.suspend.indexes.initialization", "true")
    System.setProperty("intellij.disable.shared.indexes", true.toString())
    System.setProperty("shared.indexes.download", false.toString())
    System.setProperty("intellij.hash.as.local.file.timestamp", true.toString())
    System.setProperty("idea.trust.all.projects", true.toString())

    if (args.domainSocket == null) {
      run(NettyServerBuilder
        .forPort(args.port)
        .addService(IndexingService(indicator, args))
        .build(), "${args.port}")
    } else if (Epoll.isAvailable()) {
      run(NettyServerBuilder
        .forAddress(DomainSocketAddress(args.domainSocket!!))
        .bossEventLoopGroup(EpollEventLoopGroup(1))
        .workerEventLoopGroup(EpollEventLoopGroup(4))
        .channelType(EpollServerDomainSocketChannel::class.java)
        .build(), args.domainSocket!!)
    } else if (KQueue.isAvailable()) {
      run(NettyServerBuilder
        .forAddress(DomainSocketAddress(args.domainSocket!!))
        .bossEventLoopGroup(KQueueEventLoopGroup(1))
        .workerEventLoopGroup(KQueueEventLoopGroup(4))
        .channelType(KQueueServerDomainSocketChannel::class.java)
        .build(), args.domainSocket!!)
    } else {
      throw RuntimeException("Unsupported OS '" + System.getProperty("os.name") + "', only Unix and Mac are supported")
    }
  }
}