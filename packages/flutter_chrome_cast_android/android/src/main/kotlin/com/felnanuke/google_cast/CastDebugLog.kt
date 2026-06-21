package com.felnanuke.google_cast

import android.util.Log

object CastDebugLog {

    val isDebug: Boolean
        get() = try {
            BuildConfig.DEBUG
        } catch (_: Exception) {
            true
        }

    fun d(tag: String, message: String) {
        if (isDebug) {
            Log.d(tag, message)
        }
    }

    fun d(tag: String, message: String, throwable: Throwable?) {
        if (isDebug) {
            Log.d(tag, message, throwable)
        }
    }

    fun i(tag: String, message: String) {
        if (isDebug) {
            Log.i(tag, message)
        }
        Log.i(tag, message)
    }

    fun w(tag: String, message: String) {
        Log.w(tag, message)
    }

    fun w(tag: String, message: String, throwable: Throwable?) {
        Log.w(tag, message, throwable)
    }

    fun e(tag: String, message: String) {
        Log.e(tag, message)
    }

    fun e(tag: String, message: String, throwable: Throwable?) {
        Log.e(tag, message, throwable)
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
            Log.e(tag, errorMsg)
        }
        return errorMsg
    }

    fun castOperation(tag: String, operation: String, details: Map<String, Any?> = emptyMap()) {
        if (!isDebug) return
        val detailStr = if (details.isEmpty()) "" else " | ${
            details.entries.joinToString(", ") { "${it.key}=${it.value}" }
        }"
        Log.d(tag, "[CAST_OP] $operation$detailStr")
    }

    fun castResult(tag: String, operation: String, success: Boolean, details: String = "") {
        if (!isDebug) return
        val status = if (success) "SUCCESS" else "FAILED"
        val detailStr = if (details.isEmpty()) "" else " | $details"
        Log.d(tag, "[CAST_RESULT] $operation -> $status$detailStr")
    }

    fun sessionEvent(tag: String, event: String, sessionId: String?, deviceId: String?, extra: String = "") {
        if (!isDebug) return
        Log.d(tag, "[SESSION] $event | sessionId=$sessionId | deviceId=$deviceId${if (extra.isNotEmpty()) " | $extra" else ""}")
    }

    fun mediaEvent(tag: String, event: String, details: Map<String, Any?> = emptyMap()) {
        if (!isDebug) return
        val detailStr = if (details.isEmpty()) "" else " | ${
            details.entries.joinToString(", ") { "${it.key}=${it.value}" }
        }"
        Log.d(tag, "[MEDIA] $event$detailStr")
    }

    fun discoveryEvent(tag: String, event: String, details: Map<String, Any?> = emptyMap()) {
        if (!isDebug) return
        val detailStr = if (details.isEmpty()) "" else " | ${
            details.entries.joinToString(", ") { "${it.key}=${it.value}" }
        }"
        Log.d(tag, "[DISCOVERY] $event$detailStr")
    }
}
