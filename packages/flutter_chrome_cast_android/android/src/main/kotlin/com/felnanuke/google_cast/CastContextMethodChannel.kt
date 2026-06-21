package com.felnanuke.google_cast

import android.annotation.SuppressLint
import android.content.Context
import android.os.Build
import android.util.Log
import androidx.activity.ComponentActivity
import androidx.activity.result.ActivityResultLauncher
import androidx.activity.result.contract.ActivityResultContracts
import com.felnanuke.google_cast.pigeon.CastContextInitRequest
import com.felnanuke.google_cast.pigeon.CastOptionsPigeon
import com.felnanuke.google_cast.pigeon.FlutterError
import com.felnanuke.google_cast.pigeon.GoogleCastContextHostApi
import com.google.android.gms.cast.framework.CastContext
import com.google.android.gms.cast.framework.CastOptions
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import com.google.android.gms.cast.LaunchOptions
import java.util.concurrent.Executors

private const val TAG = "CastContext"

class CastContextMethodChannel : FlutterPlugin, GoogleCastContextHostApi {

    private lateinit var appContext: Context

    private val discoveryManager = DiscoveryManagerMethodChannel()

    private lateinit var sessionManagerMethodChannel: SessionManagerMethodChannel

    private lateinit var nearbyWifiDevicesPermissionLauncher: ActivityResultLauncher<String>

    private val executor = Executors.newSingleThreadExecutor()

    // MARK: - Flutter Plugin Lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onAttachedToEngine: Initializing Cast context method channel")
        CastDebugLog.d(TAG, "onAttachedToEngine: application context=${binding.applicationContext}")

        appContext = binding.applicationContext

        CastDebugLog.d(TAG, "onAttachedToEngine: Attaching DiscoveryManagerMethodChannel")
        discoveryManager.onAttachedToEngine(binding)

        CastDebugLog.d(TAG, "onAttachedToEngine: Creating SessionManagerMethodChannel")
        sessionManagerMethodChannel = SessionManagerMethodChannel(discoveryManager)

        CastDebugLog.d(TAG, "onAttachedToEngine: Attaching SessionManagerMethodChannel")
        sessionManagerMethodChannel.onAttachedToEngine(binding)

        GoogleCastContextHostApi.setUp(binding.binaryMessenger, this)
        CastDebugLog.d(TAG, "onAttachedToEngine: GoogleCastContextHostApi setUp complete")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onDetachedFromEngine: Cleaning up Cast context method channel")
        GoogleCastContextHostApi.setUp(binding.binaryMessenger, null)
        try {
            val sessionManager = CastContext.getSharedInstance(appContext)?.sessionManager
            if (sessionManager != null) {
                sessionManager.removeSessionManagerListener(sessionManagerMethodChannel)
                CastDebugLog.d(TAG, "onDetachedFromEngine: SessionManagerListener removed successfully")
            } else {
                CastDebugLog.w(TAG, "onDetachedFromEngine: SessionManager was null, nothing to remove")
            }
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "onDetachedFromEngine - failed to remove session manager listener", e)
        }
    }

    private fun setupActivityResult(activity: ComponentActivity) {
        CastDebugLog.d(TAG, "setupActivityResult: Registering permission launcher for NearbyWifiDevices (Android 13+)")
        nearbyWifiDevicesPermissionLauncher =
            activity.registerForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted: Boolean ->
                if (isGranted) {
                    CastDebugLog.d(TAG, "Nearby WiFi devices permission GRANTED - device discovery enabled")
                } else {
                    CastDebugLog.w(TAG, "Nearby WiFi devices permission DENIED - device discovery may not work on Android 13+")
                }
            }
    }

    override fun setSharedInstanceWithOptions(request: CastContextInitRequest): Boolean {
        CastDebugLog.d(TAG, "setSharedInstanceWithOptions: Received Cast context init request")
        CastDebugLog.castOperation(TAG, "setSharedInstanceWithOptions", mapOf(
            "appId" to request.options.appId,
            "stopCastingOnAppTerminated" to request.options.stopCastingOnAppTerminated
        ))

        try {
            val result = setSharedInstance(request.options)
            CastDebugLog.castResult(TAG, "setSharedInstanceWithOptions", result, "appId=${request.options.appId}")
            return result
        } catch (e: Exception) {
            val errorMsg = CastDebugLog.castError(TAG, "setSharedInstanceWithOptions", e)
            throw FlutterError("CAST_INIT_ERROR", "Failed to initialize Cast context: ${e.message}. ${e.cause?.let { "Cause: ${it.message}" } ?: ""}", null)
        }
    }

    private fun setSharedInstance(options: CastOptionsPigeon): Boolean {
        val appId = options.appId
        if (appId == null) {
            CastDebugLog.e(TAG, "setSharedInstance: Missing required Cast appId")
            throw IllegalArgumentException("Missing required Cast appId - cannot initialize Cast context without a receiver app ID")
        }

        CastDebugLog.d(TAG, "setSharedInstance: Building CastOptions with appId=$appId")

        val optionsBuilder = CastOptions.Builder()
        optionsBuilder.setReceiverApplicationId(appId)

        val launcherOptions = LaunchOptions.Builder().setAndroidReceiverCompatible(true).build()
        optionsBuilder.setLaunchOptions(launcherOptions)
        CastDebugLog.d(TAG, "setSharedInstance: LaunchOptions set - androidReceiverCompatible=true")

        optionsBuilder.setResumeSavedSession(true)
        CastDebugLog.d(TAG, "setSharedInstance: ResumeSavedSession=true")

        optionsBuilder.setEnableReconnectionService(true)
        CastDebugLog.d(TAG, "setSharedInstance: EnableReconnectionService=true")

        val castOptions = optionsBuilder.build()
        GoogleCastOptionsProvider.options = castOptions
        CastDebugLog.d(TAG, "setSharedInstance: CastOptions stored in GoogleCastOptionsProvider")

        GoogleCastOptionsProvider.stopCastingOnAppTerminated = options.stopCastingOnAppTerminated
        CastDebugLog.d(TAG, "setSharedInstance: stopCastingOnAppTerminated=${options.stopCastingOnAppTerminated}")

        try {
            val castContext = CastContext.getSharedInstance(appContext)
            val sessionManager = castContext.sessionManager
            sessionManager.addSessionManagerListener(sessionManagerMethodChannel)
            CastDebugLog.d(TAG, "setSharedInstance: SessionManagerListener added to session manager")
            CastDebugLog.d(TAG, "setSharedInstance: Cast SDK initialized successfully with appId=$appId")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "setSharedInstance - failed to get CastContext shared instance or add listener", e)
            throw e
        }

        return true
    }
}
