package rules_intellij.domain_socket;

import io.grpc.ManagedChannel;
import io.grpc.netty.NettyChannelBuilder;
import io.netty.channel.epoll.Epoll;
import io.netty.channel.epoll.EpollDomainSocketChannel;
import io.netty.channel.epoll.EpollEventLoopGroup;
import io.netty.channel.epoll.EpollServerDomainSocketChannel;
import io.netty.channel.kqueue.KQueue;
import io.netty.channel.kqueue.KQueueDomainSocketChannel;
import io.netty.channel.kqueue.KQueueEventLoopGroup;
import io.netty.channel.kqueue.KQueueServerDomainSocketChannel;
import io.netty.channel.unix.DomainSocketAddress;

public class NettyDomainSocketChannelBuilder {

    public static NettyDomainSocketChannelBuilder forDomainSocket(String socket) {
        return new NettyDomainSocketChannelBuilder(socket);
    }

    private final NettyChannelBuilder innerBuilder;

    NettyDomainSocketChannelBuilder(String socket) {
        innerBuilder = NettyChannelBuilder
            .forAddress(new DomainSocketAddress(socket));

        if (Epoll.isAvailable()) {
            innerBuilder
                .eventLoopGroup(new EpollEventLoopGroup())
                .channelType(EpollDomainSocketChannel.class);
        } else if (KQueue.isAvailable()) {
            innerBuilder
                .eventLoopGroup(new KQueueEventLoopGroup())
                .channelType(KQueueDomainSocketChannel.class);
        } else {
            throw new RuntimeException("Unsupported OS '" + System.getProperty("os.name") + "', only Unix and Mac are supported");
        }
    }

    public NettyDomainSocketChannelBuilder usePlainText() {
        innerBuilder.usePlaintext();
        return this;
    }

    public ManagedChannel build() {
        return innerBuilder.build();
    }

}