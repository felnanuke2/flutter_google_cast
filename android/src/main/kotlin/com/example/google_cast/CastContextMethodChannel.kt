package com.example.google_cast

import android.content.Context
import android.os.Build
import android.provider.CalendarContract
import androidx.annotation.RequiresApi
import androidx.mediarouter.app.MediaRouteButton
import androidx.mediarouter.media.MediaControlIntent
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import androidx.mediarouter.media.MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY
import androidx.mediarouter.media.MediaRouter.CALLBACK_FLAG_UNFILTERED_EVENTS
import com.google.android.gms.cast.LaunchOptions
import com.google.android.gms.cast.framework.CastButtonFactory


class CastContextMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val discoveryManager = DiscoveryManagerMethodChannel()
    private lateinit var sessionManagerMethodChannel: SessionManagerMethodChannel

    private val castContext: CastContext?
        get() {
            return CastContext.getSharedInstance()
        }


    //FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.context")
        channel.setMethodCallHandler(this)
        discoveryManager.onAttachedToEngine(binding)
        sessionManagerMethodChannel = SessionManagerMethodChannel(discoveryManager)
        sessionManagerMethodChannel.onAttachedToEngine(binding)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }


    // MethodCallHandler
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "setSharedInstance" -> result.success(setSharedInstance(call.arguments))
            else -> result.notImplemented()
        }
    }


    private fun setSharedInstance(arguments: Any?): Boolean {
        val map = arguments as HashMap<String, Any>
        var optionsBuilder = CastOptions.Builder()
        optionsBuilder.setReceiverApplicationId(map["appId"] as String)
        val launcherOptions = LaunchOptions.Builder().setAndroidReceiverCompatible(true).build()
        optionsBuilder.setLaunchOptions(launcherOptions)
        optionsBuilder.setResumeSavedSession(true)
        optionsBuilder.setEnableReconnectionService(true)
        GoogleCastOptionsProvider.options = optionsBuilder.build()
        CastContext.getSharedInstance(appContext)
        castContext?.sessionManager?.addSessionManagerListener(sessionManagerMethodChannel)
        return true
    }
}