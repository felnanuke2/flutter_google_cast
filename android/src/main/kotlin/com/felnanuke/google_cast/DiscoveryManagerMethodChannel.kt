package com.felnanuke.google_cast

import android.content.Context
import androidx.mediarouter.media.MediaControlIntent
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import com.google.android.gms.cast.framework.CastContext
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlin.system.exitProcess

private const val TAG = "DiscoveryManager"

class DiscoveryManagerMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    lateinit var channel: MethodChannel
    private val routerCallBack: DiscoveryRouterCallback = DiscoveryRouterCallback()
    val router: MediaRouter
        get() = MediaRouter.getInstance(context)
    private lateinit var context: Context


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.discovery_manager")
        channel.setMethodCallHandler(this)
        context = binding.applicationContext
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startDiscovery" -> startDiscovery()
            "stopDiscovery" -> router.removeCallback(routerCallBack)
        }
    }

    private fun startDiscovery() {

        router.removeCallback(routerCallBack)
        val selector = MediaRouteSelector.Builder()
            .addControlCategories(listOf(CastMediaControlIntent.categoryForCast("ED7DABE1"))).build()
        router.addCallback(
            selector, routerCallBack, MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN
        )
        routerCallBack.getCastDevicesMap()
    }


    inner class DiscoveryRouterCallback : MediaRouter.Callback() {


        override fun onRouteUnselected(
            router: MediaRouter, route: MediaRouter.RouteInfo, reason: Int
        ) {
            super.onRouteUnselected(router, route, reason)

            print("routes ${router?.routes?.size}")
        }

        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteAdded(router, route)
            if (router != null) getCastDevicesMap()
        }

        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteRemoved(router, route)
            if (router != null) getCastDevicesMap()
        }

        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteChanged(router, route)
            if (router != null) getCastDevicesMap()
        }

        override fun onRouteVolumeChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteVolumeChanged(router, route)
            if (router != null) getCastDevicesMap()
        }

        override fun onRoutePresentationDisplayChanged(
            router: MediaRouter, route: MediaRouter.RouteInfo
        ) {
            super.onRoutePresentationDisplayChanged(router, route)

        }

        override fun onProviderAdded(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderAdded(router, provider)
            print("routes ${router?.routes?.size}")
        }

        override fun onProviderRemoved(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderRemoved(router, provider)
            print("routes ${router.routes.size}")
        }

        override fun onProviderChanged(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderChanged(router, provider)
            print("routes ${router.routes.size}")
        }

        private fun getCastDevice(routeInfo: MediaRouter.RouteInfo): CastDevice? {

            return CastDevice.getFromBundle(routeInfo.extras)
        }

         fun getCastDevicesMap() {
            if (router == null) return
            var devices = mutableListOf<CastDevice>()
            for (route in router!!.routes) {
                val device = getCastDevice(route)
                if (device != null) {
                    devices.add(device)
                }
            }
            val json = Gson().toJson(devices)
            this@DiscoveryManagerMethodChannel.channel.invokeMethod("onDevicesChanged", json)
        }
    }

    fun selectRoute(id: String) {
        val routes = router?.routes
        val selectedRoute = routes?.find {
            val device = CastDevice.getFromBundle(it.extras)
            device?.deviceId == id
        }
        if (selectedRoute != null) {
            this.router?.selectRoute(selectedRoute)
        }
    }


}