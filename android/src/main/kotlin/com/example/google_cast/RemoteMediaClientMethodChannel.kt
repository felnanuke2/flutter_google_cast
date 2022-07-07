package com.example.google_cast

import com.example.google_cast.extensions.QueueItemBuilder
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
            "queueNextItem" -> queueNextItem(call.arguments)
            "queuePrevItem" -> queuePrevItem(call.arguments)
            "queueJumpToItemWithId" -> queueJumpToItemWithId(call.arguments)
            "queueRemoveItemsWithIds" -> queueRemoveItemsWithIds(call.arguments)
            "seek" -> seek(call.arguments)
            "setActiveTrackIds" -> setActiveTrackIds(call.arguments)
            "setPlaybackRate" -> setPlaybackRate(call.arguments)
            "setTextTrackStyle" -> setTextTrackStyle(call.arguments)
            "play" -> play(call.arguments)
            "pause" -> pause(call.arguments)


        }
    }

    private fun setTextTrackStyle(arguments: Any?) {

    }

    private fun setPlaybackRate(arguments: Any?) {

    }

    private fun setActiveTrackIds(arguments: Any?) {

    }

    private fun seek(arguments: Any?) {

    }

    private fun queueRemoveItemsWithIds(arguments: Any?) {

    }

    private fun queueJumpToItemWithId(arguments: Any?) {

    }

    private fun queuePrevItem(arguments: Any?) {

    }

    private fun queueNextItem(arguments: Any?) {

    }

    private fun queueInsertItemAndPlay(arguments: Any?) {

    }

    private fun queueInsertItems(arguments: Any?) {

    }

    private fun pause(arguments: Any?) {

    }

    private fun play(arguments: Any?) {

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
            playPosition.toLong(),
            JSONObject()
        )



    }

    private fun loadMedia(arguments: Any) {
        currentRemoteMediaClient?.loadingItem


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