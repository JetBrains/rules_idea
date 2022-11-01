package rules_intellij.domain_socket;

import java.lang.RuntimeException;

import io.grpc.BindableService;
import io.grpc.Server;
import io.grpc.netty.NettyServerBuilder;
import io.netty.channel.epoll.Epoll;
import io.netty.channel.epoll.EpollEventLoopGroup;
import io.netty.channel.epoll.EpollServerDomainSocketChannel;
import io.netty.channel.kqueue.KQueue;
import io.netty.channel.kqueue.KQueueEventLoopGroup;
import io.netty.channel.kqueue.KQueueServerDomainSocketChannel;
import io.netty.channel.unix.DomainSocketAddress;

public class NettyDomainSocketServerBuilder {

    public static NettyDomainSocketServerBuilder forDomainSocket(String socket) {
        return new NettyDomainSocketServerBuilder(socket);
    }

    private final NettyServerBuilder innerBuilder;

    NettyDomainSocketServerBuilder(String socket) {
        innerBuilder = NettyServerBuilder
            .forAddress(new DomainSocketAddress(socket));

        if (Epoll.isAvailable()) {
            innerBuilder.channelType(EpollServerDomainSocketChannel.class);
        } else if (KQueue.isAvailable()) {
            innerBuilder.channelType(KQueueServerDomainSocketChannel.class);
        } else {
            throw new RuntimeException("Unsupported OS '" + System.getProperty("os.name") + "', only Unix and Mac are supported");
        }
    }

    public NettyDomainSocketServerBuilder eventGroups(int boss, int worker) {
        if (Epoll.isAvailable()) {
            innerBuilder
                .bossEventLoopGroup(new EpollEventLoopGroup(boss))
                .workerEventLoopGroup(new  EpollEventLoopGroup(worker));
        } else if (KQueue.isAvailable()) {
            innerBuilder
                .bossEventLoopGroup(new KQueueEventLoopGroup(boss))
                .workerEventLoopGroup(new KQueueEventLoopGroup(worker));
        }
        return this;
    }

    public NettyDomainSocketServerBuilder addService(BindableService bindableService) {
        innerBuilder.addService(bindableService);
        return this;
    }

    public Server build() {
        return innerBuilder.build();
    }
}