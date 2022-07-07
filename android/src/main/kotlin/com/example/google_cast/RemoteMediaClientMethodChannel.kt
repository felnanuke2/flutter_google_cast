package com.example.google_cast

import com.example.google_cast.extensions.GoogleCastSeekOptionsBuilder
import com.example.google_cast.extensions.QueueItemBuilder
import com.google.android.gms.cast.MediaSeekOptions
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.media.RemoteMediaClient
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class RemoteMediaClientMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler,
    RemoteMediaClient.Callback(), RemoteMediaClient.ProgressListener {
    private lateinit var channel: MethodChannel
    private val currentRemoteMediaClient: RemoteMediaClient?
        get() =
            CastContext.getSharedInstance()?.sessionManager?.currentCastSession?.remoteMediaClient


    // FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.remote_media_client")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadMedia" -> loadMedia(call.arguments)
            "queueLoadItems" -> queueLoadItems(call.arguments as Map<String, Any?>)
            "queueInsertItems" -> queueInsertItems(call.arguments)
            "queueInsertItemAndPlay" -> queueInsertItemAndPlay(call.arguments)
            "queueNextItem" -> queueNextItem()
            "queuePrevItem" -> queuePrevItem()
            "queueJumpToItemWithId" -> queueJumpToItemWithId(call.arguments)
            "queueRemoveItemsWithIds" -> queueRemoveItemsWithIds(call.arguments)
            "seek" -> seek(call.arguments)
            "setActiveTrackIds" -> setActiveTrackIds(call.arguments)
            "setPlaybackRate" -> setPlaybackRate(call.arguments)
            "setTextTrackStyle" -> setTextTrackStyle(call.arguments)
            "play" -> play()
            "pause" -> pause()


        }
    }

    private fun setTextTrackStyle(arguments: Any?) {

    }

    private fun setPlaybackRate(arguments: Any?) {
        val playbackRate = arguments as Double
        currentRemoteMediaClient?.setPlaybackRate(playbackRate)
    }

    private fun setActiveTrackIds(arguments: Any?) {
        arguments as IntArray
        val longArray = arguments.map {
            it.toLong()
        }
        currentRemoteMediaClient?.setActiveMediaTracks(longArray.toLongArray())

    }

    private fun seek(arguments: Any?) {
        arguments as Map<String, Any?>
        val options = GoogleCastSeekOptionsBuilder.fromMap(arguments)
        currentRemoteMediaClient?.seek(options)
    }

    private fun queueRemoveItemsWithIds(arguments: Any?) {
        arguments as IntArray
        currentRemoteMediaClient?.queueRemoveItems(arguments, JSONObject())
    }

    private fun queueJumpToItemWithId(arguments: Any?) {
        val itemId = arguments as Int
        currentRemoteMediaClient?.queueJumpToItem(itemId, JSONObject())

    }

    private fun queuePrevItem() {
        currentRemoteMediaClient?.queuePrev(JSONObject())
    }

    private fun queueNextItem() {
        currentRemoteMediaClient?.queueNext(JSONObject())
    }

    private fun queueInsertItemAndPlay(arguments: Any?) {

    }

    private fun queueInsertItems(arguments: Any?) {

    }

    private fun pause() {
        currentRemoteMediaClient?.pause()
    }

    private fun play() {
        currentRemoteMediaClient?.play()

    }

    private fun queueLoadItems(arguments: Map<String, Any?>) {
        val queueItemsData = arguments["queueItems"] as List<Map<String, Any?>>
        val optionsData = arguments["options"] as Map<String, Any?>
        val startIndex = optionsData["startIndex"] as Int
        val repeatMode = optionsData["repeatMode"] as Int
        val playPosition = optionsData["playPosition"] as Int
        val queueItems = QueueItemBuilder.listFromMap(queueItemsData)
        currentRemoteMediaClient?.queueLoad(
            queueItems.toTypedArray(),
            startIndex,
            repeatMode,
            playPosition.toLong() * 1000,
            JSONObject()
        )


    }

    private fun loadMedia(arguments: Any) {


    }

    fun startListen() {
        currentRemoteMediaClient?.registerCallback(this)
        currentRemoteMediaClient?.addProgressListener(this, 500)
    }

    fun endListen() {
        currentRemoteMediaClient?.removeProgressListener(this)
        currentRemoteMediaClient?.unregisterCallback(this)
    }

    // ProgressListener
    override fun onProgressUpdated(progress: Long, duration: Long) {
        var data = mapOf<String, Any?>(
            "progress" to progress,
            "duration" to duration,
        )
        channel.invokeMethod("onPlayerPositionChanged", data)
    }
    // RemoteMediaCallBack

    override fun onStatusUpdated() {

        super.onStatusUpdated()
        println("onStatusChanged")


    }
}