package com.felnanuke.google_cast

import android.media.session.MediaSession
import android.util.Log
import com.felnanuke.google_cast.extensions.*
import com.felnanuke.google_cast.pigeon.*
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import org.json.JSONObject

private const val TAG = "RemoteMediaClient"

class RemoteMediaClientMethodChannel : FlutterPlugin, RemoteMediaClientHostApi,
    RemoteMediaClient.Callback(), RemoteMediaClient.ProgressListener {

    private lateinit var flutterApi: RemoteMediaClientFlutterApi

    private val currentRemoteMediaClient: RemoteMediaClient?
        get() =
            CastContext.getSharedInstance()?.sessionManager?.currentCastSession?.remoteMediaClient

    // MARK: - Flutter Plugin Lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onAttachedToEngine: Initializing RemoteMediaClient method channel")
        RemoteMediaClientHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = RemoteMediaClientFlutterApi(binding.binaryMessenger)
        CastDebugLog.d(TAG, "onAttachedToEngine: RemoteMediaClient ready")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onDetachedFromEngine: Cleaning up RemoteMediaClient")
        RemoteMediaClientHostApi.setUp(binding.binaryMessenger, null)
        endListen()
        CastDebugLog.d(TAG, "onDetachedFromEngine: RemoteMediaClient cleaned up, listeners removed")
    }

    override fun loadMedia(request: LoadMediaRequestPigeon) {
        CastDebugLog.mediaEvent(TAG, "loadMedia START", mapOf(
            "contentId" to request.mediaInfo.contentId,
            "contentType" to request.mediaInfo.contentType,
            "contentUrl" to request.mediaInfo.contentUrl,
            "streamType" to request.mediaInfo.streamType,
            "autoPlay" to request.autoPlay,
            "playPosition" to request.playPosition,
            "playbackRate" to request.playbackRate,
            "hasCredentials" to (request.credentials != null),
            "hasActiveTrackIds" to (request.activeTrackIds != null)
        ))

        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] loadMedia: RemoteMediaClient is NULL - no active Cast session or session has no media client")
            CastDebugLog.e(TAG, "[MEDIA ERROR] loadMedia: Ensure a Cast session is active and connected before loading media")
            return
        }

        val mediaInfo = request.mediaInfo.toCastMediaInfo()
        if (mediaInfo == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] loadMedia: Failed to convert MediaInfo - contentId is blank or invalid")
            CastDebugLog.e(TAG, "[MEDIA ERROR] loadMedia: contentId='${request.mediaInfo.contentId}' - must not be empty")
            return
        }

        try {
            val loadData = request.toCastMediaLoadRequestData(mediaInfo)
            CastDebugLog.d(TAG, "loadMedia: Calling RemoteMediaClient.load() with mediaInfo contentId=${mediaInfo.contentId}")
            client.load(loadData)
            CastDebugLog.castResult(TAG, "loadMedia", true, "contentId=${mediaInfo.contentId}")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "loadMedia(contentId=${request.mediaInfo.contentId})", e)
        }
    }

    override fun queueLoadItems(request: QueueLoadRequestPigeon) {
        CastDebugLog.mediaEvent(TAG, "queueLoadItems START", mapOf(
            "itemCount" to request.items.size,
            "startIndex" to request.options?.startIndex,
            "playPosition" to request.options?.playPosition,
            "repeatMode" to request.options?.repeatMode
        ))

        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueLoadItems: RemoteMediaClient is NULL")
            return
        }

        val queueItems = request.items.mapNotNull { item ->
            item?.toCastMediaQueueItem()
        }
        CastDebugLog.d(TAG, "queueLoadItems: Converted ${queueItems.size}/${request.items.size} items to CastMediaQueueItem")

        val options = request.options
        val startIndex = options?.startIndex?.toInt() ?: 0
        val playPosition = options?.playPosition ?: 0L
        val queueCustomDataJson = options.toQueueCustomDataJson()

        try {
            client.queueLoad(
                queueItems.toTypedArray(),
                startIndex,
                request.options?.repeatMode.toCastRepeatMode(),
                playPosition * 1000,
                queueCustomDataJson
            )
            CastDebugLog.castResult(TAG, "queueLoadItems", true, "itemCount=${queueItems.size}, startIndex=$startIndex")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueLoadItems(itemCount=${queueItems.size})", e)
        }
    }

    override fun queueInsertItems(request: QueueInsertItemsRequestPigeon) {
        CastDebugLog.mediaEvent(TAG, "queueInsertItems", mapOf(
            "itemCount" to request.items.size,
            "beforeItemWithId" to request.beforeItemWithId
        ))

        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueInsertItems: RemoteMediaClient is NULL")
            return
        }

        val items = request.items.mapNotNull { item ->
            item?.toCastMediaQueueItem()
        }
        val beforeItemWithId = request.beforeItemWithId?.toInt() ?: MediaSession.QueueItem.UNKNOWN_ID

        try {
            client.queueInsertItems(items.toTypedArray(), beforeItemWithId, JSONObject())
            CastDebugLog.castResult(TAG, "queueInsertItems", true, "insertedCount=${items.size}")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueInsertItems(itemCount=${items.size})", e)
        }
    }

    override fun queueInsertItemAndPlay(request: QueueInsertItemAndPlayRequestPigeon) {
        CastDebugLog.mediaEvent(TAG, "queueInsertItemAndPlay", mapOf(
            "itemId" to request.item.itemId,
            "beforeItemWithId" to request.beforeItemWithId
        ))

        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueInsertItemAndPlay: RemoteMediaClient is NULL")
            return
        }

        val item = request.item.toCastMediaQueueItem()
        if (item == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueInsertItemAndPlay: Failed to convert queue item - media info is null")
            return
        }

        try {
            client.queueInsertAndPlayItem(item, request.beforeItemWithId.toInt(), JSONObject())
            CastDebugLog.castResult(TAG, "queueInsertItemAndPlay", true, "itemId=${request.item.itemId}")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueInsertItemAndPlay(itemId=${request.item.itemId})", e)
        }
    }

    override fun queueNextItem() {
        CastDebugLog.mediaEvent(TAG, "queueNextItem")
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueNextItem: RemoteMediaClient is NULL")
            return
        }
        try {
            client.queueNext(JSONObject())
            CastDebugLog.castResult(TAG, "queueNextItem", true)
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueNextItem", e)
        }
    }

    override fun queuePrevItem() {
        CastDebugLog.mediaEvent(TAG, "queuePrevItem")
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queuePrevItem: RemoteMediaClient is NULL")
            return
        }
        try {
            client.queuePrev(JSONObject())
            CastDebugLog.castResult(TAG, "queuePrevItem", true)
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queuePrevItem", e)
        }
    }

    override fun queueJumpToItemWithId(itemId: Long) {
        CastDebugLog.mediaEvent(TAG, "queueJumpToItemWithId", mapOf("itemId" to itemId))
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueJumpToItemWithId: RemoteMediaClient is NULL")
            return
        }
        try {
            client.queueJumpToItem(itemId.toInt(), JSONObject())
            CastDebugLog.castResult(TAG, "queueJumpToItemWithId", true, "itemId=$itemId")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueJumpToItemWithId(itemId=$itemId)", e)
        }
    }

    override fun queueRemoveItemsWithIds(itemIds: List<Long?>) {
        CastDebugLog.mediaEvent(TAG, "queueRemoveItemsWithIds", mapOf("itemIds" to itemIds))
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueRemoveItemsWithIds: RemoteMediaClient is NULL")
            return
        }
        val ids = itemIds.mapNotNull { it?.toInt() }.toIntArray()
        try {
            client.queueRemoveItems(ids, JSONObject())
            CastDebugLog.castResult(TAG, "queueRemoveItemsWithIds", true, "removedCount=${ids.size}")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueRemoveItemsWithIds(ids=${ids.contentToString()})", e)
        }
    }

    override fun queueReorderItems(request: QueueReorderItemsRequestPigeon) {
        CastDebugLog.mediaEvent(TAG, "queueReorderItems", mapOf(
            "itemsIds" to request.itemsIds,
            "beforeItemWithId" to request.beforeItemWithId
        ))
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] queueReorderItems: RemoteMediaClient is NULL")
            return
        }
        val itemIds = request.itemsIds.mapNotNull { it?.toInt() }.toIntArray()
        val beforeItemWithId =
            request.beforeItemWithId?.toInt() ?: MediaSession.QueueItem.UNKNOWN_ID
        try {
            client.queueReorderItems(itemIds, beforeItemWithId, JSONObject())
            CastDebugLog.castResult(TAG, "queueReorderItems", true, "reorderedCount=${itemIds.size}")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "queueReorderItems(itemIds=${itemIds.contentToString()})", e)
        }
    }

    override fun seek(request: SeekOptionPigeon) {
        CastDebugLog.mediaEvent(TAG, "seek", mapOf(
            "position" to request.position,
            "resumeState" to request.resumeState,
            "seekToInfinity" to request.seekToInfinity
        ))
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] seek: RemoteMediaClient is NULL")
            return
        }
        try {
            client.seek(request.toCastSeekOptions())
            CastDebugLog.castResult(TAG, "seek", true, "position=${request.position}s")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "seek(position=${request.position})", e)
        }
    }

    override fun setActiveTrackIds(trackIds: List<Long?>) {
        val castTrackIds = trackIds.mapNotNull { it }.toLongArray()
        CastDebugLog.mediaEvent(TAG, "setActiveTrackIds", mapOf(
            "trackIds" to castTrackIds.contentToString()
        ))
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] setActiveTrackIds: RemoteMediaClient is NULL")
            return
        }
        client.setActiveMediaTracks(castTrackIds)
            ?.addStatusListener { status ->
                if (status.isSuccess) {
                    CastDebugLog.castResult(TAG, "setActiveTrackIds", true, "trackIds=${castTrackIds.contentToString()}")
                } else {
                    CastDebugLog.e(TAG, "[MEDIA ERROR] setActiveTrackIds FAILED: statusCode=${status.statusCode}, trackIds=${castTrackIds.contentToString()}")
                    CastDebugLog.e(TAG, "[MEDIA ERROR] setActiveTrackIds: Status message: ${status.statusMessage ?: "No message"}")
                    CastDebugLog.castResult(TAG, "setActiveTrackIds", false, "statusCode=${status.statusCode}, message=${status.statusMessage}")
                }
            } ?: run {
                CastDebugLog.w(TAG, "setActiveTrackIds: setActiveMediaTracks returned null - no result pending")
            }
    }

    override fun setPlaybackRate(request: SetPlaybackRateRequestPigeon) {
        CastDebugLog.mediaEvent(TAG, "setPlaybackRate", mapOf("rate" to request.rate))
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] setPlaybackRate: RemoteMediaClient is NULL")
            return
        }
        try {
            client.setPlaybackRate(request.rate)
            CastDebugLog.castResult(TAG, "setPlaybackRate", true, "rate=${request.rate}")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "setPlaybackRate(rate=${request.rate})", e)
        }
    }

    override fun setTextTrackStyle(textTrackStyle: TextTrackStylePigeon) {
        CastDebugLog.mediaEvent(TAG, "setTextTrackStyle", mapOf(
            "fontFamily" to textTrackStyle.fontFamily,
            "fontScale" to textTrackStyle.fontScale,
            "foregroundColor" to textTrackStyle.foregroundColor,
            "backgroundColor" to textTrackStyle.backgroundColor
        ))
        setTextTrackStyleInternal(textTrackStyle)
    }

    override fun play() {
        CastDebugLog.mediaEvent(TAG, "play")
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] play: RemoteMediaClient is NULL")
            return
        }
        try {
            client.play()
            CastDebugLog.castResult(TAG, "play", true)
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "play", e)
        }
    }

    override fun pause() {
        CastDebugLog.mediaEvent(TAG, "pause")
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] pause: RemoteMediaClient is NULL")
            return
        }
        try {
            client.pause()
            CastDebugLog.castResult(TAG, "pause", true)
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "pause", e)
        }
    }

    override fun stop() {
        CastDebugLog.mediaEvent(TAG, "stop")
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] stop: RemoteMediaClient is NULL")
            return
        }
        try {
            client.stop()
            CastDebugLog.castResult(TAG, "stop", true)
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "stop", e)
        }
    }

    private fun setTextTrackStyleInternal(style: TextTrackStylePigeon) {
        CastDebugLog.w(TAG, "setTextTrackStyleInternal: Text track style is currently a no-op (not implemented)")
    }

    override fun onStatusUpdated() {
        super.onStatusUpdated()
        val mediaStatus = currentRemoteMediaClient?.mediaStatus
        val pigeonStatus = mediaStatus?.toPigeonMediaStatus()
        CastDebugLog.mediaEvent(TAG, "onStatusUpdated", mapOf(
            "hasStatus" to (pigeonStatus != null),
            "playerState" to pigeonStatus?.playerState,
            "idleReason" to pigeonStatus?.idleReason,
            "playbackRate" to pigeonStatus?.playbackRate,
            "currentItemId" to pigeonStatus?.currentItemId,
            "repeatMode" to pigeonStatus?.repeatMode
        ))
        flutterApi.onMediaStatusChanged(pigeonStatus) { }
    }

    override fun onQueueStatusUpdated() {
        super.onQueueStatusUpdated()
        val queueItems = currentRemoteMediaClient?.mediaStatus?.queueItems?.map { it.toPigeonMediaQueueItem() } ?: emptyList()
        CastDebugLog.mediaEvent(TAG, "onQueueStatusUpdated", mapOf(
            "queueItemCount" to queueItems.size
        ))
        flutterApi.onQueueStatusChanged(queueItems) { }
    }

    override fun onProgressUpdated(progress: Long, duration: Long) {
        // Only log every 5 seconds to avoid flooding
        if (progress % 5000 < 500) {
            CastDebugLog.d(TAG, "onProgressUpdated: progress=${progress}ms, duration=${duration}ms")
        }
        val update = PlayerPositionUpdate(progress, duration)
        flutterApi.onPlayerPositionChanged(update) { }
    }

    fun startListen() {
        CastDebugLog.d(TAG, "startListen: Registering RemoteMediaClient callback and progress listener (interval=500ms)")
        val client = currentRemoteMediaClient
        if (client == null) {
            CastDebugLog.e(TAG, "[MEDIA ERROR] startListen: RemoteMediaClient is NULL - cannot register listeners")
            return
        }
        client.registerCallback(this)
        client.addProgressListener(this, 500)
        CastDebugLog.d(TAG, "startListen: RemoteMediaClient listeners registered successfully")
    }

    fun endListen() {
        CastDebugLog.d(TAG, "endListen: Removing RemoteMediaClient callback and progress listener")
        try {
            currentRemoteMediaClient?.removeProgressListener(this)
            currentRemoteMediaClient?.unregisterCallback(this)
            CastDebugLog.d(TAG, "endListen: RemoteMediaClient listeners removed successfully")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "endListen - failed to remove listeners", e)
        }
    }
}
