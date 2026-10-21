package com.felnanuke.google_cast

import android.util.Log

/** Log levels shared with the Dart logging API. */
private enum class CastLogLevel(
    val rank: Int,
    val androidPriority: Int,
) {
    NONE(0, Int.MAX_VALUE),
    ERROR(1, Log.ERROR),
    WARNING(2, Log.WARN),
    INFO(3, Log.INFO),
    VERBOSE(4, Log.DEBUG),
    ;

    companion object {
        fun fromWireValue(value: String?): CastLogLevel? = when (value) {
            "none" -> NONE
            "error" -> ERROR
            "warning" -> WARNING
            "info" -> INFO
            "verbose" -> VERBOSE
            else -> null
        }
    }
}

/** Central logger for messages emitted by the Android side of this plugin. */
internal object GoogleCastLogger {
    /**
     * `null` means that the app did not opt in. In that state, calls retain the
     * priority used by the legacy direct `Log.*` statement.
     */
    @Volatile
    private var configuredLevel: CastLogLevel? = null

    fun configure(wireValue: String?) {
        configuredLevel = CastLogLevel.fromWireValue(wireValue)
    }

    fun error(
        tag: String,
        legacyPriority: Int = Log.ERROR,
        throwable: Throwable? = null,
        message: () -> String,
    ) = write(CastLogLevel.ERROR, tag, legacyPriority, throwable, message)

    fun warning(
        tag: String,
        legacyPriority: Int = Log.WARN,
        throwable: Throwable? = null,
        message: () -> String,
    ) = write(CastLogLevel.WARNING, tag, legacyPriority, throwable, message)

    fun info(
        tag: String,
        legacyPriority: Int = Log.INFO,
        throwable: Throwable? = null,
        message: () -> String,
    ) = write(CastLogLevel.INFO, tag, legacyPriority, throwable, message)

    fun verbose(
        tag: String,
        legacyPriority: Int = Log.DEBUG,
        throwable: Throwable? = null,
        message: () -> String,
    ) = write(CastLogLevel.VERBOSE, tag, legacyPriority, throwable, message)

    private fun write(
        messageLevel: CastLogLevel,
        tag: String,
        legacyPriority: Int,
        throwable: Throwable?,
        message: () -> String,
    ) {
        val selectedLevel = configuredLevel
        if (selectedLevel != null &&
            (selectedLevel == CastLogLevel.NONE || messageLevel.rank > selectedLevel.rank)
        ) {
            return
        }

        val priority = selectedLevel?.let { messageLevel.androidPriority } ?: legacyPriority
        val text = message()
        when (priority) {
            Log.VERBOSE -> if (throwable == null) Log.v(tag, text) else Log.v(tag, text, throwable)
            Log.DEBUG -> if (throwable == null) Log.d(tag, text) else Log.d(tag, text, throwable)
            Log.INFO -> if (throwable == null) Log.i(tag, text) else Log.i(tag, text, throwable)
            Log.WARN -> if (throwable == null) Log.w(tag, text) else Log.w(tag, text, throwable)
            else -> if (throwable == null) Log.e(tag, text) else Log.e(tag, text, throwable)
        }
    }
}
