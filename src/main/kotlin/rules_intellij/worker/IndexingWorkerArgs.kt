package rules_intellij.worker

import com.beust.jcommander.JCommander
import com.beust.jcommander.Parameter

open class IndexingWorkerArgs {
    @Parameter(names = ["--persistent_worker"])
    var isPersistent = false

    @Parameter(names = ["--debug_log"])
    var debugLog: String? = null

    @Parameter(names = ["--debug_endpoint"])
    var debugEndpoint: String? = null

    @Parameter(names = ["--project_dir"])
    var projectDir: String? = null

    @Parameter(names = ["--out_dir"])
    var outDir: String? = null

    @Parameter(names = ["--target"])
    var target: String? = null

    @Parameter(names = ["--name"])
    var name: String? = null

    @Parameter(names = ["--ide_binary"])
    var ideBinary: String? = null

    @Parameter(names = ["--plugins_directory"])
    var pluginsDirectory: String? = null

    @Parameter(names = ["-s"])
    var sources: List<String> = ArrayList()
    fun endpoint() = debugEndpoint ?:  "0.0.0.0:9000"

    fun parseArgs(args: Array<String>) {
        JCommander
            .newBuilder()
            .addObject(this)
            .build()
            .parse(*args)
    }
}