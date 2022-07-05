package com.example.google_cast

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class SessionManagerMethodChannel(discoveryManager: DiscoveryManagerMethodChannel) : FlutterPlugin,
    MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private val discoveryManagerMethodChannel: DiscoveryManagerMethodChannel = discoveryManager
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.session_manager")
        channel.setMethodCallHandler(this)

    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSessionWithDeviceId" -> startSession(call.arguments, result)
        }

    }

    private fun startSession(arguments: Any?, result: MethodChannel.Result) {
        val deviceId = arguments as String
        discoveryManagerMethodChannel.selectRoute(deviceId)

        result.success(true)
    }
}