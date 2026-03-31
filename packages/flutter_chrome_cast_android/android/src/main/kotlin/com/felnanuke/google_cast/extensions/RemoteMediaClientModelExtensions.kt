package com.felnanuke.google_cast.extensions

import com.felnanuke.google_cast.pigeon.LiveSeekableRange
import com.felnanuke.google_cast.pigeon.LoadMediaRequestPigeon
import com.felnanuke.google_cast.pigeon.MediaInfo
import com.felnanuke.google_cast.pigeon.MediaQueueItem
import com.felnanuke.google_cast.pigeon.MediaResumeStatePigeon
import com.felnanuke.google_cast.pigeon.MediaStatus
import com.felnanuke.google_cast.pigeon.MediaTrack
import com.felnanuke.google_cast.pigeon.QueueLoadOptionsPigeon
import com.felnanuke.google_cast.pigeon.RepeatModePigeon
import com.felnanuke.google_cast.pigeon.SeekOptionPigeon
import com.felnanuke.google_cast.pigeon.Volume
import com.google.android.gms.cast.MediaInfo as CastMediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaQueueItem as CastMediaQueueItem
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.MediaStatus as CastMediaStatus
import com.google.android.gms.cast.MediaTrack as CastMediaTrack
import org.json.JSONArray
import org.json.JSONObject

fun MediaTrack.toCastMediaTrack(): CastMediaTrack {
    val builder = CastMediaTrack.Builder(trackId, type.toInt())
        .setContentId(trackContentId)
        .setSubtype(subtype.toInt())
        .setName(name)
        .setLanguage(language)

    if (trackContentType.isNotBlank()) {
        builder.setContentType(trackContentType)
    }

    return builder.build()
}

fun MediaInfo.toCastMediaInfo(): CastMediaInfo? {
    if (contentId.isBlank()) {
        return null
    }

    val builder = CastMediaInfo.Builder(contentId)

    if (contentUrl.isNotBlank()) {
        builder.setContentUrl(contentUrl)
    }
    if (contentType.isNotBlank()) {
        builder.setContentType(contentType)
    }

    builder.setStreamType(
        when (streamType) {
            "BUFFERED" -> CastMediaInfo.STREAM_TYPE_BUFFERED
            "LIVE" -> CastMediaInfo.STREAM_TYPE_LIVE
            "NONE" -> CastMediaInfo.STREAM_TYPE_NONE
            else -> CastMediaInfo.STREAM_TYPE_INVALID
        }
    )

    val castTracks = tracks?.mapNotNull { it?.toCastMediaTrack() }.orEmpty()
    if (castTracks.isNotEmpty()) {
        builder.setMediaTracks(castTracks)
    }

    customData?.let { builder.setCustomData(it.toJsonObject()) }

    return builder.build()
}

fun MediaQueueItem.toCastMediaQueueItem(): CastMediaQueueItem? {
    val castMedia = media?.toCastMediaInfo() ?: return null
    val builder = CastMediaQueueItem.Builder(castMedia)
        .setItemId(itemId.toInt())
        .setPreloadTime(preLoadTime.toDouble())
        .setStartTime(startTime.toDouble())
        .setPlaybackDuration(playbackDuration.toDouble())
        .setAutoplay(autoplay)

    activeTrackIds?.mapNotNull { it }?.toLongArray()?.let { builder.setActiveTrackIds(it) }
    customData?.let { builder.setCustomData(it.toJsonObject()) }

    return builder.build()
}

fun SeekOptionPigeon.toCastSeekOptions(): MediaSeekOptions {
    val resumeState = when (resumeState) {
        MediaResumeStatePigeon.PLAY -> 0
        MediaResumeStatePigeon.PAUSE -> 1
        MediaResumeStatePigeon.UNCHANGED -> 2
    }

    return MediaSeekOptions.Builder()
        .setPosition(position * 1000)
        .setResumeState(resumeState)
        .setIsSeekToInfinite(seekToInfinity)
        .build()
}

fun RepeatModePigeon?.toCastRepeatMode(): Int {
    return when (this) {
        RepeatModePigeon.ALL -> CastMediaStatus.REPEAT_MODE_REPEAT_ALL
        RepeatModePigeon.SINGLE -> CastMediaStatus.REPEAT_MODE_REPEAT_SINGLE
        RepeatModePigeon.ALL_AND_SHUFFLE -> CastMediaStatus.REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE
        RepeatModePigeon.OFF, null -> CastMediaStatus.REPEAT_MODE_REPEAT_OFF
    }
}

fun QueueLoadOptionsPigeon?.toQueueCustomDataJson(): JSONObject {
    return this?.customData?.toJsonObject() ?: JSONObject()
}

fun LoadMediaRequestPigeon.toCastMediaLoadRequestData(mediaInfo: CastMediaInfo): MediaLoadRequestData {
    val builder = MediaLoadRequestData.Builder()
        .setMediaInfo(mediaInfo)
        .setAutoplay(autoPlay)
        .setCurrentTime(playPosition * 1000)
        .setPlaybackRate(playbackRate)

    customData?.let { builder.setCustomData(it.toJsonObject()) }
    activeTrackIds?.mapNotNull { it }?.toLongArray()?.let { builder.setActiveTrackIds(it) }
    credentials?.let { builder.setCredentials(it) }
    credentialsType?.let { builder.setCredentialsType(it) }

    return builder.build()
}

fun CastMediaTrack.toPigeonMediaTrack(): MediaTrack {
    return MediaTrack(
        trackId = id,
        type = type.toLong(),
        trackContentId = contentId ?: "",
        trackContentType = contentType ?: "",
        subtype = subtype.toLong(),
        name = name ?: "",
        language = language ?: ""
    )
}

fun CastMediaInfo.toPigeonMediaInfo(): MediaInfo {
    val stream = when (streamType) {
        CastMediaInfo.STREAM_TYPE_BUFFERED -> "BUFFERED"
        CastMediaInfo.STREAM_TYPE_LIVE -> "LIVE"
        CastMediaInfo.STREAM_TYPE_NONE -> "NONE"
        else -> "NONE"
    }

    return MediaInfo(
        contentId = contentId ?: "",
        contentType = contentType ?: "",
        streamType = stream,
        contentUrl = contentUrl ?: "",
        duration = streamDuration,
        customData = customData?.toMapRecursive(),
        tracks = mediaTracks?.map { it.toPigeonMediaTrack() }
    )
}

fun CastMediaQueueItem.toPigeonMediaQueueItem(): MediaQueueItem {
    return MediaQueueItem(
        itemId = itemId.toLong(),
        preLoadTime = preloadTime.toLong(),
        startTime = startTime.toLong(),
        playbackDuration = playbackDuration.toLong(),
        media = media?.toPigeonMediaInfo(),
        autoplay = autoplay,
        activeTrackIds = activeTrackIds?.map { it.toLong() },
        customData = customData?.toMapRecursive()
    )
}

fun CastMediaStatus.toPigeonMediaStatus(): MediaStatus {
    val player = when (playerState) {
        CastMediaStatus.PLAYER_STATE_PLAYING -> "PLAYING"
        CastMediaStatus.PLAYER_STATE_PAUSED -> "PAUSED"
        CastMediaStatus.PLAYER_STATE_BUFFERING -> "BUFFERING"
        CastMediaStatus.PLAYER_STATE_IDLE -> "IDLE"
        else -> "UNKNOWN"
    }

    val idle = when (idleReason) {
        CastMediaStatus.IDLE_REASON_FINISHED -> "FINISHED"
        CastMediaStatus.IDLE_REASON_CANCELED -> "CANCELED"
        CastMediaStatus.IDLE_REASON_INTERRUPTED -> "INTERRUPTED"
        CastMediaStatus.IDLE_REASON_ERROR -> "ERROR"
        else -> "NONE"
    }

    val repeat = when (queueRepeatMode) {
        CastMediaStatus.REPEAT_MODE_REPEAT_ALL -> "ALL"
        CastMediaStatus.REPEAT_MODE_REPEAT_SINGLE -> "SINGLE"
        CastMediaStatus.REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE -> "ALL_AND_SHUFFLE"
        else -> "OFF"
    }

    val range = liveSeekableRange?.let {
        LiveSeekableRange(
            start = it.startTime,
            end = it.endTime,
            isMovingWindow = it.isMovingWindow,
            isLiveDone = it.isLiveDone
        )
    }

    return MediaStatus(
        mediaSessionId = toJson().optLong("mediaSessionId"),
        playerState = player,
        idleReason = idle,
        playbackRate = playbackRate,
        media = mediaInfo?.toPigeonMediaInfo(),
        volume = Volume(
            level = streamVolume.toDouble(),
            muted = isMute
        ),
        repeatMode = repeat,
        currentItemId = currentItemId.toLong(),
        activeTrackIds = activeTrackIds?.map { it.toLong() },
        liveSeekableRange = range
    )
}

fun Map<*, *>.toJsonObject(): JSONObject {
    val json = JSONObject()
    forEach { (key, value) ->
        if (key != null) {
            json.put(key.toString(), value.toJsonValue())
        }
    }
    return json
}

fun JSONObject.toMapRecursive(): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = keys()
    while (keys.hasNext()) {
        val key = keys.next()
        val value = opt(key)
        map[key] = when (value) {
            JSONObject.NULL -> null
            is JSONObject -> value.toMapRecursive()
            is JSONArray -> value.toListRecursive()
            else -> value
        }
    }
    return map
}

private fun JSONArray.toListRecursive(): List<Any?> {
    val list = mutableListOf<Any?>()
    for (index in 0 until length()) {
        val value = opt(index)
        list.add(
            when (value) {
                JSONObject.NULL -> null
                is JSONObject -> value.toMapRecursive()
                is JSONArray -> value.toListRecursive()
                else -> value
            }
        )
    }
    return list
}

private fun Any?.toJsonValue(): Any? {
    return when (this) {
        null -> JSONObject.NULL
        is Map<*, *> -> toJsonObject()
        is List<*> -> {
            val array = JSONArray()
            forEach { array.put(it.toJsonValue()) }
            array
        }
        else -> this
    }
}