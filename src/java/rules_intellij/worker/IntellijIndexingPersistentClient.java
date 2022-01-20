package rules_intellij.worker;

import io.grpc.Channel;
import io.grpc.ManagedChannelBuilder;

import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpc;
import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpc.DaemonBlockingStub;
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexRequest;
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexResponse;
import com.intellij.indexing.shared.ultimate.persistent.rpc.StartupRequest;
import com.intellij.indexing.shared.ultimate.persistent.rpc.StartupResponse;

public class IntellijIndexingPersistentClient {
    private DebugLogger logger;
    private final DaemonBlockingStub stub;

    public IntellijIndexingPersistentClient(DebugLogger logger, String target) {
        this.logger = logger;
        Channel channel = ManagedChannelBuilder.forTarget(target)
            .usePlaintext()
            .build();
        this.stub = DaemonGrpc.newBlockingStub(channel);
    }

    public long start(String projectDir) {
        StartupRequest request = StartupRequest.newBuilder()
            .setProjectDir(System.getProperty("user.dir") + "/" + projectDir)
            .build();
        logger.log("StartupRequest",request);
        StartupResponse response = stub.start(request);
        logger.log("StartupResponse",response);
        return response.getProjectId();
    }

    public IndexResponse index(IndexRequest request) {
        logger.log("IndexRequest",request);
        IndexResponse response = stub.index(request);
        logger.log("IndexResponse", response);
        return response;
    }

}
