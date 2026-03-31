package com.felnanuke.google_cast

import android.media.session.MediaSession
import android.util.Log
import com.felnanuke.google_cast.extensions.*
import com.felnanuke.google_cast.pigeon.*
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
        val mediaInfo = request.mediaInfo.toCastMediaInfo() ?: return
        currentRemoteMediaClient?.load(request.toCastMediaLoadRequestData(mediaInfo))
    }

    override fun queueLoadItems(request: QueueLoadRequestPigeon) {
        val queueItems = request.items.mapNotNull { item ->
            item?.toCastMediaQueueItem()
        }
        val options = request.options
        val startIndex = options?.startIndex?.toInt() ?: 0
        val playPosition = options?.playPosition ?: 0L
        val queueCustomDataJson = options.toQueueCustomDataJson()

        currentRemoteMediaClient?.queueLoad(
            queueItems.toTypedArray(),
            startIndex,
            request.options?.repeatMode.toCastRepeatMode(),
            playPosition * 1000,
            queueCustomDataJson
        )
    }

    override fun queueInsertItems(request: QueueInsertItemsRequestPigeon) {
        val items = request.items.mapNotNull { item ->
            item?.toCastMediaQueueItem()
        }
        val beforeItemWithId = request.beforeItemWithId?.toInt() ?: MediaSession.QueueItem.UNKNOWN_ID
        currentRemoteMediaClient?.queueInsertItems(items.toTypedArray(), beforeItemWithId, JSONObject())
    }

    override fun queueInsertItemAndPlay(request: QueueInsertItemAndPlayRequestPigeon) {
        val item = request.item.toCastMediaQueueItem() ?: return
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
        currentRemoteMediaClient?.seek(request.toCastSeekOptions())
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

    override fun onStatusUpdated() {
        super.onStatusUpdated()
        val mediaStatus = currentRemoteMediaClient?.mediaStatus
        val pigeonStatus = mediaStatus?.toPigeonMediaStatus()
        Log.w(TAG, "onStatusUpdated hasStatus=${pigeonStatus != null}")
        flutterApi.onMediaStatusChanged(pigeonStatus) { }
    }

    override fun onQueueStatusUpdated() {
        super.onQueueStatusUpdated()
        val queueItems = currentRemoteMediaClient?.mediaStatus?.queueItems?.map { it.toPigeonMediaQueueItem() } ?: emptyList()
        flutterApi.onQueueStatusChanged(queueItems) { }
    }

    override fun onProgressUpdated(progress: Long, duration: Long) {
        val update = PlayerPositionUpdate(progress, duration)
        flutterApi.onPlayerPositionChanged(update) { }
    }

    fun startListen() {
        currentRemoteMediaClient?.registerCallback(this)
        currentRemoteMediaClient?.addProgressListener(this, 500)
    }

    fun endListen() {
        currentRemoteMediaClient?.removeProgressListener(this)
        currentRemoteMediaClient?.unregisterCallback(this)
    }
}
