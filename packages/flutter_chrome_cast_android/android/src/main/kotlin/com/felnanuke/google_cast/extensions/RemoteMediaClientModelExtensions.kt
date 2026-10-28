package com.felnanuke.google_cast.extensions

import android.net.Uri
import com.felnanuke.google_cast.CastDebugLog
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
import com.felnanuke.google_cast.pigeon.TextTrackStylePigeon
import com.felnanuke.google_cast.pigeon.Volume
import com.google.android.gms.cast.MediaInfo as CastMediaInfo
import com.google.android.gms.cast.MediaLoadRequestData
import com.google.android.gms.cast.MediaMetadata
import com.google.android.gms.cast.MediaQueueItem as CastMediaQueueItem
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.MediaStatus as CastMediaStatus
import com.google.android.gms.cast.MediaTrack as CastMediaTrack
import com.google.android.gms.cast.TextTrackStyle as CastTextTrackStyle
import com.google.android.gms.common.images.WebImage
import com.felnanuke.google_cast.pigeon.MediaImagePigeon
import com.felnanuke.google_cast.pigeon.MediaMetadataPigeon
import org.json.JSONArray
import org.json.JSONObject
import java.text.ParseException
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import java.util.TimeZone

private const val TAG = "ModelExtensions"

fun MediaTrack.toCastMediaTrack(): CastMediaTrack {
    CastDebugLog.d(TAG, "toCastMediaTrack: trackId=$trackId, type=$type, contentId=$trackContentId, language=$language")
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
        CastDebugLog.e(TAG, "[CONVERSION ERROR] toCastMediaInfo: contentId is BLANK - cannot create CastMediaInfo without a content ID")
        CastDebugLog.e(TAG, "[CONVERSION ERROR] toCastMediaInfo: Received contentUrl=$contentUrl, contentType=$contentType, streamType=$streamType")
        return null
    }

    CastDebugLog.d(TAG, "toCastMediaInfo: contentId=$contentId, contentUrl=$contentUrl, contentType=$contentType, streamType=$streamType")

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
            else -> {
                CastDebugLog.w(TAG, "toCastMediaInfo: Unknown streamType='$streamType', using STREAM_TYPE_INVALID")
                CastMediaInfo.STREAM_TYPE_INVALID
            }
        }
    )

    // Stream duration: Flutter sends seconds, the SDK expects milliseconds.
    if (duration > 0) {
        builder.setStreamDuration(duration * 1000)
    }

    // HLS segment formats. Required for fragmented-MP4 HLS (e.g. PeerTube
    // VOD) to play on the Default Media Receiver: without the hint the
    // receiver cannot demux fMP4 segments and stays stuck in LOADING.
    // The dedicated pigeon fields take precedence over the legacy
    // customData keys.
    val hlsSegmentFormat = GoogleCastMediaInfoExtensions.hlsSegmentFormatFromName(
        this.hlsSegmentFormat
            ?: (customData?.get(GoogleCastMediaInfoExtensions.HLS_SEGMENT_FORMAT_KEY) as? String)
    )
    hlsSegmentFormat?.let {
        CastDebugLog.d(TAG, "toCastMediaInfo: Setting hlsSegmentFormat=$it")
        builder.setHlsSegmentFormat(it)
    }
    val hlsVideoSegmentFormat = GoogleCastMediaInfoExtensions.hlsVideoSegmentFormatFromName(
        this.hlsVideoSegmentFormat
            ?: (customData?.get(GoogleCastMediaInfoExtensions.HLS_VIDEO_SEGMENT_FORMAT_KEY) as? String)
    )
    hlsVideoSegmentFormat?.let {
        CastDebugLog.d(TAG, "toCastMediaInfo: Setting hlsVideoSegmentFormat=$it")
        builder.setHlsVideoSegmentFormat(it)
    }

    metadata?.toCastMediaMetadata()?.let {
        CastDebugLog.d(TAG, "toCastMediaInfo: Setting metadata (type=${it.mediaType})")
        builder.setMetadata(it)
    }

    val castTracks = tracks?.mapNotNull { it?.toCastMediaTrack() }.orEmpty()
    if (castTracks.isNotEmpty()) {
        builder.setMediaTracks(castTracks)
        CastDebugLog.d(TAG, "toCastMediaInfo: Added ${castTracks.size} media tracks")
    }

    customData?.let {
        CastDebugLog.d(TAG, "toCastMediaInfo: Setting customData")
        // The HLS segment format hints are an internal detail of the load
        // request and must not reach the receiver as custom metadata.
        builder.setCustomData(
            GoogleCastMediaInfoExtensions.withoutHlsSegmentFormats(it).toJsonObject()
        )
    }

    return builder.build()
}

/**
 * Converts the pigeon media metadata into a Cast SDK [MediaMetadata].
 *
 * Port of the legacy map based `GoogleCastMetadataBuilder.fromMap` to the
 * pigeon payload: the fields are stored under the canonical Cast metadata
 * keys so receivers display them, the ISO-8601 dates are converted with
 * [MediaMetadata.putDate] and the images are attached as [WebImage]s.
 */
fun MediaMetadataPigeon.toCastMediaMetadata(): MediaMetadata {
    val metadata = MediaMetadata(metadataType.toInt())

    title?.let { metadata.putString(MediaMetadata.KEY_TITLE, it) }
    subtitle?.let { metadata.putString(MediaMetadata.KEY_SUBTITLE, it) }
    studio?.let { metadata.putString(MediaMetadata.KEY_STUDIO, it) }
    artist?.let { metadata.putString(MediaMetadata.KEY_ARTIST, it) }
    albumName?.let { metadata.putString(MediaMetadata.KEY_ALBUM_TITLE, it) }
    albumArtist?.let { metadata.putString(MediaMetadata.KEY_ALBUM_ARTIST, it) }
    composer?.let { metadata.putString(MediaMetadata.KEY_COMPOSER, it) }
    seriesTitle?.let { metadata.putString(MediaMetadata.KEY_SERIES_TITLE, it) }
    location?.let { metadata.putString(MediaMetadata.KEY_LOCATION_NAME, it) }
    trackNumber?.let { metadata.putInt(MediaMetadata.KEY_TRACK_NUMBER, it.toInt()) }
    discNumber?.let { metadata.putInt(MediaMetadata.KEY_DISC_NUMBER, it.toInt()) }
    season?.let { metadata.putInt(MediaMetadata.KEY_SEASON_NUMBER, it.toInt()) }
    episode?.let { metadata.putInt(MediaMetadata.KEY_EPISODE_NUMBER, it.toInt()) }
    width?.let { metadata.putInt(MediaMetadata.KEY_WIDTH, it.toInt()) }
    height?.let { metadata.putInt(MediaMetadata.KEY_HEIGHT, it.toInt()) }
    latitude?.let { metadata.putDouble(MediaMetadata.KEY_LOCATION_LATITUDE, it) }
    longitude?.let { metadata.putDouble(MediaMetadata.KEY_LOCATION_LONGITUDE, it) }
    iso8601ToCalendar(releaseDate)?.let { metadata.putDate(MediaMetadata.KEY_RELEASE_DATE, it) }
    // The TV show original air date is stored under the broadcast date key,
    // the closest canonical key exposed by the Android Cast SDK.
    iso8601ToCalendar(originalAirDate)?.let { metadata.putDate(MediaMetadata.KEY_BROADCAST_DATE, it) }
    iso8601ToCalendar(creationDateTime)?.let { metadata.putDate(MediaMetadata.KEY_CREATION_DATE, it) }

    images?.mapNotNull { it }?.forEach { image ->
        if (image.url.isNotBlank()) {
            val uri = Uri.parse(image.url)
            val width = image.width?.toInt()
            val height = image.height?.toInt()
            metadata.addImage(
                if (width != null && height != null) {
                    WebImage(uri, width, height)
                } else {
                    WebImage(uri)
                }
            )
        }
    }

    return metadata
}

/**
 * Parses an ISO-8601 date string (the representation produced by
 * `DateTime.toUtc().toIso8601String()` on the Dart side) into a [Calendar].
 *
 * A plain epoch-milliseconds string and the `yyyy-MM-dd` date only form are
 * also accepted for backwards compatibility with the legacy map based
 * payloads.
 */
private fun iso8601ToCalendar(value: String?): Calendar? {
    if (value.isNullOrBlank()) return null
    val trimmed = value.trim()
    trimmed.toLongOrNull()?.let { millis ->
        return Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { timeInMillis = millis }
    }
    // Fractional seconds beyond milliseconds are truncated so the
    // SimpleDateFormat patterns below can parse the value.
    val truncated = trimmed.replace(Regex("""(\.\d{3})\d+"""), "$1")
    val patterns = listOf(
        "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
        "yyyy-MM-dd'T'HH:mm:ss'Z'",
        "yyyy-MM-dd"
    )
    for (pattern in patterns) {
        try {
            val format = SimpleDateFormat(pattern, Locale.US)
            format.timeZone = TimeZone.getTimeZone("UTC")
            format.isLenient = false
            val date = format.parse(truncated) ?: continue
            return Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply { time = date }
        } catch (e: ParseException) {
            // Try the next pattern.
        }
    }
    CastDebugLog.w(TAG, "iso8601ToCalendar: unable to parse date '$value'")
    return null
}

fun MediaQueueItem.toCastMediaQueueItem(): CastMediaQueueItem? {
    val castMedia = media?.toCastMediaInfo()
    if (castMedia == null) {
        CastDebugLog.e(TAG, "[CONVERSION ERROR] toCastMediaQueueItem: media is null or invalid for itemId=$itemId")
        return null
    }
    CastDebugLog.d(TAG, "toCastMediaQueueItem: itemId=$itemId, startTime=$startTime, autoplay=$autoplay")
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

fun SeekOptionPigeon.toCastSeekOptions(currentStreamPositionMs: Long? = null): MediaSeekOptions {
    val resumeState = when (resumeState) {
        MediaResumeStatePigeon.PLAY -> 0
        MediaResumeStatePigeon.PAUSE -> 1
        MediaResumeStatePigeon.UNCHANGED -> 2
    }
    // The Android Cast SDK has no relative seek; resolve it against the
    // current stream position (clamped at 0) like the receiver would.
    val positionMs = if (relative && currentStreamPositionMs != null) {
        (currentStreamPositionMs + position * 1000).coerceAtLeast(0)
    } else {
        position * 1000
    }
    CastDebugLog.d(TAG, "toCastSeekOptions: position=${position}s, relative=$relative -> ${positionMs}ms, resumeState=$resumeState, seekToInfinity=$seekToInfinity")

    return MediaSeekOptions.Builder()
        .setPosition(positionMs)
        .setResumeState(resumeState)
        .setIsSeekToInfinite(seekToInfinity)
        .build()
}

fun TextTrackStylePigeon.toCastTextTrackStyle(): CastTextTrackStyle {
    val style = CastTextTrackStyle()
    backgroundColor?.let { style.backgroundColor = it.parseArgbHex() }
    foregroundColor?.let { style.foregroundColor = it.parseArgbHex() }
    edgeColor?.let { style.edgeColor = it.parseArgbHex() }
    windowColor?.let { style.windowColor = it.parseArgbHex() }
    fontFamily?.let { style.setFontFamily(it) }
    fontScale?.let { style.fontScale = it.toFloat() }
    windowRoundedCornerRadius?.let { style.windowCornerRadius = it.toInt() }
    fontGenericFamily?.let { name ->
        when (name) {
            "sansSerif" -> CastTextTrackStyle.FONT_FAMILY_SANS_SERIF
            "monospacedSansSerif" -> CastTextTrackStyle.FONT_FAMILY_MONOSPACED_SANS_SERIF
            "serif" -> CastTextTrackStyle.FONT_FAMILY_SERIF
            "monospacedSerif" -> CastTextTrackStyle.FONT_FAMILY_MONOSPACED_SERIF
            "casual" -> CastTextTrackStyle.FONT_FAMILY_CASUAL
            "cursive" -> CastTextTrackStyle.FONT_FAMILY_CURSIVE
            "smallCapitals" -> CastTextTrackStyle.FONT_FAMILY_SMALL_CAPITALS
            else -> null
        }?.let { style.fontGenericFamily = it }
    }
    fontStyle?.let { name ->
        when (name) {
            "normal" -> CastTextTrackStyle.FONT_STYLE_NORMAL
            "bold" -> CastTextTrackStyle.FONT_STYLE_BOLD
            "italic" -> CastTextTrackStyle.FONT_STYLE_ITALIC
            "boldItalic" -> CastTextTrackStyle.FONT_STYLE_BOLD_ITALIC
            else -> null
        }?.let { style.fontStyle = it }
    }
    windowType?.let { name ->
        when (name) {
            "none" -> CastTextTrackStyle.WINDOW_TYPE_NONE
            "normal" -> CastTextTrackStyle.WINDOW_TYPE_NORMAL
            "roundedCorners" -> CastTextTrackStyle.WINDOW_TYPE_ROUNDED
            else -> null
        }?.let { style.windowType = it }
    }
    customData?.let { style.setCustomData(it.toJsonObject()) }
    return style
}

/** Parses "#RRGGBBAA" / "#AARRGGBB" style hex into an ARGB int. */
private fun String.parseArgbHex(): Int =
    android.graphics.Color.parseColor(if (startsWith("#")) this else "#$this")

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
    CastDebugLog.d(TAG, "toCastMediaLoadRequestData: autoPlay=$autoPlay, playPosition=${playPosition}s, playbackRate=$playbackRate, hasCredentials=${credentials != null}")
    val builder = MediaLoadRequestData.Builder()
        .setMediaInfo(mediaInfo)
        .setAutoplay(autoPlay)
        .setCurrentTime(playPosition * 1000)
        .setPlaybackRate(playbackRate)

    customData?.let {
        CastDebugLog.d(TAG, "toCastMediaLoadRequestData: Setting customData")
        builder.setCustomData(it.toJsonObject())
    }
    activeTrackIds?.mapNotNull { it }?.toLongArray()?.let {
        CastDebugLog.d(TAG, "toCastMediaLoadRequestData: Setting activeTrackIds=${it.contentToString()}")
        builder.setActiveTrackIds(it)
    }
    credentials?.let {
        CastDebugLog.d(TAG, "toCastMediaLoadRequestData: Setting credentials (type=$credentialsType)")
        builder.setCredentials(it)
    }
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
    CastDebugLog.d(TAG, "toPigeonMediaInfo: contentId=$contentId, streamType=$stream, duration=$streamDuration")

    return MediaInfo(
        contentId = contentId ?: "",
        contentType = contentType ?: "",
        streamType = stream,
        contentUrl = contentUrl ?: "",
        // The pigeon contract reports the duration in seconds; the SDK
        // exposes it in milliseconds.
        duration = if (streamDuration > 0) streamDuration / 1000 else 0,
        customData = customData?.toMapRecursive(),
        tracks = mediaTracks?.map { it.toPigeonMediaTrack() },
        metadata = metadata?.toPigeonMetadata(),
        hlsSegmentFormat = GoogleCastMediaInfoExtensions.hlsSegmentFormatToName(hlsSegmentFormat),
        hlsVideoSegmentFormat = GoogleCastMediaInfoExtensions.hlsVideoSegmentFormatToName(
            hlsVideoSegmentFormat
        )
    )
}

fun MediaMetadata.toPigeonMetadata(): MediaMetadataPigeon {
    val images = images?.map { webImage: WebImage ->
        MediaImagePigeon(
            url = webImage.url?.toString() ?: "",
            width = if (webImage.width > 0) webImage.width.toLong() else null,
            height = if (webImage.height > 0) webImage.height.toLong() else null
        )
    }

    val title = getString(MediaMetadata.KEY_TITLE)
    val subtitle = getString(MediaMetadata.KEY_SUBTITLE)
    val studio = getString(MediaMetadata.KEY_STUDIO)
    val artist = getString(MediaMetadata.KEY_ARTIST)
    val albumName = getString(MediaMetadata.KEY_ALBUM_TITLE)
    val seriesTitle = getString(MediaMetadata.KEY_SERIES_TITLE)

    val season = if (containsKey(MediaMetadata.KEY_SEASON_NUMBER)) {
        getInt(MediaMetadata.KEY_SEASON_NUMBER)?.toLong()
    } else null

    val episode = if (containsKey(MediaMetadata.KEY_EPISODE_NUMBER)) {
        getInt(MediaMetadata.KEY_EPISODE_NUMBER)?.toLong()
    } else null

    // MediaMetadata.getDate() is declared to return a Date, but when the
    // metadata is deserialized from receiver JSON the underlying value can
    // actually be a Calendar (or String), which makes SimpleDateFormat.format
    // throw IllegalArgumentException. Widen to Any? and convert defensively.
    val rawDate: Any? = getDate(MediaMetadata.KEY_RELEASE_DATE)
    val releaseDate = when (rawDate) {
        null -> null
        is java.util.Date -> SimpleDateFormat("yyyy-MM-dd", Locale.US).format(rawDate)
        is java.util.Calendar -> SimpleDateFormat("yyyy-MM-dd", Locale.US).format(rawDate.time)
        is Number -> SimpleDateFormat("yyyy-MM-dd", Locale.US).format(java.util.Date(rawDate.toLong()))
        is String -> rawDate.takeIf { it.isNotBlank() }
        else -> null
    }

    return MediaMetadataPigeon(
        metadataType = mediaType.toLong(),
        title = title,
        subtitle = subtitle,
        studio = studio,
        artist = artist,
        albumName = albumName,
        seriesTitle = seriesTitle,
        season = season,
        episode = episode,
        releaseDate = releaseDate,
        images = images
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

    CastDebugLog.d(TAG, "toPigeonMediaStatus: playerState=$player, idleReason=$idle, repeatMode=$repeat, playbackRate=$playbackRate, currentItemId=$currentItemId")

    if (idleReason == CastMediaStatus.IDLE_REASON_ERROR) {
        CastDebugLog.e(TAG, "[MEDIA ERROR] MediaStatus has IDLE_REASON_ERROR - playback failed!")
        CastDebugLog.e(TAG, "[MEDIA ERROR] Player state: $player, idle reason: $idle")
        CastDebugLog.e(TAG, "[MEDIA ERROR] Media info: contentId=${mediaInfo?.contentId}, contentType=${mediaInfo?.contentType}")
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
