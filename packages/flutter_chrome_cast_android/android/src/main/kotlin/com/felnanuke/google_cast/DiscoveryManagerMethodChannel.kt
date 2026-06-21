package com.felnanuke.google_cast

import android.content.Context
import android.util.Log
import androidx.mediarouter.media.MediaControlIntent
import androidx.mediarouter.media.MediaRouteSelector
import androidx.mediarouter.media.MediaRouter
import com.felnanuke.google_cast.extensions.toMap
import com.felnanuke.google_cast.pigeon.CastDevicePigeon
import com.felnanuke.google_cast.pigeon.DiscoveryManagerFlutterApi
import com.felnanuke.google_cast.pigeon.DiscoveryManagerHostApi
import com.google.android.gms.cast.CastDevice
import com.google.android.gms.cast.CastMediaControlIntent
import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "DiscoveryManager"

class DiscoveryManagerMethodChannel : FlutterPlugin, DiscoveryManagerHostApi {

    private lateinit var flutterApi: DiscoveryManagerFlutterApi

    val routerCallBack: DiscoveryRouterCallback = DiscoveryRouterCallback()

    val router: MediaRouter
        get() = MediaRouter.getInstance(context)

    private lateinit var context: Context

    // MARK: - Flutter Plugin Lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onAttachedToEngine: Initializing DiscoveryManager method channel")
        DiscoveryManagerHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = DiscoveryManagerFlutterApi(binding.binaryMessenger)
        context = binding.applicationContext
        CastDebugLog.d(TAG, "onAttachedToEngine: DiscoveryManager ready, context=${context}")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onDetachedFromEngine: Cleaning up DiscoveryManager")
        DiscoveryManagerHostApi.setUp(binding.binaryMessenger, null)
        CastDebugLog.d(TAG, "onDetachedFromEngine: DiscoveryManager cleaned up")
    }

    override fun stopDiscovery() {
        CastDebugLog.d(TAG, "stopDiscovery: Removing router callback")
        router.removeCallback(routerCallBack)
        CastDebugLog.discoveryEvent(TAG, "Discovery STOPPED")
    }

    override fun startDiscovery() {
        CastDebugLog.d(TAG, "startDiscovery: Starting Cast device discovery")
        router.removeCallback(routerCallBack)
        val selector = MediaRouteSelector.Builder()
            .addControlCategories(listOf(CastMediaControlIntent.categoryForRemotePlayback()))
            .build()
        CastDebugLog.d(TAG, "startDiscovery: MediaRouteSelector built with categoryForRemotePlayback")
        router.addCallback(
            selector, routerCallBack, MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY
        )
        CastDebugLog.d(TAG, "startDiscovery: Router callback registered with CALLBACK_FLAG_REQUEST_DISCOVERY")
        CastDebugLog.discoveryEvent(TAG, "Discovery STARTED", mapOf(
            "totalRoutes" to router.routes.size
        ))

        routerCallBack.getCastDevicesMap()
    }

    override fun isDiscoveryActiveForDeviceCategory(deviceCategory: String): Boolean {
        val isActive = router.routes.isNotEmpty()
        CastDebugLog.d(TAG, "isDiscoveryActiveForDeviceCategory: category=$deviceCategory, isActive=$isActive, routes=${router.routes.size}")
        return isActive
    }

    inner class DiscoveryRouterCallback : MediaRouter.Callback() {

        override fun onRouteUnselected(
            router: MediaRouter, route: MediaRouter.RouteInfo, reason: Int
        ) {
            super.onRouteUnselected(router, route, reason)
            CastDebugLog.discoveryEvent(TAG, "Route UNSELECTED", mapOf(
                "routeName" to route.name,
                "reason" to reason,
                "totalRoutes" to router.routes.size
            ))
        }

        override fun onRouteAdded(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteAdded(router, route)
            val device = CastDevice.getFromBundle(route.extras)
            CastDebugLog.discoveryEvent(TAG, "Route ADDED", mapOf(
                "routeName" to route.name,
                "deviceId" to device?.deviceId,
                "deviceModel" to device?.modelName,
                "totalRoutes" to router.routes.size
            ))
            getCastDevicesMap()
        }

        override fun onRouteRemoved(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteRemoved(router, route)
            val device = CastDevice.getFromBundle(route.extras)
            CastDebugLog.discoveryEvent(TAG, "Route REMOVED", mapOf(
                "routeName" to route.name,
                "deviceId" to device?.deviceId,
                "totalRoutes" to router.routes.size
            ))
            getCastDevicesMap()
        }

        override fun onRouteChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteChanged(router, route)
            val device = CastDevice.getFromBundle(route.extras)
            CastDebugLog.discoveryEvent(TAG, "Route CHANGED", mapOf(
                "routeName" to route.name,
                "deviceId" to device?.deviceId,
                "totalRoutes" to router.routes.size
            ))
            getCastDevicesMap()
        }

        override fun onRouteVolumeChanged(router: MediaRouter, route: MediaRouter.RouteInfo) {
            super.onRouteVolumeChanged(router, route)
            CastDebugLog.d(TAG, "onRouteVolumeChanged: route=${route.name}, volume=${route.volume}")
            getCastDevicesMap()
        }

        override fun onProviderAdded(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderAdded(router, provider)
            CastDebugLog.discoveryEvent(TAG, "Provider ADDED", mapOf(
                "providerName" to provider.componentName?.flattenToShortString(),
                "totalRoutes" to router.routes.size
            ))
        }

        override fun onProviderRemoved(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderRemoved(router, provider)
            CastDebugLog.discoveryEvent(TAG, "Provider REMOVED", mapOf(
                "providerName" to provider.componentName?.flattenToShortString(),
                "totalRoutes" to router.routes.size
            ))
        }

        override fun onProviderChanged(router: MediaRouter, provider: MediaRouter.ProviderInfo) {
            super.onProviderChanged(router, provider)
            CastDebugLog.discoveryEvent(TAG, "Provider CHANGED", mapOf(
                "providerName" to provider.componentName?.flattenToShortString(),
                "totalRoutes" to router.routes.size
            ))
        }

        private fun getCastDevice(routeInfo: MediaRouter.RouteInfo): Map<*, *>? {
            val device = CastDevice.getFromBundle(routeInfo.extras)
            return device?.let {
                device.toMap()
            }
        }

        fun getCastDevicesMap() {
            val devices = mutableListOf<CastDevicePigeon>()
            val seenDeviceIds = mutableSetOf<String>()
            val seenDeviceSignatures = mutableSetOf<String>()

            CastDebugLog.d(TAG, "getCastDevicesMap: Scanning ${router.routes.size} routes for Cast devices")

            for (route in router.routes) {
                val device = getCastDevice(route)
                if (device != null) {
                    val deviceId = device["id"] as? String
                    val deviceName = device["name"] as? String
                    val deviceModel = device["model_name"] as? String
                    val deviceSignature = "${deviceName}_${deviceModel}"

                    CastDebugLog.d(TAG, "getCastDevicesMap: Found Cast device - id=$deviceId, name=$deviceName, model=$deviceModel, signature=$deviceSignature")

                    if (deviceId != null &&
                        !seenDeviceIds.contains(deviceId) &&
                        !seenDeviceSignatures.contains(deviceSignature)) {
                        seenDeviceIds.add(deviceId)
                        seenDeviceSignatures.add(deviceSignature)
                        devices.add(
                            CastDevicePigeon(
                                deviceId = deviceId,
                                friendlyName = deviceName ?: "",
                                modelName = deviceModel,
                                statusText = null,
                                deviceVersion = device["device_version"] as? String ?: "",
                                isOnLocalNetwork = device["is_on_local_network"] as? Boolean ?: false,
                                category = "",
                                uniqueId = deviceId,
                                index = null,
                            )
                        )
                        CastDebugLog.d(TAG, "getCastDevicesMap: Added unique device: $deviceId ($deviceSignature)")
                    } else {
                        CastDebugLog.d(TAG, "getCastDevicesMap: Skipping duplicate device - ID: $deviceId, signature: $deviceSignature")
                    }
                } else {
                    CastDebugLog.d(TAG, "getCastDevicesMap: Route '${route.name}' has no Cast device, skipping")
                }
            }

            CastDebugLog.d(TAG, "getCastDevicesMap: Sending ${devices.size} unique devices to Flutter")
            flutterApi.onDevicesChanged(devices) { }
        }
    }

    fun selectRoute(id: String) {
        CastDebugLog.d(TAG, "selectRoute: Attempting to select route with deviceId=$id")
        val routes = router?.routes
        CastDebugLog.d(TAG, "selectRoute: Searching among ${routes?.size ?: 0} available routes")

        val selectedRoute = routes?.find {
            val device = CastDevice.getFromBundle(it.extras)
            val match = device?.deviceId == id
            CastDebugLog.d(TAG, "selectRoute: Checking route '${it.name}' - deviceId=${device?.deviceId}, match=$match")
            match
        }

        if (selectedRoute != null) {
            CastDebugLog.d(TAG, "selectRoute: Found route '${selectedRoute.name}' for deviceId=$id, selecting it now")
            this.router?.selectRoute(selectedRoute)
            CastDebugLog.d(TAG, "selectRoute: Route selected successfully")
        } else {
            CastDebugLog.w(TAG, "selectRoute: No route found for deviceId=$id among ${routes?.size ?: 0} routes. Device may have disconnected or discovery is not active.")
        }
    }
}
