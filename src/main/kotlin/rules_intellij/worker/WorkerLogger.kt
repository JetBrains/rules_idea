package rules_intellij.worker

import java.io.PrintStream
import kotlin.system.exitProcess
import java.io.ByteArrayOutputStream
import java.nio.charset.StandardCharsets
import java.nio.file.Path
import kotlin.io.path.deleteIfExists

class WorkerLogger(debugDir: String?) {
    private val debugLog: String? = if (debugDir != null) {
        val dir = Path.of(debugDir)
        dir.toFile().mkdirs()
        dir.toString()
        dir.resolve("log").toString()
    } else {
        null
    }

    private var out: PrintStream? = if (debugLog != null) PrintStream(debugLog)  else null

    private fun log(tag: String, w: PrintStream?, f: (out: PrintStream) -> Unit) {
        val wout = w ?: return

        val baos = ByteArrayOutputStream()
        val utf8: String = StandardCharsets.UTF_8.name()
        val out = PrintStream(baos, false, utf8)

        out.println("########### $tag ###########")
        f(out)
        out.println("----------------------------")
        out.flush()

        wout.write(baos.toByteArray())
    }

    fun log(tag: String, f: (out: PrintStream) -> Unit) = log(tag, out, f)

    fun <T> log(tag: String, x: T) = log(tag) { it.println(x) }

    fun err(tag: String, e: Exception) {
        log(tag, out) {
            e.printStackTrace(it)
            it.println(e)
        }
        log(tag, System.err) {
            e.printStackTrace(it)
            it.println(e)
        }
        exitProcess(1)
    }

    fun <T> err(tag: String, x: T) {
        log(tag, x)
        log(tag, System.err) { it.println(x) }
        exitProcess(1)
    }
}