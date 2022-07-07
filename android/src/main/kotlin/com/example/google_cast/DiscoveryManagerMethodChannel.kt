package com.example.google_cast

import androidx.mediarouter.media.MediaRouter
import com.google.android.gms.cast.CastDevice
import com.google.gson.Gson
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class DiscoveryManagerMethodChannel : FlutterPlugin, MethodChannel.MethodCallHandler {

    lateinit var channel: MethodChannel
    val routerCallBack: MediaRouter.Callback = DiscoveryRouterCallback()
    var router: MediaRouter? = null


    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.discovery_manager")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {

    }

    inner class DiscoveryRouterCallback : MediaRouter.Callback() {

        override fun onRouteUnselected(
            router: MediaRouter?,
            route: MediaRouter.RouteInfo?,
            reason: Int
        ) {
            super.onRouteUnselected(router, route, reason)
            print("routes ${router?.routes?.size}")
        }

        override fun onRouteAdded(router: MediaRouter?, route: MediaRouter.RouteInfo?) {
            super.onRouteAdded(router, route)
            if (router != null)
                getCastDevicesMap(router.routes)
        }

        override fun onRouteRemoved(router: MediaRouter?, route: MediaRouter.RouteInfo?) {
            super.onRouteRemoved(router, route)
            if (router != null)
                getCastDevicesMap(router.routes)
        }

        override fun onRouteChanged(router: MediaRouter?, route: MediaRouter.RouteInfo?) {
            super.onRouteChanged(router, route)
            this@DiscoveryManagerMethodChannel.router = router
            if (router != null)
                getCastDevicesMap(router.routes)
        }

        override fun onRouteVolumeChanged(router: MediaRouter?, route: MediaRouter.RouteInfo?) {
            super.onRouteVolumeChanged(router, route)
            if (router != null)
                getCastDevicesMap(router.routes)
        }

        override fun onRoutePresentationDisplayChanged(
            router: MediaRouter?,
            route: MediaRouter.RouteInfo?
        ) {
            super.onRoutePresentationDisplayChanged(router, route)
        }

        override fun onProviderAdded(router: MediaRouter?, provider: MediaRouter.ProviderInfo?) {
            super.onProviderAdded(router, provider)
            print("routes ${router?.routes?.size}")
        }

        override fun onProviderRemoved(router: MediaRouter?, provider: MediaRouter.ProviderInfo?) {
            super.onProviderRemoved(router, provider)
            print("routes ${router?.routes?.size}")
        }

        override fun onProviderChanged(router: MediaRouter?, provider: MediaRouter.ProviderInfo?) {
            super.onProviderChanged(router, provider)
            print("routes ${router?.routes?.size}")
        }

         fun getCastDevice(routeInfo: MediaRouter.RouteInfo?): CastDevice? {
            if (routeInfo == null) return null
            return CastDevice.getFromBundle(routeInfo.extras)
        }

        private fun getCastDevicesMap(routes: List<MediaRouter.RouteInfo>) {
            var devices = mutableListOf<CastDevice>()
            for (route in routes) {
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
            device?.deviceId  == id
        }
        if (selectedRoute != null) {
            this.router?.selectRoute(selectedRoute)
        }
    }


}