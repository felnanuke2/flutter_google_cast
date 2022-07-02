package com.example.google_cast

import android.content.Context
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel


class CastContextMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var appContext: Context
    private val castContext: CastContext?
        get() {
            return CastContext.getSharedInstance()
        }


    //FlutterPlugin
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        appContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.context")
        channel.setMethodCallHandler(this)

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
       val map =  arguments as HashMap<String,Any>
        var optionsBuilder = CastOptions.Builder()
        optionsBuilder.setReceiverApplicationId(map["appId"] as String)

        GoogleCastOptionsProvider.options = optionsBuilder.build()

        CastContext.getSharedInstance(appContext)
        return true
    }
}