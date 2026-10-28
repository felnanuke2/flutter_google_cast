package com.felnanuke.google_cast

import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import com.felnanuke.google_cast.pigeon.CastDevicePigeon
import com.felnanuke.google_cast.pigeon.CastSessionPigeon
import com.felnanuke.google_cast.pigeon.ConnectionStatePigeon
import com.felnanuke.google_cast.pigeon.FlutterError
import com.felnanuke.google_cast.pigeon.SessionManagerFlutterApi
import com.felnanuke.google_cast.pigeon.SessionManagerHostApi
import com.felnanuke.google_cast.pigeon.StartSessionRequest
import com.google.android.gms.cast.Cast
import com.google.android.gms.cast.framework.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

private const val TAG = "SessionManager"

/** How long after a session teardown a reconnect must wait to not be canceled by the SDK. */
private const val SESSION_END_GRACE_MS = 1500L

/** Fallback delay before asserting a staged mute when no volume event fires. */
private const val MUTE_SETTLE_MS = 600L

class SessionManagerMethodChannel(discoveryManager: DiscoveryManagerMethodChannel) : FlutterPlugin,
    SessionManagerHostApi, SessionManagerListener<Session> {

    private lateinit var flutterApi: SessionManagerFlutterApi

    /** Fire-and-forget scope used to push Flutter API events. */
    private val eventScope = CoroutineScope(Dispatchers.Main)

    private val mainHandler = Handler(Looper.getMainLooper())

    /** Elapsed-realtime mark of the last requested session teardown. */
    @Volatile
    private var lastSessionEndAt = 0L

    private fun markSessionEnd() {
        lastSessionEndAt = SystemClock.elapsedRealtime()
    }

    private val discoveryManagerMethodChannel: DiscoveryManagerMethodChannel = discoveryManager

    private val remoteMediaClientMethodChannel = RemoteMediaClientMethodChannel()

    /** Namespaces requested by Flutter. They survive Cast session changes. */
    private val requestedMessageNamespaces = mutableSetOf<String>()

    /** Forwards receiver text messages to the Dart message stream. */
    private val messageReceivedCallback = Cast.MessageReceivedCallback { _, namespace, message ->
        eventScope.launch { flutterApi.onMessageReceived(namespace, message) }
    }

    /** Re-emits session state when the receiver reports volume/mute changes. */
    private val volumeListener = object : Cast.Listener() {
        override fun onVolumeChanged() {
            val session = sessionManager?.currentCastSession
            CastDebugLog.d(TAG, "onVolumeChanged: volume=${session?.volume} isMute=${session?.isMute}")
            applyPendingMute()
            onSessionChanged()
        }
    }

    /**
     * Mute request waiting for the volume change to settle. Many receivers
     * unmute as a side effect of applying a volume step, so the mute must be
     * (re-)asserted after the volume lands rather than sent concurrently.
     */
    @Volatile
    private var pendingMute: Boolean? = null

    private fun applyPendingMute() {
        val mute = pendingMute ?: return
        val session = sessionManager?.currentCastSession ?: return
        if (session.isMute != mute) {
            try {
                session.setMute(mute)
                CastDebugLog.d(TAG, "applyPendingMute: setMute($mute) sent")
            } catch (e: Exception) {
                CastDebugLog.castError(TAG, "applyPendingMute(setMute=$mute)", e)
            }
        }
        pendingMute = null
    }

    private fun attachVolumeListener(session: Session) {
        (session as? CastSession)?.addCastListener(volumeListener)
    }

    private fun detachVolumeListener(session: Session) {
        try {
            (session as? CastSession)?.removeCastListener(volumeListener)
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "detachVolumeListener", e)
        }
    }

    private val sessionManager: SessionManager?
        get() {
            return CastContext.getSharedInstance()?.sessionManager
        }

    // MARK: - Flutter Plugin Lifecycle

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onAttachedToEngine: Initializing SessionManager method channel")
        SessionManagerHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = SessionManagerFlutterApi(binding.binaryMessenger)
        remoteMediaClientMethodChannel.onAttachedToEngine(binding)
        CastDebugLog.d(TAG, "onAttachedToEngine: SessionManager ready, RemoteMediaClient attached")
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        CastDebugLog.d(TAG, "onDetachedFromEngine: Cleaning up SessionManager")
        sessionManager?.currentCastSession?.let { session ->
            requestedMessageNamespaces.forEach { namespace ->
                try {
                    session.removeMessageReceivedCallbacks(namespace)
                } catch (_: Exception) {
                    // The Cast session may already be disconnected.
                }
            }
        }
        // The engine may re-attach with fresh Dart state; drop stale
        // registrations so channels don't silently reattach later.
        requestedMessageNamespaces.clear()
        SessionManagerHostApi.setUp(binding.binaryMessenger, null)
        CastDebugLog.d(TAG, "onDetachedFromEngine: SessionManager cleaned up")
    }

    override fun startSessionWithDevice(request: StartSessionRequest): Boolean {
        val deviceId = request.deviceId
        CastDebugLog.d(TAG, "startSessionWithDevice: Request received for deviceId=$deviceId")

        if (deviceId.isNullOrBlank()) {
            CastDebugLog.w(TAG, "startSessionWithDevice: deviceId is null or blank, cannot start session")
            return false
        }

        // The Cast SDK tears sessions down asynchronously: after
        // endCurrentSession returns, the underlying controller is still being
        // disposed and a new connect started in that window is CANCELED by the
        // SDK. Postpone the route selection when a teardown just happened.
        val sinceEnd = SystemClock.elapsedRealtime() - lastSessionEndAt
        if (sinceEnd < SESSION_END_GRACE_MS) {
            val delay = SESSION_END_GRACE_MS - sinceEnd
            CastDebugLog.d(TAG, "startSessionWithDevice: teardown finished ${sinceEnd}ms ago; delaying route selection by ${delay}ms")
            mainHandler.postDelayed({ discoveryManagerMethodChannel.selectRoute(deviceId) }, delay)
        } else {
            CastDebugLog.d(TAG, "startSessionWithDevice: Selecting route for deviceId=$deviceId via DiscoveryManager")
            discoveryManagerMethodChannel.selectRoute(deviceId)
        }
        CastDebugLog.d(TAG, "startSessionWithDevice: Route selection initiated for deviceId=$deviceId")
        return true
    }

    override fun endSession(): Boolean {
        CastDebugLog.d(TAG, "endSession: Ending current session (without stopping receiver)")
        val currentSession = sessionManager?.currentCastSession
        CastDebugLog.d(TAG, "endSession: currentSession=${currentSession?.sessionId}, device=${currentSession?.castDevice?.friendlyName}")
        sessionManager?.endCurrentSession(false)
        markSessionEnd()
        CastDebugLog.d(TAG, "endSession: endCurrentSession(false) called")
        return true
    }

    override fun endSessionAndStopCasting(): Boolean {
        CastDebugLog.d(TAG, "endSessionAndStopCasting: Ending session AND stopping receiver")
        val currentSession = sessionManager?.currentCastSession
        CastDebugLog.d(TAG, "endSessionAndStopCasting: currentSession=${currentSession?.sessionId}, device=${currentSession?.castDevice?.friendlyName}")
        sessionManager?.endCurrentSession(true)
        markSessionEnd()
        CastDebugLog.d(TAG, "endSessionAndStopCasting: endCurrentSession(true) called")
        return true
    }

    override fun setDeviceVolume(value: Double, muted: Boolean) {
        CastDebugLog.d(TAG, "setDeviceVolume: Setting volume to $value muted=$muted")
        try {
            val session = sessionManager?.currentCastSession
            if (session == null) {
                CastDebugLog.e(TAG, "[SESSION ERROR] setDeviceVolume: no active Cast session")
                return
            }
            // Stage the mute first so onVolumeChanged (or the fallback below)
            // applies it once the receiver has settled the volume change.
            pendingMute = if (session.isMute != muted) muted else null
            session.volume = value
            mainHandler.postDelayed({ applyPendingMute() }, MUTE_SETTLE_MS)
            CastDebugLog.d(TAG, "setDeviceVolume: applied value=$value muted=$muted (pendingMute=$pendingMute)")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "setDeviceVolume(value=$value, muted=$muted)", e)
        }
    }

    // MARK: - Custom Cast Message Channels

    private fun validateNamespace(namespace: String): String {
        if (!namespace.startsWith("urn:x-cast:") || namespace.length > 128) {
            throw FlutterError(
                "INVALID_ARGUMENT",
                "A valid Cast namespace is required.",
                null
            )
        }
        return namespace
    }

    private fun registerMessageChannel(namespace: String): Boolean {
        val session = sessionManager?.currentCastSession ?: return true
        return try {
            session.removeMessageReceivedCallbacks(namespace)
            session.setMessageReceivedCallbacks(namespace, messageReceivedCallback)
            true
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "registerMessageChannel($namespace)", e)
            false
        }
    }

    private fun registerRequestedMessageChannels() {
        requestedMessageNamespaces.forEach(::registerMessageChannel)
    }

    override fun addMessageChannel(namespace: String): Boolean {
        val namespace = validateNamespace(namespace)
        requestedMessageNamespaces.add(namespace)
        return registerMessageChannel(namespace)
    }

    override fun removeMessageChannel(namespace: String): Boolean {
        val namespace = validateNamespace(namespace)
        requestedMessageNamespaces.remove(namespace)
        return try {
            sessionManager?.currentCastSession?.removeMessageReceivedCallbacks(namespace)
            true
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "removeMessageChannel($namespace)", e)
            false
        }
    }

    override suspend fun sendMessage(namespace: String, message: String): Boolean {
        val namespace = validateNamespace(namespace)
        val session = sessionManager?.currentCastSession
        if (session == null || !requestedMessageNamespaces.contains(namespace)) {
            // Runtime state, not a programmer error: report as `false` so the
            // Dart API stays a simple Future<bool>. iOS enforces the same
            // registration requirement via its channel dictionary.
            return false
        }
        return try {
            suspendCancellableCoroutine { continuation ->
                session.sendMessage(namespace, message).setResultCallback { status ->
                    continuation.resume(status.isSuccess)
                }
            }
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "sendMessage($namespace)", e)
            false
        }
    }

    override fun resetSession(): Boolean {
        // Stale sessions are not observed on Android; delegate to the
        // standard end-and-stop-casting flow.
        return endSessionAndStopCasting()
    }

    //SessionManagerLister
    override fun onSessionEnded(session: Session, errorCode: Int) {
        CastDebugLog.sessionEvent(TAG, "onSessionEnded", session.sessionId, (session as? CastSession)?.castDevice?.deviceId, "errorCode=$errorCode")
        if (errorCode == 0) {
            CastDebugLog.d(TAG, "onSessionEnded: Session ended cleanly")
        } else {
            CastDebugLog.e(TAG, "[SESSION ERROR] onSessionEnded: errorCode=$errorCode means: ${describeSessionError(errorCode)}")
        }
        detachVolumeListener(session)
        onSessionChanged()
    }

    override fun onSessionEnding(session: Session) {
        CastDebugLog.sessionEvent(TAG, "onSessionEnding", session.sessionId, (session as? CastSession)?.castDevice?.deviceId)
        detachVolumeListener(session)
        onSessionChanged()
    }

    override fun onSessionResumeFailed(session: Session, errorCode: Int) {
        CastDebugLog.e(TAG, "[SESSION FAILURE] onSessionResumeFailed: errorCode=$errorCode, sessionId=${session.sessionId}")
        CastDebugLog.e(TAG, "[SESSION FAILURE] Device: ${(session as? CastSession)?.castDevice?.friendlyName} (${(session as? CastSession)?.castDevice?.deviceId})")
        CastDebugLog.e(TAG, "[SESSION FAILURE] Error code $errorCode means: ${describeSessionError(errorCode)}")
        CastDebugLog.castError(TAG, "onSessionResumeFailed(errorCode=$errorCode)", null)
        onSessionChanged()
    }

    override fun onSessionResumed(session: Session, wasSuspended: Boolean) {
        CastDebugLog.sessionEvent(TAG, "onSessionResumed", session.sessionId, (session as? CastSession)?.castDevice?.deviceId, "wasSuspended=$wasSuspended")
        CastDebugLog.d(TAG, "onSessionResumed: Starting RemoteMediaClient listener")
        remoteMediaClientMethodChannel.startListen()
        attachVolumeListener(session)
        onSessionChanged()
    }

    override fun onSessionResuming(session: Session, sessionId: String) {
        CastDebugLog.sessionEvent(TAG, "onSessionResuming", sessionId, (session as? CastSession)?.castDevice?.deviceId)
        onSessionChanged()
    }

    override fun onSessionStartFailed(session: Session, errorCode: Int) {
        CastDebugLog.e(TAG, "[SESSION FAILURE] onSessionStartFailed: errorCode=$errorCode, sessionId=${session.sessionId}")
        CastDebugLog.e(TAG, "[SESSION FAILURE] Device: ${(session as? CastSession)?.castDevice?.friendlyName} (${(session as? CastSession)?.castDevice?.deviceId})")
        CastDebugLog.e(TAG, "[SESSION FAILURE] Error code $errorCode means: ${describeSessionError(errorCode)}")
        CastDebugLog.castError(TAG, "onSessionStartFailed(errorCode=$errorCode)", null)
        onSessionChanged()
    }

    override fun onSessionStarted(session: Session, sessionId: String) {
        CastDebugLog.sessionEvent(TAG, "onSessionStarted", sessionId, (session as? CastSession)?.castDevice?.deviceId)
        CastDebugLog.d(TAG, "onSessionStarted: Starting RemoteMediaClient listener")
        remoteMediaClientMethodChannel.startListen()
        attachVolumeListener(session)
        onSessionChanged()
    }

    override fun onSessionStarting(session: Session) {
        CastDebugLog.sessionEvent(TAG, "onSessionStarting", session.sessionId, (session as? CastSession)?.castDevice?.deviceId)
        onSessionChanged()
    }

    override fun onSessionSuspended(session: Session, reason: Int) {
        CastDebugLog.sessionEvent(TAG, "onSessionSuspended", session.sessionId, (session as? CastSession)?.castDevice?.deviceId, "reason=$reason")
        CastDebugLog.d(TAG, "onSessionSuspended: Reason: ${describeSessionSuspendReason(reason)}")
        detachVolumeListener(session)
        onSessionChanged()
    }

    private fun onSessionChanged() {
        val session = sessionManager?.currentCastSession
        val pigeonSession = session?.let { toSessionPigeon(it) }
        CastDebugLog.d(TAG, "onSessionChanged: Sending session state to Flutter - " +
                "hasSession=${session != null}, " +
                "sessionId=${session?.sessionId}, " +
                "isConnected=${session?.isConnected}, " +
                "isConnecting=${session?.isConnecting}, " +
                "device=${session?.castDevice?.friendlyName}")
        eventScope.launch { flutterApi.onSessionChanged(pigeonSession) }
    }

    private fun toSessionPigeon(session: CastSession): CastSessionPigeon {
        val state = when {
            session.isConnected -> ConnectionStatePigeon.CONNECTED
            session.isConnecting -> ConnectionStatePigeon.CONNECTING
            session.isDisconnecting -> ConnectionStatePigeon.DISCONNECTING
            else -> ConnectionStatePigeon.DISCONNECTED
        }

        CastDebugLog.d(TAG, "toSessionPigeon: state=$state, sessionId=${session.sessionId}")

        val castDevice = session.castDevice
        val devicePigeon = castDevice?.let {
            CastDebugLog.d(TAG, "toSessionPigeon: device=${it.friendlyName}, id=${it.deviceId}, model=${it.modelName}, volume=${session.volume}, mute=${session.isMute}")
            CastDevicePigeon(
                deviceId = it.deviceId ?: "",
                friendlyName = it.friendlyName ?: "",
                modelName = it.modelName,
                statusText = null,
                deviceVersion = it.deviceVersion ?: "",
                isOnLocalNetwork = it.isOnLocalNetwork,
                category = "",
                uniqueId = it.deviceId ?: "",
                index = null,
            )
        }

        return CastSessionPigeon(
            device = devicePigeon,
            sessionId = session.sessionId,
            connectionState = state,
            currentDeviceMuted = session.isMute,
            currentDeviceVolume = session.volume,
            deviceStatusText = session.applicationStatus ?: "",
        )
    }

    private fun describeSessionError(errorCode: Int): String {
        return when (errorCode) {
            0 -> "Success"
            1 -> "Operation was canceled"
            2 -> "Connection timed out - device may be unreachable or busy"
            3 -> "General failure - check network connectivity and device availability"
            4 -> "Not connected to Cast device"
            5 -> "Application not found on device - verify receiver app ID is correct"
            6 -> "Invalid request sent to Cast device"
            7 -> "Authentication failed"
            8 -> "Session was replaced by another session"
            9 -> "Authentication error - credentials may be invalid"
            10 -> "Unknown error from Cast SDK"
            11 -> "Network error - device may have lost connectivity"
            13 -> "Remote cast service failed to start"
            14 -> "Cast service creation timed out"
            15 -> "Service connection lost unexpectedly"
            16 -> "API version too old for this operation"
            17 -> "Timeout waiting for device response"
            18 -> "Cast session disconnected unexpectedly"
            19 -> "Application not running on receiver"
            20 -> "Message send failed - session may have ended"
            21 -> "Message send failed due to invalid message"
            22 -> "Device is not on local network"
            23 -> "Operation failed - no active media session"
            24 -> "Remote media client not available"
            else -> "Unknown error code: $errorCode"
        }
    }

    private fun describeSessionSuspendReason(reason: Int): String {
        return when (reason) {
            0 -> "Normal suspension"
            1 -> "Canceled"
            2 -> "Timed out"
            4 -> "Not connected - device may have gone to sleep"
            5 -> "Application not found"
            6 -> "Invalid request"
            7 -> "Authentication failed"
            8 -> "Session replaced by another"
            9 -> "Authentication error"
            11 -> "Network error - device lost connectivity"
            else -> "Unknown suspend reason: $reason"
        }
    }
}
