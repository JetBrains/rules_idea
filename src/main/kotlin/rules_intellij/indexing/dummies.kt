package rules_intellij.indexing

import com.intellij.openapi.progress.ProgressIndicator
import com.intellij.openapi.application.ModalityState
import com.intellij.openapi.progress.StandardProgressIndicator

class DummyModalityState: ModalityState() {
    override fun toString(): String = ""
    override fun dominates(p0: ModalityState): Boolean = false
}

class DummyIndicator: StandardProgressIndicator {
    private var running = false
    private var cancelled = false

    override fun start() {
        running = true
        cancelled = false
    }

    override fun stop() {
        running = false
        cancelled = false
    }

    override fun cancel() {
        running = false
        cancelled = true
    }

    override fun isRunning(): Boolean = running
    override fun isCanceled(): Boolean = cancelled

    override fun setText(p0: String?) {}
    override fun getText(): String = ""

    override fun setText2(p0: String?) {}
    override fun getText2(): String = ""

    override fun getFraction(): Double = 0.0
    override fun setFraction(p0: Double) {}

    override fun pushState() {}
    override fun popState() {}

    override fun isModal(): Boolean = false

    override fun getModalityState(): ModalityState = DummyModalityState()

    override fun setModalityProgress(p0: ProgressIndicator?) {}

    override fun isIndeterminate(): Boolean = true
    override fun setIndeterminate(p0: Boolean) {}

    override fun checkCanceled() {}

    override fun isPopupWasShown(): Boolean = false
    override fun isShowing(): Boolean = false
}