package rules_intellij.worker;

import com.google.common.util.concurrent.FutureCallback;
import com.google.common.util.concurrent.Futures;
import io.grpc.Channel;
import io.grpc.ManagedChannelBuilder;

import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpc;
import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpc.DaemonFutureStub;
import com.intellij.indexing.shared.ultimate.persistent.rpc.DaemonGrpc.DaemonBlockingStub;
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexRequest;
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexResponse;
import com.intellij.indexing.shared.ultimate.persistent.rpc.StartupRequest;
import com.intellij.indexing.shared.ultimate.persistent.rpc.StartupResponse;

import java.util.concurrent.Executors;
import java.util.concurrent.ExecutorService;

public class IntellijIndexingPersistentClient {
    private DebugLogger logger;
    private final DaemonFutureStub futureStub;
    private final DaemonBlockingStub blockingStub;
    private final ExecutorService executor = Executors.newFixedThreadPool(1);

    public IntellijIndexingPersistentClient(DebugLogger logger, String target) {
        this.logger = logger;
        Channel channel = ManagedChannelBuilder.forTarget(target)
            .usePlaintext()
            .build();
        this.futureStub = DaemonGrpc.newFutureStub(channel);
        this.blockingStub = DaemonGrpc.newBlockingStub(channel);
    }

    public long start(String projectDir) {
        StartupRequest request = StartupRequest.newBuilder()
            .setProjectDir(System.getProperty("user.dir") + "/" + projectDir)
            .build();

        logger.log("StartupRequest",request);
        StartupResponse response = blockingStub.start(request);
        logger.log("StartupResponse",response);
        return response.getProjectId();
    }

    public void index(IndexRequest request, FutureCallback<IndexResponse> callback) {
        logger.log("IndexRequest",request);
        Futures.addCallback(
            futureStub.index(request),
            new FutureCallback<IndexResponse>() {
                @Override
                public void onSuccess(IndexResponse response) {
                    logger.log("IndexResponse",response);
                    callback.onSuccess(response);
                }

                @Override
                public void onFailure(Throwable error) {
                    logger.log("IndexResponseError", error.toString());
                    callback.onFailure(error);
                }
            },
            executor
        );
    }

}
