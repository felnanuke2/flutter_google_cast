package com.felnanuke.google_cast

import com.felnanuke.google_cast.extensions.toMap
import com.google.android.gms.cast.Cast
import com.google.android.gms.cast.framework.*
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

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
    MethodChannel.MethodCallHandler, SessionManagerListener<Session> {

    /**
     * Flutter method channel for session management communication
     * 
     * Handles method calls related to Cast session operations and sends
     * session state updates to Flutter. Channel name:
     * "com.felnanuke.google_cast.session_manager"
     */
    private lateinit var channel: MethodChannel
    
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

    /** Namespaces requested by Flutter. They survive Cast session changes. */
    private val requestedMessageNamespaces = mutableSetOf<String>()

    /** Forwards receiver text messages to the Dart message stream. */
    private val messageReceivedCallback = Cast.MessageReceivedCallback { _, namespace, message ->
        channel.invokeMethod(
            "onMessageReceived",
            mapOf("namespace" to namespace, "message" to message)
        )
    }

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
        channel =
            MethodChannel(binding.binaryMessenger, "com.felnanuke.google_cast.session_manager")
        channel.setMethodCallHandler(this)
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
        channel.setMethodCallHandler(null)
        remoteMediaClientMethodChannel.onDetachedFromEngine(binding)
    }

    /**
     * Handles method calls from the Flutter side
     * 
     * Processes incoming method calls for Cast session management operations.
     * Manages session lifecycle and device control during active sessions.
     *
     * Supported methods:
     * - `startSessionWithDeviceId`: Initiates a Cast session with specified device
     * - `endSessionAndStopCasting`: Terminates session and stops casting on receiver
     * - `endSession`: Ends the current session gracefully
     * - `setStreamVolume`: Adjusts the volume of the Cast device
     *
     * @param call The method call from Flutter containing method name and arguments
     * @param result The result callback to return responses to Flutter
     */
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSessionWithDeviceId" -> startSession(call.arguments, result)
            "endSessionAndStopCasting" -> {
                sessionManager?.endCurrentSession(true)
                result.success(true)
            }
            "endSession" -> {
                sessionManager?.endCurrentSession(false)
                result.success(true)
            }
            "setStreamVolume" -> {
                sessionManager?.currentCastSession?.volume = call.arguments as Double
                result.success(true)
            }
            "addMessageChannel" -> addMessageChannel(call.arguments, result)
            "removeMessageChannel" -> removeMessageChannel(call.arguments, result)
            "sendMessage" -> sendMessage(call.arguments, result)
            else -> result.notImplemented()
        }
    }

    private fun messageArguments(arguments: Any?): Pair<String, String?>? {
        val map = arguments as? Map<*, *> ?: return null
        val namespace = map["namespace"] as? String ?: return null
        if (!namespace.startsWith("urn:x-cast:") || namespace.length > 128) return null
        return namespace to (map["message"] as? String)
    }

    private fun registerMessageChannel(namespace: String): Boolean {
        val session = sessionManager?.currentCastSession ?: return true
        return try {
            session.removeMessageReceivedCallbacks(namespace)
            session.setMessageReceivedCallbacks(namespace, messageReceivedCallback)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun registerRequestedMessageChannels() {
        requestedMessageNamespaces.forEach(::registerMessageChannel)
    }

    private fun addMessageChannel(arguments: Any?, result: MethodChannel.Result) {
        val parsed = messageArguments(arguments)
        if (parsed == null) {
            result.error("INVALID_ARGUMENT", "A valid Cast namespace is required.", null)
            return
        }
        requestedMessageNamespaces.add(parsed.first)
        result.success(registerMessageChannel(parsed.first))
    }

    private fun removeMessageChannel(arguments: Any?, result: MethodChannel.Result) {
        val parsed = messageArguments(arguments)
        if (parsed == null) {
            result.error("INVALID_ARGUMENT", "A valid Cast namespace is required.", null)
            return
        }
        requestedMessageNamespaces.remove(parsed.first)
        try {
            sessionManager?.currentCastSession?.removeMessageReceivedCallbacks(parsed.first)
            result.success(true)
        } catch (_: Exception) {
            result.success(false)
        }
    }

    private fun sendMessage(arguments: Any?, result: MethodChannel.Result) {
        val parsed = messageArguments(arguments)
        if (parsed == null) {
            result.error("INVALID_ARGUMENT", "A valid Cast namespace is required.", null)
            return
        }
        val message = parsed.second
        val session = sessionManager?.currentCastSession
        if (message == null || session == null ||
            !requestedMessageNamespaces.contains(parsed.first)
        ) {
            // Runtime state, not a programmer error: report as `false` so the
            // Dart API stays a simple Future<bool>. iOS enforces the same
            // registration requirement via its channel dictionary.
            result.success(false)
            return
        }
        try {
            session.sendMessage(parsed.first, message).setResultCallback { status ->
                result.success(status.isSuccess)
            }
        } catch (_: Exception) {
            result.success(false)
        }
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
    private fun startSession(arguments: Any?, result: MethodChannel.Result) {
        val deviceId = arguments as String
        discoveryManagerMethodChannel.selectRoute(deviceId)
        result.success(true)
    }


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
        registerRequestedMessageChannels()
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
        registerRequestedMessageChannels()
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
        val map = session?.toMap()
        channel.invokeMethod("onSessionChanged", map)
    }


}
