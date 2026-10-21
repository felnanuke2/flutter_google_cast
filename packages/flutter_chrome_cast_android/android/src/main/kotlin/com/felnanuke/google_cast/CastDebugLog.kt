package com.felnanuke.google_cast

import android.util.Log

/**
 * Debug logging facade used across the Android implementation.
 *
 * Every call is routed through [GoogleCastLogger], so the level configured by
 * the application through `GoogleCastLogger.level` applies to all plugin-owned
 * Android logs. When the application did not opt in, the legacy behavior is
 * retained: debug logs are emitted only in debug builds and the original
 * `Log` priorities are used.
 */
object CastDebugLog {

    val isDebug: Boolean
        get() = try {
            BuildConfig.DEBUG
        } catch (_: Exception) {
            true
        }

    fun d(tag: String, message: String) {
        if (!isDebug) return
        GoogleCastLogger.verbose(tag) { message }
    }

    fun d(tag: String, message: String, throwable: Throwable?) {
        if (!isDebug) return
        GoogleCastLogger.verbose(tag, throwable = throwable) { message }
    }

    fun i(tag: String, message: String) {
        GoogleCastLogger.info(tag) { message }
    }

    fun w(tag: String, message: String) {
        GoogleCastLogger.warning(tag) { message }
    }

    fun w(tag: String, message: String, throwable: Throwable?) {
        GoogleCastLogger.warning(tag, throwable = throwable) { message }
    }

    fun e(tag: String, message: String) {
        GoogleCastLogger.error(tag) { message }
    }

    fun e(tag: String, message: String, throwable: Throwable?) {
        GoogleCastLogger.error(tag, throwable = throwable) { message }
    }

    fun castError(tag: String, operation: String, error: Throwable?): String {
        val errorMsg = buildString {
            append("[CAST ERROR] Operation: $operation")
            append(" | Error: ${error?.message ?: "Unknown error"}")
            error?.cause?.let { cause ->
                append(" | Caused by: ${cause.message ?: cause.javaClass.simpleName}")
            }
            error?.let {
                append(" | Stack: ${Log.getStackTraceString(it).take(500)}")
            }
        }
        if (isDebug) {
            GoogleCastLogger.error(tag) { errorMsg }
        }
        return errorMsg
    }

    fun castOperation(tag: String, operation: String, details: Map<String, Any?> = emptyMap()) {
        if (!isDebug) return
        val detailStr = if (details.isEmpty()) "" else " | ${
            details.entries.joinToString(", ") { "${it.key}=${it.value}" }
        }"
        GoogleCastLogger.verbose(tag) { "[CAST_OP] $operation$detailStr" }
    }

    fun castResult(tag: String, operation: String, success: Boolean, details: String = "") {
        if (!isDebug) return
        val status = if (success) "SUCCESS" else "FAILED"
        val detailStr = if (details.isEmpty()) "" else " | $details"
        GoogleCastLogger.verbose(tag) { "[CAST_RESULT] $operation -> $status$detailStr" }
    }

    fun sessionEvent(tag: String, event: String, sessionId: String?, deviceId: String?, extra: String = "") {
        if (!isDebug) return
        GoogleCastLogger.verbose(tag) {
            "[SESSION] $event | sessionId=$sessionId | deviceId=$deviceId${if (extra.isNotEmpty()) " | $extra" else ""}"
        }
    }

    fun mediaEvent(tag: String, event: String, details: Map<String, Any?> = emptyMap()) {
        if (!isDebug) return
        val detailStr = if (details.isEmpty()) "" else " | ${
            details.entries.joinToString(", ") { "${it.key}=${it.value}" }
        }"
        GoogleCastLogger.verbose(tag) { "[MEDIA] $event$detailStr" }
    }

    fun discoveryEvent(tag: String, event: String, details: Map<String, Any?> = emptyMap()) {
        if (!isDebug) return
        val detailStr = if (details.isEmpty()) "" else " | ${
            details.entries.joinToString(", ") { "${it.key}=${it.value}" }
        }"
        GoogleCastLogger.verbose(tag) { "[DISCOVERY] $event$detailStr" }
    }
}
