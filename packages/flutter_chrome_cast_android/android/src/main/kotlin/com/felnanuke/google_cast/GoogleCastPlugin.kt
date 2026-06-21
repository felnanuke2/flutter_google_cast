package com.felnanuke.google_cast

import android.app.Activity
import android.app.Application
import android.os.Bundle
import android.util.Log
import androidx.annotation.NonNull
import com.google.android.gms.cast.framework.CastContext

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

class GoogleCastPlugin : FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks {

    companion object {
        private const val TAG = "GoogleCastPlugin"
    }

    private val castContextMethodChannel = CastContextMethodChannel()

    private var activity: Activity? = null

    private var applicationContext: android.content.Context? = null

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onAttachedToEngine: Initializing Google Cast plugin")
        CastDebugLog.d(TAG, "onAttachedToEngine: application context=${flutterPluginBinding.applicationContext}")
        CastDebugLog.d(TAG, "onAttachedToEngine: isDebug=${CastDebugLog.isDebug}")
        applicationContext = flutterPluginBinding.applicationContext
        try {
            castContextMethodChannel.onAttachedToEngine(flutterPluginBinding)
            CastDebugLog.d(TAG, "onAttachedToEngine: CastContextMethodChannel attached successfully")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "onAttachedToEngine", e)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onDetachedFromEngine: Cleaning up Google Cast plugin")
        try {
            castContextMethodChannel.onDetachedFromEngine(binding)
            CastDebugLog.d(TAG, "onDetachedFromEngine: CastContextMethodChannel detached successfully")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "onDetachedFromEngine", e)
        }
    }

    // MARK: - ActivityAware Implementation

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        CastDebugLog.d(TAG, "onAttachedToActivity: activity=${activity?.javaClass?.simpleName}, taskId=${activity?.taskId}")
        activity?.application?.registerActivityLifecycleCallbacks(this)
        CastDebugLog.d(TAG, "onAttachedToActivity: Activity lifecycle callbacks registered")
    }

    override fun onDetachedFromActivityForConfigChanges() {
        CastDebugLog.d(TAG, "onDetachedFromActivityForConfigChanges: Activity detached for config change (e.g., rotation)")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        CastDebugLog.d(TAG, "onReattachedToActivityForConfigChanges: activity=${activity?.javaClass?.simpleName}")
    }

    override fun onDetachedFromActivity() {
        CastDebugLog.d(TAG, "onDetachedFromActivity: Unregistering lifecycle callbacks, activity=${activity?.javaClass?.simpleName}")
        activity?.application?.unregisterActivityLifecycleCallbacks(this)
        activity = null
    }

    // MARK: - Application.ActivityLifecycleCallbacks Implementation

    override fun onActivityCreated(activity: Activity, savedInstanceState: Bundle?) {
        CastDebugLog.d(TAG, "onActivityCreated: ${activity.javaClass.simpleName}")
    }

    override fun onActivityStarted(activity: Activity) {
        CastDebugLog.d(TAG, "onActivityStarted: ${activity.javaClass.simpleName}")
    }

    override fun onActivityResumed(activity: Activity) {
        CastDebugLog.d(TAG, "onActivityResumed: ${activity.javaClass.simpleName}")
    }

    override fun onActivityPaused(activity: Activity) {
        CastDebugLog.d(TAG, "onActivityPaused: ${activity.javaClass.simpleName}")
    }

    override fun onActivityStopped(activity: Activity) {
        CastDebugLog.d(TAG, "onActivityStopped: ${activity.javaClass.simpleName}")
    }

    override fun onActivitySaveInstanceState(activity: Activity, outState: Bundle) {
        CastDebugLog.d(TAG, "onActivitySaveInstanceState: ${activity.javaClass.simpleName}")
    }

    override fun onActivityDestroyed(activity: Activity) {
        CastDebugLog.d(TAG, "onActivityDestroyed: ${activity.javaClass.simpleName}, isFinishing=${activity.isFinishing}, isSameActivity=${activity == this.activity}")
        if (activity == this.activity && activity.isFinishing) {
            if (!GoogleCastOptionsProvider.stopCastingOnAppTerminated) {
                CastDebugLog.d(TAG, "onActivityDestroyed: stopCastingOnAppTerminated=false, keeping cast session alive on receiver")
                return
            }

            try {
                val context = applicationContext ?: run {
                    CastDebugLog.w(TAG, "onActivityDestroyed: applicationContext is null, cannot end session")
                    return
                }
                val castContext = CastContext.getSharedInstance(context)
                val sessionManager = castContext?.sessionManager
                val currentSession = sessionManager?.currentCastSession
                if (currentSession != null) {
                    CastDebugLog.d(TAG, "onActivityDestroyed: Ending cast session - sessionId=${currentSession.sessionId}, device=${currentSession.castDevice?.friendlyName}, stopCastingOnAppTerminated=true")
                    sessionManager.endCurrentSession(true)
                    CastDebugLog.d(TAG, "onActivityDestroyed: endCurrentSession(true) called successfully")
                } else {
                    CastDebugLog.d(TAG, "onActivityDestroyed: No active cast session to end")
                }
            } catch (e: Exception) {
                CastDebugLog.castError(TAG, "onActivityDestroyed - failed to end cast session", e)
            }
        }
    }
}
