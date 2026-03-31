package com.felnanuke.google_cast

import com.felnanuke.google_cast.pigeon.CastDevicePigeon
import com.felnanuke.google_cast.pigeon.CastSessionPigeon
import com.felnanuke.google_cast.pigeon.ConnectionStatePigeon
import com.felnanuke.google_cast.pigeon.SessionManagerFlutterApi
import com.felnanuke.google_cast.pigeon.SessionManagerHostApi
import com.felnanuke.google_cast.pigeon.StartSessionRequest
import com.google.android.gms.cast.framework.*
import io.flutter.embedding.engine.plugins.FlutterPlugin

/**
 * Tag for logging session manager operations
 */
private const val TAG = "SessionManager"

/**
 * Flutter method channel for Google Cast session management
 * 
 * This class manages the complete lifecycle of Google Cast sessions, including session
 * creation, connection, monitoring, and termination. It implements the Google Cast
 * SessionManagerListener to receive session events and communicates session state
 * changes to Flutter in real-time.
 *
 * Key responsibilities:
 * - Cast session lifecycle management (creation, connection, termination)
 * - Session state monitoring and event handling
 * - Device volume control during active sessions
 * - Integration with discovery manager for device selection
 * - Coordination with remote media client for media operations
 * - Real-time session updates to Flutter
 *
 * Architecture:
 * The class integrates with multiple Cast SDK components:
 * - SessionManager: Core Google Cast SDK session management
 * - DiscoveryManagerMethodChannel: For device selection during session creation
 * - RemoteMediaClientMethodChannel: For media operations during active sessions
 * - Session events are propagated to Flutter for UI updates
 *
 * Session Lifecycle:
 * 1. Session creation request from Flutter with device ID
 * 2. Device selection via discovery manager
 * 3. Session connection and status monitoring
 * 4. Session state synchronization with Flutter
 * 5. Session termination and cleanup
 *
 * @param discoveryManager Reference to discovery manager for device operations
 * @author LUIZ FELIPE ALVES LIMA
 * @since Android API 21 (Android 5.0)
 */
class SessionManagerMethodChannel(discoveryManager: DiscoveryManagerMethodChannel) : FlutterPlugin,
    SessionManagerHostApi, SessionManagerListener<Session> {

    /**
     * Flutter method channel for session management communication
     * 
     * Handles method calls related to Cast session operations and sends
     * session state updates to Flutter. Channel name:
     * "com.felnanuke.google_cast.session_manager"
     */
    private lateinit var flutterApi: SessionManagerFlutterApi
    
    /**
     * Reference to discovery manager for device selection
     * 
     * Used during session creation to select and connect to specific Cast
     * devices identified by their device ID. Provides the bridge between
     * device discovery and session establishment.
     */
    private val discoveryManagerMethodChannel: DiscoveryManagerMethodChannel = discoveryManager
    
    /**
     * Remote media client method channel for media operations
     * 
     * Handles all media-related operations during active Cast sessions,
     * including media loading, playback control, and media state monitoring.
     * Automatically initialized and managed by the session manager.
     */
    private val remoteMediaClientMethodChannel = RemoteMediaClientMethodChannel()

    /**
     * Google Cast session manager instance
     * 
     * Provides access to the current Cast session manager from the Google Cast
     * SDK. Used for all session lifecycle operations and state queries.
     * 
     * @return The current session manager instance, or null if Cast context not initialized
     */
    private val sessionManager: SessionManager?
        get() {
            return CastContext.getSharedInstance()?.sessionManager
        }

    // MARK: - Flutter Plugin Lifecycle

    /**
     * Called when the Flutter plugin is attached to the Flutter engine
     * 
     * Initializes the session manager method channel and sets up the remote
     * media client for media operations during Cast sessions.
     *
     * Setup operations:
     * - Creates the session manager method channel
     * - Registers this class as the method call handler
     * - Initializes the remote media client method channel
     * - Prepares session management infrastructure
     *
     * @param binding Flutter plugin binding providing access to engine resources
     */
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SessionManagerHostApi.setUp(binding.binaryMessenger, this)
        flutterApi = SessionManagerFlutterApi(binding.binaryMessenger)
        remoteMediaClientMethodChannel.onAttachedToEngine(binding)
    }

    /**
     * Called when the Flutter plugin is detached from the Flutter engine
     * 
     * Performs cleanup of session manager resources to prevent memory leaks.
     *
     * Cleanup operations:
     * - Removes method call handler from the channel
     * - Stops session monitoring
     * - Releases session-related resources
     *
     * @param binding Flutter plugin binding being detached
     */
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        SessionManagerHostApi.setUp(binding.binaryMessenger, null)
    }

    override fun startSessionWithDevice(request: StartSessionRequest): Boolean {
        val deviceId = request.deviceId
        if (deviceId.isNullOrBlank()) return false
        discoveryManagerMethodChannel.selectRoute(deviceId)
        return true
    }

    override fun endSession(): Boolean {
        sessionManager?.endCurrentSession(false)
        return true
    }

    override fun endSessionAndStopCasting(): Boolean {
        sessionManager?.endCurrentSession(true)
        return true
    }

    override fun setDeviceVolume(value: Double) {
        sessionManager?.currentCastSession?.volume = value
    }

    /**
     * Initiates a Cast session with the specified device
     * 
     * Starts a new Cast session by selecting the target device through the
     * discovery manager and initiating the connection process. The actual
     * session connection status is reported through session manager listener
     * callbacks.
     *
     * @param arguments The device ID as a String for the target Cast device
     * @param result Flutter result callback to indicate session initiation status
     */
    //SessionManagerLister
    override fun onSessionEnded(session: Session, p1: Int) {
        onSessionChanged()
    }

    override fun onSessionEnding(p0: Session) {
        onSessionChanged()
    }

    override fun onSessionResumeFailed(p0: Session, p1: Int) {

        onSessionChanged()
    }

    override fun onSessionResumed(p0: Session, p1: Boolean) {
        remoteMediaClientMethodChannel.startListen()
        onSessionChanged()
    }

    override fun onSessionResuming(p0: Session, p1: String) {
        onSessionChanged()
    }

    override fun onSessionStartFailed(p0: Session, p1: Int) {
        onSessionChanged()
    }

    override fun onSessionStarted(session: Session, p1: String) {
        remoteMediaClientMethodChannel.startListen()
        onSessionChanged()
    }

    override fun onSessionStarting(p0: Session) {
        onSessionChanged()
    }

    override fun onSessionSuspended(p0: Session, p1: Int) {
        onSessionChanged()
    }


    private fun onSessionChanged() {
        val session = sessionManager?.currentCastSession
        flutterApi.onSessionChanged(session?.let { toSessionPigeon(it) }) { }
    }

    private fun toSessionPigeon(session: CastSession): CastSessionPigeon {
        val state = when {
            session.isConnected -> ConnectionStatePigeon.CONNECTED
            session.isConnecting -> ConnectionStatePigeon.CONNECTING
            session.isDisconnecting -> ConnectionStatePigeon.DISCONNECTING
            else -> ConnectionStatePigeon.DISCONNECTED
        }

        val castDevice = session.castDevice
        val devicePigeon = castDevice?.let {
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


}