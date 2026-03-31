package com.felnanuke.google_cast

import android.media.session.MediaSession
import android.util.Log
import com.felnanuke.google_cast.extensions.*
import com.felnanuke.google_cast.pigeon.*
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_ALL
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_OFF
import com.google.android.gms.cast.MediaStatus.REPEAT_MODE_REPEAT_SINGLE
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.json.JSONObject

/**
 * Tag for logging remote media client operations
 */
private const val TAG = "RemoteMediaClient"

/**
 * Flutter method channel for Google Cast remote media client operations
 *
 * This class manages all media-related operations for Google Cast sessions, providing
 * comprehensive control over media playback, queue management, and media status monitoring.
 * It implements Google Cast remote media client callback interfaces to receive media
 * events and progress updates, communicating these changes to Flutter in real-time.
 *
 * Key responsibilities:
 * - Media loading and queue management operations
 * - Playback controls (play, pause, stop, seek)
 * - Volume and audio track management
 * - Media progress and status monitoring
 * - Queue operations (insert, remove, reorder items)
 * - Text track and subtitle controls
 * - Real-time media updates to Flutter
 *
 * Architecture:
 * The class integrates with Google Cast SDK media components:
 * - RemoteMediaClient: Core Cast SDK media control interface
 * - RemoteMediaClient.Callback: Receives media status change events
 * - RemoteMediaClient.ProgressListener: Monitors media playback progress
 * - Media queue management for playlist functionality
 * - Automatic progress tracking during media playback
 *
 * Media Operations:
 * 1. Media loading with metadata and options
 * 2. Queue management for playlist functionality
 * 3. Playback control and seeking operations
 * 4. Track selection and subtitle management
 * 5. Progress monitoring and status updates
 * 6. Event propagation to Flutter for UI updates
 *
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class RemoteMediaClientMethodChannel : FlutterPlugin, RemoteMediaClientHostApi,
    RemoteMediaClient.Callback(), RemoteMediaClient.ProgressListener {

    /**
     * Pigeon Flutter API for sending media events to Flutter layer
     */
    private lateinit var flutterApi: RemoteMediaClientFlutterApi

    /**
     * Current remote media client instance for the active Cast session
     *
     * Provides access to the media client for the current Cast session.
     * Returns null if no Cast session is active or no media client is available.
     *
     * @return The current remote media client, or null if not available
     */
    private val currentRemoteMediaClient: RemoteMediaClient?
        get() =
            CastContext.getSharedInstance()?.sessionManager?.currentCastSession?.remoteMediaClient

    // MARK: - Flutter Plugin Lifecycle


    /**
     * Called when the Flutter plugin is attached to the Flutter engine
     *
     * Initializes the remote media client method channel for media operations.
     *
     * Setup operations:
     * - Creates the remote media client method channel
     * - Registers this class as the method call handler
     * - Prepares media control infrastructure
     *
     * @param binding Flutter plugin binding providing access to engine resources
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        RemoteMediaClientHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = RemoteMediaClientFlutterApi(binding.binaryMessenger)
    }

    /**
     * Called when the Flutter plugin is detached from the Flutter engine
     *
     * Performs cleanup of remote media client resources to prevent memory leaks.
     *
     * Cleanup operations:
     * - Removes method call handler from the channel
     * - Stops media monitoring
     * - Releases media-related resources
     *
     * @param binding Flutter plugin binding being detached
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        RemoteMediaClientHostApi.setUp(binding.binaryMessenger, null)
        // Clean up media client listeners to prevent memory leaks
        endListen()
    }

    override fun loadMedia(request: LoadMediaRequestPigeon) {
        val mediaInfo = GoogleCastMediaInfo.fromMap(mediaInfoToMap(request.mediaInfo)) ?: return
        val requestData = buildMediaLoadRequestData(mediaInfo, request)
        currentRemoteMediaClient?.load(requestData)
    }

    override fun queueLoadItems(request: QueueLoadRequestPigeon) {
        val queueItems = request.items.mapNotNull { item ->
            item?.let { GoogleCastQueueItemBuilder.fromMap(queueItemToMap(it)) }
        }
        val options = request.options
        val startIndex = options?.startIndex ?: 0
        val playPosition = options?.playPosition ?: 0L
        val queueCustomDataJson = options?.customData?.let { mapToJsonObject(it) } ?: JSONObject()

        currentRemoteMediaClient?.queueLoad(
            queueItems.toTypedArray(),
            startIndex,
            repeatModeToCast(request.options?.repeatMode),
            playPosition * 1000,
            queueCustomDataJson
        )
    }

    override fun queueInsertItems(request: QueueInsertItemsRequestPigeon) {
        val items = request.items.mapNotNull { item ->
            item?.let { GoogleCastQueueItemBuilder.fromMap(queueItemToMap(it)) }
        }
        val beforeItemWithId = request.beforeItemWithId?.toInt() ?: MediaSession.QueueItem.UNKNOWN_ID
        currentRemoteMediaClient?.queueInsertItems(items.toTypedArray(), beforeItemWithId, JSONObject())
    }

    override fun queueInsertItemAndPlay(request: QueueInsertItemAndPlayRequestPigeon) {
        val item = GoogleCastQueueItemBuilder.fromMap(queueItemToMap(request.item)) ?: return
        currentRemoteMediaClient?.queueInsertAndPlayItem(item, request.beforeItemWithId.toInt(), JSONObject())
    }

    override fun queueNextItem() {
        currentRemoteMediaClient?.queueNext(JSONObject())
    }

    override fun queuePrevItem() {
        currentRemoteMediaClient?.queuePrev(JSONObject())
    }

    override fun queueJumpToItemWithId(itemId: Long) {
        currentRemoteMediaClient?.queueJumpToItem(itemId.toInt(), JSONObject())
    }

    override fun queueRemoveItemsWithIds(itemIds: List<Long?>) {
        val ids = itemIds.mapNotNull { it?.toInt() }.toIntArray()
        currentRemoteMediaClient?.queueRemoveItems(ids, JSONObject())
    }

    override fun queueReorderItems(request: QueueReorderItemsRequestPigeon) {
        val itemIds = request.itemsIds.mapNotNull { it?.toInt() }.toIntArray()
        val beforeItemWithId =
            request.beforeItemWithId?.toInt() ?: MediaSession.QueueItem.UNKNOWN_ID
        currentRemoteMediaClient?.queueReorderItems(itemIds, beforeItemWithId, JSONObject())
    }

    override fun seek(request: SeekOptionPigeon) {
        val options = GoogleCastSeekOptionsBuilder.fromMap(
            mapOf(
                "position" to request.position,
                "relative" to request.relative,
                "resumeState" to when (request.resumeState) {
                    MediaResumeStatePigeon.PLAY -> 0
                    MediaResumeStatePigeon.PAUSE -> 1
                    MediaResumeStatePigeon.UNCHANGED -> 2
                },
                "seekToInfinity" to request.seekToInfinity,
            )
        )
        currentRemoteMediaClient?.seek(options)
    }

    override fun setActiveTrackIds(trackIds: List<Long?>) {
        val castTrackIds = trackIds.mapNotNull { it }.toLongArray()
        currentRemoteMediaClient?.setActiveMediaTracks(castTrackIds)
            ?.addStatusListener { status ->
                if (status.isSuccess) {
                    Log.w(TAG, "setActiveTrackIds success ${castTrackIds.contentToString()}")
                } else {
                    Log.w(TAG, "setActiveTrackIds failed ${castTrackIds.contentToString()}")
                }
            }
    }

    override fun setPlaybackRate(request: SetPlaybackRateRequestPigeon) {
        currentRemoteMediaClient?.setPlaybackRate(request.rate)
    }

    override fun setTextTrackStyle(textTrackStyle: TextTrackStylePigeon) {
        setTextTrackStyleInternal(textTrackStyle)
    }

    override fun play() {
        currentRemoteMediaClient?.play()
    }

    override fun pause() {
        currentRemoteMediaClient?.pause()
    }

    override fun stop() {
        currentRemoteMediaClient?.stop()
    }

    private fun setTextTrackStyleInternal(style: TextTrackStylePigeon) {
        // TODO: apply text track style in native SDK using typed Pigeon model.
        // Kept as no-op to preserve previous behavior while removing map payloads.
    }

    private fun repeatModeToCast(repeatMode: RepeatModePigeon?): Int {
        return when (repeatMode) {
            RepeatModePigeon.ALL -> REPEAT_MODE_REPEAT_ALL
            RepeatModePigeon.SINGLE -> REPEAT_MODE_REPEAT_SINGLE
            RepeatModePigeon.ALL_AND_SHUFFLE -> REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE
            RepeatModePigeon.OFF, null -> REPEAT_MODE_REPEAT_OFF
        }
    }

    private fun buildMediaLoadRequestData(
        mediaInfo: com.google.android.gms.cast.MediaInfo,
        request: LoadMediaRequestPigeon
    ): com.google.android.gms.cast.MediaLoadRequestData {
        val activeTrackIds = request.activeTrackIds?.mapNotNull { it }?.toLongArray()

        val requestDataBuilder = com.google.android.gms.cast.MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .setAutoplay(request.autoPlay ?: true)
            .setCurrentTime(request.playPosition.toLong() * 1000)
            .setPlaybackRate(request.playbackRate ?: 1.0)

        if (request.customData != null) {
            requestDataBuilder.setCustomData(mapToJsonObject(request.customData))
        }

        if (activeTrackIds != null) {
            requestDataBuilder.setActiveTrackIds(activeTrackIds)
        }

        if (request.credentials != null) {
            requestDataBuilder.setCredentials(request.credentials)
        }

        if (request.credentialsType != null) {
            requestDataBuilder.setCredentialsType(request.credentialsType)
        }

        return requestDataBuilder.build()
    }



    override fun onStatusUpdated() {
        super.onStatusUpdated()
        val mediaStatus = currentRemoteMediaClient?.mediaStatus
        val pigeonStatus = mediaStatus?.let { toMediaStatusPigeon(it) }
        Log.w(TAG, "onStatusUpdated hasStatus=${pigeonStatus != null}")
        flutterApi.onMediaStatusChanged(pigeonStatus) { }
    }

    override fun onQueueStatusUpdated() {
        super.onQueueStatusUpdated()
        val queueItems = currentRemoteMediaClient?.mediaStatus?.queueItems?.map { toMediaQueueItemPigeon(it) } ?: emptyList()
        flutterApi.onQueueStatusChanged(queueItems) { }
    }

    override fun onProgressUpdated(progress: Long, duration: Long) {
        val update = PlayerPositionUpdate(progress, duration)
        flutterApi.onPlayerPositionChanged(update) { }
    }

    // MARK: - Pigeon Model Conversion

    private fun toMediaStatusPigeon(status: com.google.android.gms.cast.MediaStatus): MediaStatus {
        val playerState = when (status.playerState) {
            com.google.android.gms.cast.MediaStatus.PLAYER_STATE_PLAYING -> "PLAYING"
            com.google.android.gms.cast.MediaStatus.PLAYER_STATE_PAUSED -> "PAUSED"
            com.google.android.gms.cast.MediaStatus.PLAYER_STATE_BUFFERING -> "BUFFERING"
            com.google.android.gms.cast.MediaStatus.PLAYER_STATE_IDLE -> "IDLE"
            else -> "UNKNOWN"
        }

        val idleReason = when (status.idleReason) {
            com.google.android.gms.cast.MediaStatus.IDLE_REASON_FINISHED -> "FINISHED"
            com.google.android.gms.cast.MediaStatus.IDLE_REASON_CANCELED -> "CANCELED"
            com.google.android.gms.cast.MediaStatus.IDLE_REASON_INTERRUPTED -> "INTERRUPTED"
            com.google.android.gms.cast.MediaStatus.IDLE_REASON_ERROR -> "ERROR"
            else -> "NONE"
        }

        val liveSeekableRange = status.liveSeekableRange?.let {
            LiveSeekableRange(
                start = it.startTime,
                end = it.endTime,
                isMovingWindow = it.isMovingWindow,
                isLiveDone = it.isLiveDone
            )
        }

        return MediaStatus(
            mediaSessionId = status.toJson().optLong("mediaSessionId"),
            playerState = playerState,
            idleReason = idleReason,
            playbackRate = status.playbackRate,
            media = status.mediaInfo?.let { toMediaInfoPigeon(it) },
            volume = Volume(
                level = status.streamVolume.toDouble(),
                muted = status.isMute
            ),
            repeatMode = when (status.queueRepeatMode) {
                REPEAT_MODE_REPEAT_ALL -> "ALL"
                REPEAT_MODE_REPEAT_SINGLE -> "SINGLE"
                REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE -> "ALL_AND_SHUFFLE"
                else -> "OFF"
            },
            currentItemId = status.currentItemId.toLong(),
            activeTrackIds = status.activeTrackIds?.map { it.toLong() },
            liveSeekableRange = liveSeekableRange
        )
    }

    private fun toMediaInfoPigeon(mediaInfo: com.google.android.gms.cast.MediaInfo): MediaInfo {
        val streamType = when (mediaInfo.streamType) {
            com.google.android.gms.cast.MediaInfo.STREAM_TYPE_BUFFERED -> "BUFFERED"
            com.google.android.gms.cast.MediaInfo.STREAM_TYPE_LIVE -> "LIVE"
            com.google.android.gms.cast.MediaInfo.STREAM_TYPE_NONE -> "NONE"
            else -> "NONE"
        }

        return MediaInfo(
            contentId = mediaInfo.contentId ?: "",
            contentType = mediaInfo.contentType ?: "",
            streamType = streamType,
            contentUrl = mediaInfo.contentUrl ?: "",
            duration = mediaInfo.streamDuration,
            customData = mediaInfo.customData?.let { jsonObjectToMap(it) },
            tracks = mediaInfo.mediaTracks?.map { track ->
                MediaTrack(
                    trackId = track.id.toLong(),
                    type = track.type.toLong(),
                    trackContentId = track.contentId ?: "",
                    trackContentType = track.contentType ?: "",
                    subtype = track.subtype.toLong(),
                    name = track.name ?: "",
                    language = track.language ?: ""
                )
            }
        )
    }

    private fun toMediaQueueItemPigeon(item: com.google.android.gms.cast.MediaQueueItem): MediaQueueItem {
        return MediaQueueItem(
            itemId = item.itemId.toLong(),
            preLoadTime = item.preloadTime.toLong(),
            startTime = item.startTime.toLong(),
            playbackDuration = item.playbackDuration.toLong(),
            media = item.media?.let { toMediaInfoPigeon(it) },
            autoplay = item.autoplay,
            activeTrackIds = item.activeTrackIds?.map { it.toLong() },
            customData = item.customData?.let { jsonObjectToMap(it) }
        )
    }

    private fun jsonObjectToMap(jsonObject: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        val keys = jsonObject.keys()
        while (keys.hasNext()) {
            val key = keys.next()
            val value = jsonObject.opt(key)
            map[key] = when (value) {
                JSONObject.NULL -> null
                is JSONObject -> jsonObjectToMap(value)
                else -> value
            }
        }
        return map
    }

    /** Recursively converts a Flutter/codec map to a JSONObject, preserving value types. */
    private fun mapToJsonObject(map: Map<*, *>): JSONObject {
        val json = JSONObject()
        map.forEach { (key, value) ->
            if (key != null) {
                json.put(key.toString(), toJsonValue(value))
            }
        }
        return json
    }

    /** Recursively converts a Flutter/codec list to a JSONArray, preserving value types. */
    private fun listToJsonArray(list: List<*>): org.json.JSONArray {
        val arr = org.json.JSONArray()
        list.forEach { arr.put(toJsonValue(it)) }
        return arr
    }

    private fun toJsonValue(value: Any?): Any? {
        return when (value) {
            null -> JSONObject.NULL
            is Map<*, *> -> mapToJsonObject(value)
            is List<*> -> listToJsonArray(value)
            else -> value
        }
    }

    fun startListen() {
        currentRemoteMediaClient?.registerCallback(this)
        currentRemoteMediaClient?.addProgressListener(this, 500)
    }

    fun endListen() {
        currentRemoteMediaClient?.removeProgressListener(this)
        currentRemoteMediaClient?.unregisterCallback(this)
    }

    private fun mediaInfoToMap(mediaInfo: MediaInfo): Map<String, Any?> {
        return mapOf(
            "contentId" to mediaInfo.contentId,
            "contentType" to mediaInfo.contentType,
            "streamType" to mediaInfo.streamType,
            "contentUrl" to mediaInfo.contentUrl,
            "duration" to mediaInfo.duration,
            "customData" to mediaInfo.customData,
            "tracks" to mediaInfo.tracks?.mapNotNull { track ->
                track?.let {
                    mapOf(
                        "trackId" to it.trackId,
                        "type" to it.type,
                        "trackContentId" to it.trackContentId,
                        "trackContentType" to it.trackContentType,
                        "subtype" to it.subtype,
                        "name" to it.name,
                        "language" to it.language,
                    )
                }
            },
        )
    }

    private fun queueItemToMap(item: MediaQueueItem): Map<String, Any?> {
        return mapOf(
            "itemId" to item.itemId.toInt(),
            "preLoadTime" to item.preLoadTime.toInt(),
            "startTime" to item.startTime.toInt(),
            "playbackDuration" to item.playbackDuration.toInt(),
            "media" to item.media?.let { mediaInfoToMap(it) },
            "autoplay" to item.autoplay,
            "activeTrackIds" to item.activeTrackIds,
            "customData" to item.customData,
        )
    }
}
