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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

private const val TAG = "DiscoveryManager"

/** Fire-and-forget scope used to push Flutter API events. */
private val flutterApiScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)

class DiscoveryManagerMethodChannel : FlutterPlugin, DiscoveryManagerHostApi {

    private lateinit var flutterApi: DiscoveryManagerFlutterApi

    val routerCallBack: DiscoveryRouterCallback = DiscoveryRouterCallback()

    val router: MediaRouter
        get() = MediaRouter.getInstance(context)

    private lateinit var context: Context

    /**
     * Whether a discovery router callback is currently registered.
     *
     * [MediaRouter.routes] is a poor proxy for this: it always contains at least
     * the local "Phone" route, so it reports discovery as active even before
     * [startDiscovery] is ever called. This flag mirrors the real callback
     * registration state instead.
     */
    private var isDiscovering = false

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
        isDiscovering = false
        // Drop the last known device list so consumers do not keep acting on
        // receivers that are no longer being discovered.
        flutterApiScope.launch { flutterApi.onDevicesChanged(emptyList()) }
        CastDebugLog.discoveryEvent(TAG, "Discovery STOPPED")
    }

    override fun startDiscovery(activeScan: Boolean) {
        CastDebugLog.d(TAG, "startDiscovery: Starting Cast device discovery (activeScan=$activeScan)")
        router.removeCallback(routerCallBack)
        val selector = MediaRouteSelector.Builder()
            .addControlCategories(listOf(CastMediaControlIntent.categoryForRemotePlayback()))
            .build()
        var flags = MediaRouter.CALLBACK_FLAG_REQUEST_DISCOVERY
        if (activeScan) {
            // Ask the media router to perform an active scan so receivers that
            // the passive scan misses are still discovered.
            flags = flags or MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN
        }
        CastDebugLog.d(TAG, "startDiscovery: MediaRouteSelector built with categoryForRemotePlayback")
        router.addCallback(selector, routerCallBack, flags)
        isDiscovering = true
        CastDebugLog.d(TAG, "startDiscovery: Router callback registered with flags=$flags")
        CastDebugLog.discoveryEvent(TAG, "Discovery STARTED", mapOf(
            "totalRoutes" to router.routes.size
        ))

        routerCallBack.getCastDevicesMap()
    }

    override fun isDiscoveryActiveForDeviceCategory(deviceCategory: String): Boolean {
        // MediaRouter on Android discovers every Cast route in the
        // "remote playback" category; there is no per-app-category discovery to
        // query. Report the real callback registration state and keep the
        // category argument for API parity with iOS.
        val isActive = isDiscovering
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
            // Volume changes do not affect the device list; re-sending the whole
            // map here only spams the Flutter side with identical payloads.
            CastDebugLog.d(TAG, "onRouteVolumeChanged: route=${route.name}, volume=${route.volume}")
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
            // Deduplicate by device id only. Keying on name+model collapses two
            // physically different receivers that share a friendly name (very
            // common with identical TVs), making one of them unreachable.
            val seenDeviceIds = mutableSetOf<String>()

            CastDebugLog.d(TAG, "getCastDevicesMap: Scanning ${router.routes.size} routes for Cast devices")

            for (route in router.routes) {
                val device = getCastDevice(route)
                if (device != null) {
                    val deviceId = device["id"] as? String
                    val deviceName = device["name"] as? String
                    val deviceModel = device["model_name"] as? String

                    CastDebugLog.d(TAG, "getCastDevicesMap: Found Cast device - id=$deviceId, name=$deviceName, model=$deviceModel")

                    if (deviceId != null && seenDeviceIds.add(deviceId)) {
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
                        CastDebugLog.d(TAG, "getCastDevicesMap: Added unique device: $deviceId ($deviceName)")
                    } else {
                        CastDebugLog.d(TAG, "getCastDevicesMap: Skipping duplicate device - ID: $deviceId")
                    }
                } else {
                    CastDebugLog.d(TAG, "getCastDevicesMap: Route '${route.name}' has no Cast device, skipping")
                }
            }

            CastDebugLog.d(TAG, "getCastDevicesMap: Sending ${devices.size} unique devices to Flutter")
            flutterApiScope.launch { flutterApi.onDevicesChanged(collapseAndroidTvDuplicates(devices)) }
        }

        /**
         * Android TV receivers publish two routes for the same physical device:
         * the classic Cast route (opaque hex device id) and a Cast Connect route
         * (UUID-format device id that also changes across receiver restarts).
         * Keep the classic route whenever both exist for the same
         * friendly name + model, so the device list does not show duplicates.
         */
        private fun collapseAndroidTvDuplicates(devices: List<CastDevicePigeon>): List<CastDevicePigeon> {
            fun isAndroidTvRoute(id: String?) = id != null && id.contains("-")
            val classic = devices.filter { !isAndroidTvRoute(it.deviceId) }
            val androidTv = devices.filter { isAndroidTvRoute(it.deviceId) }
            val kept = classic + androidTv.filter { atv ->
                classic.none { it.friendlyName == atv.friendlyName && it.modelName == atv.modelName }
            }
            if (kept.size != devices.size) {
                CastDebugLog.d(
                    TAG,
                    "collapseAndroidTvDuplicates: collapsed ${devices.size} routes -> ${kept.size} devices " +
                        "(dropped Cast Connect duplicate(s) ${devices.filter { d -> !kept.any { it.deviceId == d.deviceId } }.map { it.deviceId }})"
                )
            }
            return kept
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
