package rules_intellij.worker;

import java.io.*;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import com.beust.jcommander.JCommander;
import com.beust.jcommander.Parameter;

import com.google.devtools.build.lib.worker.WorkerProtocol.*;
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexRequest;
import com.intellij.indexing.shared.ultimate.persistent.rpc.IndexResponse;

public final class IndexingWorker {

    static class WorkerArgs {
        @Parameter(names = "--persistent_worker")
        public boolean isPersistent;

        @Parameter(names = "--debug_log")
        public String debugLog;

        @Parameter(names = "--debug_endpoint")
        public String debugEndpoint;

        @Parameter(names = "--project_dir")
        public String projectDir;

        @Parameter(names = "--out_dir")
        public String outDir;

        @Parameter(names = "--target")
        public String target;

        @Parameter(names = "--name")
        public String name;

        @Parameter(names = "-s")
        public List<String> sources = new ArrayList<>();
    }

    private static void startIntellij() {
        // dump-shared-index persistent-project
        // -Dcaches.indexerThreadsCount=1
        throw new UnsupportedOperationException("not implemented yet");
    }

    private static void onStartup(String[] rawArgs, WorkerArgs args, DebugLogger logger) throws IOException {
        logger.log("ARGS", (out) -> {
            for (String arg: rawArgs) {
                out.println(arg);
            }
        });
        logger.log("ENV", (out) -> {
            for (Map.Entry<String, String> entry : System.getenv().entrySet()) {
                out.println(entry.getKey() + " : " + entry.getValue());
            }
        });

        if (args.debugEndpoint == null) {
            startIntellij();
        }
    }

    private static class Work extends WorkerArgs {
        private final DebugLogger logger;
        private final IntellijIndexingPersistentClient client;
        private final long projectId;

        public Work(DebugLogger logger, IntellijIndexingPersistentClient client, long projectId) {
            this.logger = logger;
            this.client = client;
            this.projectId = projectId;
        }

        WorkResponse processRequest(WorkRequest workRequest) throws IOException {
            logger.log("WorkRequest", workRequest);

            IndexRequest request = IndexRequest.newBuilder()
                .setProjectId(projectId)
                .setIndexDebugName(target)
                .setIndexId(target
                    .replace("//", "")
                    .replace("/","_")
                    .replace(":", "_"))
                .addAllSources(sources)
                .setProjectRoot(System.getProperty("user.dir"))
                .build();

            IndexResponse indexResponse = client.index(request);
            Path outPath = Paths.get(outDir);
            new File(indexResponse.getIjxPath()).renameTo(outPath.resolve(name + ".ijx").toFile());
            new File(indexResponse.getIjxMetadataPath()).renameTo(outPath.resolve(name + ".ijx.metadata.json").toFile());
            new File(indexResponse.getIjxSha256Path()).renameTo(outPath.resolve(name + ".ijx.sha256").toFile());

            WorkResponse workResponse = WorkResponse.newBuilder()
                .setRequestId(workRequest.getRequestId())
                .build();

            logger.log("WorkResponse", workResponse);
            return workResponse;
        }

    }

    public static void main(String[] args) throws IOException {
        WorkerArgs startupArgs = new WorkerArgs();
        JCommander
            .newBuilder()
            .addObject(startupArgs)
            .build()
            .parse(args);

        if (!startupArgs.isPersistent) {
            throw new UnsupportedOperationException("Only persistent workers supported");
        }

        DebugLogger logger = new DebugLogger(startupArgs.debugLog);
        onStartup(args, startupArgs, logger);

        IntellijIndexingPersistentClient client = new IntellijIndexingPersistentClient(logger, startupArgs.debugEndpoint);
        long projectId = client.start(startupArgs.projectDir);

        while (true) {
            WorkRequest request = WorkRequest.parseDelimitedFrom(System.in);
            if (request == null) {
                break;
            }

            Work worker = new Work(logger, client, projectId);
            JCommander.newBuilder()
                .addObject(worker)
                .build()
                .parse(request.getArgumentsList().toArray(new String[] {}));

            WorkResponse response = worker.processRequest(request);
            response.writeDelimitedTo(System.out);
        }
    }

}
