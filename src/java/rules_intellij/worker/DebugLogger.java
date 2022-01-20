package rules_intellij.worker;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.Map;

class DebugLogger {
    private final PrintWriter mOut;

    public DebugLogger(String debugLog) throws IOException {
        if (debugLog != null) {
            this.mOut = new PrintWriter(debugLog);
        } else {
            this.mOut = null;
        }
    }

    public interface LogClosure<T> {
        void log(PrintWriter out);
    }

    public <T> void log(String tag, LogClosure<T> f) {
        if (mOut == null) {
            return;
        }

        mOut.println("-------- " + tag + " --------");
        f.log(mOut);
        mOut.flush();
    }

    public <T> void log(String tag, T x) {
        if (mOut == null) {
            return;
        }

        mOut.println("-------- " + tag + " --------");
        mOut.println(x);
        mOut.flush();
    }
}
