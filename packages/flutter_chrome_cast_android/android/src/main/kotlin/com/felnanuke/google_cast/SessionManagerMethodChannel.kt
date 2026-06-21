package com.felnanuke.google_cast

import com.felnanuke.google_cast.pigeon.CastDevicePigeon
import com.felnanuke.google_cast.pigeon.CastSessionPigeon
import com.felnanuke.google_cast.pigeon.ConnectionStatePigeon
import com.felnanuke.google_cast.pigeon.SessionManagerFlutterApi
import com.felnanuke.google_cast.pigeon.SessionManagerHostApi
import com.felnanuke.google_cast.pigeon.StartSessionRequest
import com.google.android.gms.cast.framework.*
import io.flutter.embedding.engine.plugins.FlutterPlugin

private const val TAG = "SessionManager"

class SessionManagerMethodChannel(discoveryManager: DiscoveryManagerMethodChannel) : FlutterPlugin,
    SessionManagerHostApi, SessionManagerListener<Session> {

    private lateinit var flutterApi: SessionManagerFlutterApi

    private val discoveryManagerMethodChannel: DiscoveryManagerMethodChannel = discoveryManager

    private val remoteMediaClientMethodChannel = RemoteMediaClientMethodChannel()

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

        CastDebugLog.d(TAG, "startSessionWithDevice: Selecting route for deviceId=$deviceId via DiscoveryManager")
        discoveryManagerMethodChannel.selectRoute(deviceId)
        CastDebugLog.d(TAG, "startSessionWithDevice: Route selection initiated for deviceId=$deviceId")
        return true
    }

    override fun endSession(): Boolean {
        CastDebugLog.d(TAG, "endSession: Ending current session (without stopping receiver)")
        val currentSession = sessionManager?.currentCastSession
        CastDebugLog.d(TAG, "endSession: currentSession=${currentSession?.sessionId}, device=${currentSession?.castDevice?.friendlyName}")
        sessionManager?.endCurrentSession(false)
        CastDebugLog.d(TAG, "endSession: endCurrentSession(false) called")
        return true
    }

    override fun endSessionAndStopCasting(): Boolean {
        CastDebugLog.d(TAG, "endSessionAndStopCasting: Ending session AND stopping receiver")
        val currentSession = sessionManager?.currentCastSession
        CastDebugLog.d(TAG, "endSessionAndStopCasting: currentSession=${currentSession?.sessionId}, device=${currentSession?.castDevice?.friendlyName}")
        sessionManager?.endCurrentSession(true)
        CastDebugLog.d(TAG, "endSessionAndStopCasting: endCurrentSession(true) called")
        return true
    }

    override fun setDeviceVolume(value: Double) {
        CastDebugLog.d(TAG, "setDeviceVolume: Setting volume to $value")
        try {
            sessionManager?.currentCastSession?.volume = value
            CastDebugLog.d(TAG, "setDeviceVolume: Volume set successfully to $value")
        } catch (e: Exception) {
            CastDebugLog.castError(TAG, "setDeviceVolume(value=$value)", e)
        }
    }

    //SessionManagerLister
    override fun onSessionEnded(session: Session, errorCode: Int) {
        CastDebugLog.sessionEvent(TAG, "onSessionEnded", session.sessionId, (session as? CastSession)?.castDevice?.deviceId, "errorCode=$errorCode")
        CastDebugLog.d(TAG, "onSessionEnded: Session ended cleanly, errorCode=$errorCode")
        onSessionChanged()
    }

    override fun onSessionEnding(session: Session) {
        CastDebugLog.sessionEvent(TAG, "onSessionEnding", session.sessionId, (session as? CastSession)?.castDevice?.deviceId)
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
        onSessionChanged()
    }

    override fun onSessionStarting(session: Session) {
        CastDebugLog.sessionEvent(TAG, "onSessionStarting", session.sessionId, (session as? CastSession)?.castDevice?.deviceId)
        onSessionChanged()
    }

    override fun onSessionSuspended(session: Session, reason: Int) {
        CastDebugLog.sessionEvent(TAG, "onSessionSuspended", session.sessionId, (session as? CastSession)?.castDevice?.deviceId, "reason=$reason")
        CastDebugLog.d(TAG, "onSessionSuspended: Reason: ${describeSessionSuspendReason(reason)}")
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
        flutterApi.onSessionChanged(pigeonSession) { }
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
