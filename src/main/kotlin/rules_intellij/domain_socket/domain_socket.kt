package rules_intellij.domain_socket

import io.grpc.BindableService
import io.grpc.ManagedChannel
import io.grpc.Server
import io.grpc.netty.NettyChannelBuilder
import io.grpc.netty.NettyServerBuilder
import io.netty.channel.epoll.Epoll
import io.netty.channel.epoll.EpollDomainSocketChannel
import io.netty.channel.epoll.EpollEventLoopGroup
import io.netty.channel.epoll.EpollServerDomainSocketChannel
import io.netty.channel.kqueue.KQueue
import io.netty.channel.kqueue.KQueueDomainSocketChannel
import io.netty.channel.kqueue.KQueueEventLoopGroup
import io.netty.channel.kqueue.KQueueServerDomainSocketChannel
import io.netty.channel.unix.DomainSocketAddress

private fun<T> withUnsupportedException(): T {
    throw RuntimeException("Unsupported OS '${System.getProperty("os.name") }', only Unix and Mac are supported")
}

class NettyDomainSocketServerBuilder(socket: String) {
    companion object {
        fun forDomainSocket(socket: String) = NettyDomainSocketServerBuilder(socket)
    }

    private var innerBuilder = NettyServerBuilder
        .forAddress(DomainSocketAddress(socket))
        .channelType(
            if (Epoll.isAvailable())
                EpollServerDomainSocketChannel::class.java
            else if (KQueue.isAvailable())
                KQueueServerDomainSocketChannel::class.java
            else
                withUnsupportedException()
        )

    private fun wrapInner(inner: NettyServerBuilder): NettyDomainSocketServerBuilder {
        innerBuilder = inner
        return this
    }
    
    fun eventGroups(boss: Int, worker: Int) = wrapInner(
        if (Epoll.isAvailable())
            innerBuilder
                .bossEventLoopGroup(EpollEventLoopGroup(boss))
                .workerEventLoopGroup(EpollEventLoopGroup(worker))
        else if (KQueue.isAvailable())
            innerBuilder
                .bossEventLoopGroup(KQueueEventLoopGroup(boss))
                .workerEventLoopGroup(KQueueEventLoopGroup(worker))
        else
            withUnsupportedException()
    )

    fun addService(bindableService: BindableService?) = innerBuilder.addService(bindableService)

    fun build(): Server = innerBuilder.build()
}

class NettyDomainSocketChannelBuilder(socket: String) {
    companion object {
        fun forDomainSocket(socket: String) = NettyDomainSocketChannelBuilder(socket)
    }

    private var innerBuilder = NettyChannelBuilder
        .forAddress(DomainSocketAddress(socket))
        .eventLoopGroup(EpollEventLoopGroup())
        .channelType(
            if (Epoll.isAvailable())
                EpollDomainSocketChannel::class.java
            else if (KQueue.isAvailable())
                KQueueDomainSocketChannel::class.java
            else
                withUnsupportedException()
        )

    private fun wrapInner(inner: NettyChannelBuilder): NettyDomainSocketChannelBuilder {
        innerBuilder = inner
        return this
    }

    fun usePlainText() = wrapInner(innerBuilder.usePlaintext())
    fun build(): ManagedChannel = innerBuilder.build()
}