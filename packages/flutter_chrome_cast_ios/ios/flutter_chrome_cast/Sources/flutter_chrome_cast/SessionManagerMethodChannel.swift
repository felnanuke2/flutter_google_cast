//
//  SessionManagerMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/06/22.
//

import Flutter
import Foundation
import GoogleCast

/// Flutter method channel for Google Cast session management operations
/// 
/// This class manages Google Cast sessions, handling the connection and disconnection
/// to Cast devices, session state monitoring, and device control operations.
/// It implements the Google Cast session manager listener protocol to receive
/// session-related events and communicates these back to Flutter.
///
/// Key features:
/// - Cast session creation and termination
/// - Session state monitoring and event handling
/// - Device volume control during active sessions
/// - Real-time session updates to Flutter
/// - Singleton pattern for consistent session state
///
/// The class provides a bridge between Flutter's session management API
/// and the native Google Cast SDK session functionality on iOS.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class FGCSessionManagerMethodChannel : UIResponder, FlutterPlugin, GCKSessionManagerListener, SessionManagerHostApi {
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = FGCSessionManagerMethodChannel()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared FGCSessionManagerMethodChannel instance
    static public var instance : FGCSessionManagerMethodChannel{
         _instance
    }
    
    // MARK: - Google Cast Session Properties
    
    /// The current active Cast session (if any)
    /// - Returns: The current session or nil if no session is active
    var currentSession : GCKSession? {
        sessionManager.currentSession
    }
    
    /// The current active Cast session specifically (more specific than currentSession)
    /// - Returns: The current Cast session or nil if no Cast session is active
    var currentCastSession: GCKCastSession? {
        sessionManager.currentCastSession
    }
    
    /// The current connection state of the session manager
    /// - Returns: The connection state (disconnected, connecting, connected, etc.)
    var connectState: GCKConnectionState{
        sessionManager.connectionState
    }
    
    // MARK: - Communication Properties
    
    /// Typed Flutter API for sending session updates.
    private var flutterApi: SessionManagerFlutterApi?
    
    /// Reference to the Google Cast session manager
    /// - Returns: The session manager from the shared Cast context
    private var sessionManager : GCKSessionManager  {
        GCKCastContext.sharedInstance().sessionManager
    }
    
    /// Reference to the Google Cast discovery manager
    /// Used for device selection when starting sessions
    /// - Returns: The discovery manager from the shared Cast context
    private var discoveryManager: GCKDiscoveryManager  {
        GCKCastContext.sharedInstance().discoveryManager
    }
    
    // MARK: - Flutter Plugin Registration
        /// Registers the session manager method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for session management communication.
    /// The channel name is "google_cast.session_manager" and handles all
    /// session-related method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = FGCSessionManagerMethodChannel.instance
        SessionManagerHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        instance.flutterApi = SessionManagerFlutterApi(binaryMessenger: registrar.messenger())
    }
    
    func startSessionWithDevice(request: StartSessionRequest) throws -> Bool {
        if let index = request.deviceIndex {
            return startSessionWithDevice(deviceIndex: Int(index))
        }

        if let deviceId = request.deviceId {
            return startSessionWithDevice(deviceId: deviceId)
        }
        return false
    }

    func endSession() throws -> Bool {
        sessionManager.endSession()
        return true
    }

    func endSessionAndStopCasting() throws -> Bool {
        sessionManager.endSessionAndStopCasting(true)
        return true
    }

    func setDeviceVolume(value: Double) throws {
        setDeviceVolume(NSNumber(value: value))
    }
    
    // MARK: - Cast Session Management Methods
    
    /// Initiates a Cast session with the specified device
    /// 
    /// Attempts to start a Cast session with a device from the discovery list.
    /// The device is identified by its index in the discovery manager's device list.
    ///
    /// - Parameter deviceIndex: The index of the device in the discovery list
    /// - Returns: `true` if session initiation was successful, `false` otherwise
    /// - Note: This method only initiates the session; actual connection status 
    ///         is reported through session manager listener callbacks
    private func startSessionWithDevice(deviceIndex : Int ) -> Bool {
        
        let device = discoveryManager.device(at: UInt(deviceIndex))
        return sessionManager.startSession(with: device)
    }

    private func startSessionWithDevice(deviceId: String) -> Bool {
        let count = discoveryManager.deviceCount
        guard count > 0 else { return false }

        for index in 0..<count {
            let device = discoveryManager.device(at: index)
            if device.deviceID == deviceId {
                return sessionManager.startSession(with: device)
            }
        }

        return false
    }
    
    /// Ends the current Cast session
    /// 
    /// Terminates the active Cast session if one exists. The session will be
    /// gracefully closed, but casting may continue on the receiver device.
    ///
    /// - Parameter result: Flutter result callback for operation status
    private func endSession(_ result : FlutterResult) {
        print(self.sessionManager.endSession())
    }
    
    /// Ends the current session and stops casting on the receiver
    /// 
    /// Terminates the active Cast session and instructs the receiver device
    /// to stop casting entirely. This is more aggressive than `endSession()`.
    ///
    /// - Parameter result: Flutter result callback for operation status
    /// Ends the current session and stops casting on the receiver
    /// 
    /// Terminates the active Cast session and instructs the receiver device
    /// to stop casting entirely. This is more aggressive than `endSession()`.
    ///
    /// - Parameter result: Flutter result callback for operation status
    private func endSessionAndStopCasting(_ result : FlutterResult) {
        print(self.sessionManager.endSessionAndStopCasting(true))
    }
    
    /// Sets the volume level of the connected Cast device
    /// 
    /// Adjusts the volume of the Cast receiver device during an active session.
    /// This controls the device's output volume, not the sender app's volume.
    ///
    /// - Parameter volume: The desired volume level (typically 0.0 to 1.0)
    /// - Note: Only works when there's an active Cast session
    func setDeviceVolume(_ volume : NSNumber){
        sessionManager.currentCastSession?.setDeviceVolume(Float(truncating: volume))
    }
    
    // MARK: - Google Cast Session Manager Listener
    
    /// Called when a session is about to start
    /// 
    /// This delegate method is invoked just before a Cast session begins.
    /// Updates Flutter with the new session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that will start
    public func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        onSessionChanged(session)
    }
    
    /// Called when a session has successfully started
    /// 
    /// This delegate method is invoked after a Cast session has been established.
    /// Notifies Flutter of the new session and starts media client listening.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that started
    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        onSessionChanged(session)
        RemoteMediaClienteMethodChannel.instance.startListen()
    }
    
    /// Called when a Cast session is about to start
    /// 
    /// This delegate method is invoked just before a Cast session begins.
    /// This is the Cast-specific version of willStart for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that will start
    public func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a Cast session fails to start
    /// 
    /// This delegate method is invoked when a Cast session initiation fails.
    /// Updates Flutter with the session state and error information.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that failed to start
    ///   - error: The error that caused the failure
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        onSessionChanged(session)
    }
    
    /// Called when a session is about to end
    /// 
    /// This delegate method is invoked just before a session terminates.
    /// Updates Flutter with the changing session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that will end
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        onSessionChanged(session)
    }
    
    /// Called when a session has ended
    /// 
    /// This delegate method is invoked after a session has been terminated.
    /// Notifies Flutter and stops media client listening.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that ended
    ///   - error: Optional error if the session ended unexpectedly
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        onSessionChanged(session)
        RemoteMediaClienteMethodChannel.instance.onSessionEnd()
    }
    
    /// Called when a Cast session is about to end
    /// 
    /// This delegate method is invoked just before a Cast session terminates.
    /// This is the Cast-specific version of willEnd for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that will end
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a Cast session has ended
    /// 
    /// This delegate method is invoked after a Cast session has been terminated.
    /// Clears the session state in Flutter and stops media client operations.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that ended
    ///   - error: Optional error if the session ended unexpectedly
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        onSessionChanged(nil)
        RemoteMediaClienteMethodChannel.instance.onSessionEnd()
    }
    
    /// Called when a session fails to start
    /// 
    /// This delegate method is invoked when a session initiation fails.
    /// Updates Flutter with the session state and error information.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that failed to start
    ///   - error: The error that caused the failure
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        onSessionChanged(session)
    }
    
    /// Called when a session is suspended
    /// 
    /// This delegate method is invoked when a session is temporarily suspended
    /// (e.g., app goes to background). Clears the session state in Flutter.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that was suspended
    ///   - reason: The reason for the suspension
    public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
            onSessionChanged(nil)
    }
    
    /// Called when a Cast session is suspended
    /// 
    /// This delegate method is invoked when a Cast session is temporarily suspended.
    /// This is the Cast-specific version of didSuspend for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that was suspended
    ///   - reason: The reason for the suspension
    public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
            onSessionChanged(nil)
    }
    
    /// Called when a session is about to resume
    /// 
    /// This delegate method is invoked just before a suspended session resumes.
    /// Updates Flutter with the resuming session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that will resume
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeSession session: GCKSession) {
        onSessionChanged(session)
    }
    
    /// Called when a session has resumed
    /// 
    /// This delegate method is invoked after a suspended session has resumed.
    /// Restarts media client listening and restores session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session that resumed
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        onSessionChanged(session)
        RemoteMediaClienteMethodChannel.instance.startListen()
        RemoteMediaClienteMethodChannel.instance.resumeSession();
    }
    
    /// Called when a Cast session has resumed
    /// 
    /// This delegate method is invoked after a suspended Cast session has resumed.
    /// This is the Cast-specific version of didResumeSession for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that resumed
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a Cast session is about to resume
    /// 
    /// This delegate method is invoked just before a suspended Cast session resumes.
    /// This is the Cast-specific version of willResumeSession for GCKSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session that will resume
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeCastSession session: GCKCastSession) {
        onSessionChanged(session)
    }
    
    /// Called when a device in the session is updated
    /// 
    /// This delegate method is invoked when the Cast device information changes
    /// during an active session (e.g., device name change).
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session containing the updated device
    ///   - device: The updated device information
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didUpdate device: GCKDevice) {
        onSessionChanged(session)
    }
    
    /// Called when device volume changes
    /// 
    /// This delegate method is invoked when the Cast device's volume or mute
    /// state changes. Updates Flutter with the new session state.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session with volume changes
    ///   - volume: The new volume level (0.0 to 1.0)
    ///   - muted: Whether the device is muted
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        onSessionChanged(session)
    }
    
    /// Called when Cast device volume changes
    /// 
    /// This delegate method is invoked when the Cast device's volume or mute
    /// state changes. This is the Cast-specific version for GCKCastSession.
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The Cast session with volume changes
    ///   - volume: The new volume level (0.0 to 1.0)
    ///   - muted: Whether the device is muted
    public func sessionManager(_ sessionManager: GCKSessionManager, castSession session: GCKCastSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        onSessionChanged(session)
    }
    
    /// Called when device status changes
    /// 
    /// This delegate method is invoked when the Cast device reports a status
    /// text change (e.g., "Ready to cast", media title, etc.).
    ///
    /// - Parameters:
    ///   - sessionManager: The session manager instance
    ///   - session: The session with status changes
    ///   - statusText: The new status text from the device
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceStatus statusText: String?) {
        onSessionChanged(session)
    }

    // MARK: - Helper Methods
    
    /// Notifies Flutter of session state changes
    /// 
    /// This helper method sends session updates to the Flutter side via
    /// the method channel. It converts the session object to a dictionary
    /// format suitable for Flutter consumption.
    ///
    /// - Parameter session: The session that changed, or nil if session ended
    private func onSessionChanged(_ session : GCKSession?){
        flutterApi?.onSessionChanged(session: toSessionPigeon(session)) { _ in }
    }

    private func toSessionPigeon(_ session: GCKSession?) -> CastSessionPigeon? {
        guard let session else { return nil }

        let state: ConnectionStatePigeon
        switch sessionManager.connectionState {
        case .connected:
            state = .connected
        case .connecting:
            state = .connecting
        case .disconnecting:
            state = .disconnecting
        default:
            state = .disconnected
        }

        let castDevice = session.device
        let device = CastDevicePigeon(
            deviceId: castDevice.deviceID ?? "",
            friendlyName: castDevice.friendlyName ?? "",
            modelName: castDevice.modelName,
            statusText: castDevice.statusText,
            deviceVersion: castDevice.deviceVersion ?? "",
            isOnLocalNetwork: castDevice.isOnLocalNetwork,
            category: castDevice.category ?? "",
            uniqueId: castDevice.uniqueID ?? "",
            index: nil
        )

        return CastSessionPigeon(
            device: device,
            sessionId: session.sessionID,
            connectionState: state,
            currentDeviceMuted: currentCastSession?.currentDeviceMuted ?? false,
            currentDeviceVolume: Double(currentCastSession?.currentDeviceVolume ?? 0),
            deviceStatusText: currentCastSession?.deviceStatusText ?? ""
        )
    }
    
}
