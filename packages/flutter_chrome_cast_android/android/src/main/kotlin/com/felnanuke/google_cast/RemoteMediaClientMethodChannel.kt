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
        loadMedia(
            mapOf(
                "mediaInfo" to request.mediaInfo.let { mediaInfoToMap(it) },
                "autoPlay" to request.autoPlay,
                "playPosition" to request.playPosition,
                "playbackRate" to request.playbackRate,
                "activeTrackIds" to request.activeTrackIds,
                "credentials" to request.credentials,
                "credentialsType" to request.credentialsType,
                "customData" to request.customData,
            )
        )
    }

    override fun queueLoadItems(request: QueueLoadRequestPigeon) {
        queueLoadItems(
            mapOf(
                "queueItems" to request.items.mapNotNull { it?.let { queueItemToMap(it) } },
                "options" to request.options?.let {
                    mapOf(
                        "startIndex" to it.startIndex,
                        "repeatMode" to when (it.repeatMode) {
                            RepeatModePigeon.OFF -> "OFF"
                            RepeatModePigeon.ALL -> "ALL"
                            RepeatModePigeon.SINGLE -> "SINGLE"
                            RepeatModePigeon.ALL_AND_SHUFFLE -> "ALL_AND_SHUFFLE"
                        },
                        "playPosition" to it.playPosition,
                        "customData" to it.customData,
                    )
                },
            )
        )
    }

    override fun queueInsertItems(request: QueueInsertItemsRequestPigeon) {
        queueInsertItems(
            mapOf(
                "items" to request.items.mapNotNull { it?.let { queueItemToMap(it) } },
                "beforeItemWithId" to request.beforeItemWithId?.toInt(),
            )
        )
    }

    override fun queueInsertItemAndPlay(request: QueueInsertItemAndPlayRequestPigeon) {
        queueInsertItemAndPlay(
            mapOf(
                "item" to queueItemToMap(request.item),
                "beforeItemWithId" to request.beforeItemWithId.toInt(),
            )
        )
    }

    override fun queueNextItem() = queueNextItemInternal()

    override fun queuePrevItem() = queuePrevItemInternal()

    override fun queueJumpToItemWithId(itemId: Long) = queueJumpToItemWithIdInternal(itemId.toInt())

    override fun queueRemoveItemsWithIds(itemIds: List<Long?>) {
        val ids = itemIds.mapNotNull { it?.toInt() }.toIntArray()
        queueRemoveItemsWithIdsInternal(ids)
    }

    override fun queueReorderItems(request: QueueReorderItemsRequestPigeon) {
        val ids = request.itemsIds.mapNotNull { it?.toInt() }.toIntArray()
        queueReorderItemsInternal(
            mapOf(
                "itemsIds" to ids,
                "beforeItemWithId" to request.beforeItemWithId?.toInt(),
            )
        )
    }

    override fun seek(request: SeekOptionPigeon) {
        seekInternal(
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
    }

    override fun setActiveTrackIds(trackIds: List<Long?>) {
        setActiveTrackIdsInternal(ArrayList(trackIds.mapNotNull { it }))
    }

    override fun setPlaybackRate(rate: Double) = setPlaybackRateInternal(rate)

    override fun setTextTrackStyle(textTrackStyle: TextTrackStylePigeon) = setTextTrackStyleInternal(textTrackStyle)

    override fun play() = playInternal()

    override fun pause() = pauseInternal()

    override fun stop() = stopInternal()

    private fun setTextTrackStyleInternal(style: TextTrackStylePigeon) {
        // TODO: apply text track style in native SDK using typed Pigeon model.
        // Kept as no-op to preserve previous behavior while removing map payloads.
    }

    private fun setPlaybackRateInternal(arguments: Any?) {
        val playbackRate = arguments as Double
        currentRemoteMediaClient?.setPlaybackRate(playbackRate)
    }

    private fun setActiveTrackIdsInternal(arguments: Any?) {
        arguments as ArrayList<Long>
        val longArray = arguments.map {
            it.toLong()
        }
        currentRemoteMediaClient?.setActiveMediaTracks(longArray.toLongArray())
            ?.addStatusListener { status ->
                if (status.isSuccess) {

                    Log.w(TAG, "setActiveTrackIds success $longArray")
                } else {
                    Log.w(TAG, "setActiveTrackIds failed $longArray")
                }

            }


    }

    private fun seekInternal(arguments: Any?) {
        arguments as Map<String, Any?>
        val options = GoogleCastSeekOptionsBuilder.fromMap(arguments)
        currentRemoteMediaClient?.seek(options)
    }

    private fun queueReorderItemsInternal(arguments: Any?) {
        arguments as Map<String, Any?>
        val itemIds = arguments["itemsIds"] as IntArray
        val beforeItemWithId =
            (arguments["beforeItemWithId"] as Int?) ?: MediaSession.QueueItem.UNKNOWN_ID
        currentRemoteMediaClient?.queueReorderItems(itemIds, beforeItemWithId, JSONObject())
    }

    private fun queueRemoveItemsWithIdsInternal(arguments: Any?) {
        arguments as IntArray
        currentRemoteMediaClient?.queueRemoveItems(arguments, JSONObject())
    }

    private fun queueJumpToItemWithIdInternal(itemId: Int) {
        currentRemoteMediaClient?.queueJumpToItem(itemId, JSONObject())

    }

    private fun queuePrevItemInternal() {
        currentRemoteMediaClient?.queuePrev(JSONObject())
    }

    private fun queueNextItemInternal() {
        currentRemoteMediaClient?.queueNext(JSONObject())
    }

    private fun queueInsertItemAndPlay(arguments: Map<String, Any?>) {
        val item =
            GoogleCastQueueItemBuilder.fromMap(arguments["item"] as Map<String, Any?>) ?: return
        val beforeItemWithId = arguments["beforeItemWithId"] as Int
        var jsonObject = JSONObject()
        currentRemoteMediaClient?.queueInsertAndPlayItem(item, beforeItemWithId, jsonObject)

    }

    private fun queueInsertItems(arguments: Map<String, Any?>) {
        val items =
            GoogleCastQueueItemBuilder.listFromMap(arguments["items"] as List<Map<String, Any?>>)
        val beforeItemWithId =
            (arguments["beforeItemWithId"] as Int?) ?: MediaSession.QueueItem.UNKNOWN_ID
        var jsonObject = JSONObject()
        currentRemoteMediaClient?.queueInsertItems(
            items.toTypedArray(),
            beforeItemWithId,
            jsonObject
        )

    }

    private fun pauseInternal() {
        currentRemoteMediaClient?.pause()
    }

    private fun playInternal() {
        currentRemoteMediaClient?.play()

    }

    private fun stopInternal() {
        currentRemoteMediaClient?.stop()
    }

    private fun queueLoadItems(arguments: Map<String, Any?>) {
        val queueItemsData = arguments["queueItems"] as List<Map<String, Any?>>
        val optionsData = arguments["options"] as? Map<String, Any?> ?: emptyMap()
        val startIndex = (optionsData["startIndex"] as? Number)?.toInt() ?: 0
        val repeatMode = optionsData["repeatMode"] as String?
        val playPosition = (optionsData["playPosition"] as? Number)?.toLong() ?: 0L
        val queueCustomData = optionsData["customData"] as? Map<*, *>
        val queueCustomDataJson = if (queueCustomData != null) {
            mapToJsonObject(queueCustomData)
        } else {
            JSONObject()
        }
        val queueItems = GoogleCastQueueItemBuilder.listFromMap(queueItemsData)
        currentRemoteMediaClient?.queueLoad(
            queueItems.toTypedArray(),
            startIndex,
            when (repeatMode) {
                "OFF" -> REPEAT_MODE_REPEAT_OFF
                "ALL" -> REPEAT_MODE_REPEAT_ALL
                "SINGLE" -> REPEAT_MODE_REPEAT_SINGLE
                "ALL_AND_SHUFFLE" -> REPEAT_MODE_REPEAT_ALL_AND_SHUFFLE
                else -> REPEAT_MODE_REPEAT_OFF
            },
            playPosition * 1000,
            queueCustomDataJson
        )
    }

    private fun loadMedia(arguments: Map<String, Any?>) {
        val mediaInfo =
            GoogleCastMediaInfo.fromMap(arguments["mediaInfo"] as Map<String, Any?>) ?: return
        val customData = arguments["customData"] as? Map<*, *>
        val requestData = buildMediaLoadRequestData(mediaInfo, arguments, customData)
        currentRemoteMediaClient?.load(requestData)
    }

    private fun buildMediaLoadRequestData(
        mediaInfo: com.google.android.gms.cast.MediaInfo,
        arguments: Map<String, Any?>,
        customData: Map<*, *>?
    ): com.google.android.gms.cast.MediaLoadRequestData {
        val autoPlay = arguments["autoPlay"] as? Boolean ?: true
        val playPosition = arguments["playPosition"] as? Int ?: 0
        val activeTrackIds = (arguments["activeTrackIds"] as? ArrayList<Number>)?.map { it.toLong() }?.toLongArray()
        val credentials = arguments["credentials"] as? String
        val credentialsType = arguments["credentialsType"] as? String
        val playbackRate = arguments["playbackRate"] as? Double ?: 1.0

        val requestDataBuilder = com.google.android.gms.cast.MediaLoadRequestData.Builder()
            .setMediaInfo(mediaInfo)
            .setAutoplay(autoPlay)
            .setCurrentTime((playPosition * 1000).toLong())
            .setPlaybackRate(playbackRate)

        if (customData != null) {
            requestDataBuilder.setCustomData(mapToJsonObject(customData))
        }

        if (activeTrackIds != null) {
            requestDataBuilder.setActiveTrackIds(activeTrackIds)
        }

        if (credentials != null) {
            requestDataBuilder.setCredentials(credentials)
        }

        if (credentialsType != null) {
            requestDataBuilder.setCredentialsType(credentialsType)
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
