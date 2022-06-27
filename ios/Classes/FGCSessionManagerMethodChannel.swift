//
//  FlutterSessionManager.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/06/22.
//

import Foundation
import GoogleCast

public class FGCSessionManagerMethodChannel : UIResponder, FlutterPlugin, GCKSessionManagerListener {
    
    private override init() {
        
    }
    static private let _instance = FGCSessionManagerMethodChannel()
    
    static public var instance : FGCSessionManagerMethodChannel{
         _instance
    }
    
    
    //MARK: - SessionManagerVars
    
    var currentSession : GCKSession? {
        sessionManager.currentSession
    }
    
    var currentCastSession: GCKCastSession? {
        sessionManager.currentCastSession
    }
    
    var connectState: GCKConnectionState{
        sessionManager.connectionState
    }
    
    
    var channel : FlutterMethodChannel?
    
    private var sessionManager : GCKSessionManager  {
        GCKCastContext.sharedInstance().sessionManager
    }
    
    private var discoveryManager: GCKDiscoveryManager  {
        GCKCastContext.sharedInstance().discoveryManager
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = FGCSessionManagerMethodChannel.instance
        
        instance.channel =  FlutterMethodChannel(name: "google_cast.session_manager", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)

        
    }
    
   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startSessionWithDevice":
            
        result(startSessionWithDevice(deviceIndex: call.arguments as! Int))
            
           
            
   
            
        default:
            result(FlutterError(code: "1", message: "No Method Handler", details: nil))
            break
        }
        
        
        
    }
    
    //MARK: -  GCKSessionManager
    
    private func startSessionWithDevice(deviceIndex : Int ) -> Bool {
        
        let device = discoveryManager.device(at: UInt(deviceIndex))
        return sessionManager.startSession(with: device)
        
        
        
    }
    
    //MARK: -GCKSessionManagerListener
    

    
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKSession) {
        
        onSessionChanged(session)
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKSession) {
        onSessionChanged(session)
        
    }
    
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willStart session: GCKCastSession) {
        
    }
    
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKSession) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKSession, withError error: Error?) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKSession, withError error: Error) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKSession, with reason: GCKConnectionSuspendReason) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didSuspend session: GCKCastSession, with reason: GCKConnectionSuspendReason) {
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeSession session: GCKSession) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeSession session: GCKSession) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, willResumeCastSession session: GCKCastSession) {
        
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didUpdate device: GCKDevice) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        onSessionChanged(session)
        
    }
    
    
    public func sessionManager(_ sessionManager: GCKSessionManager, castSession session: GCKCastSession, didReceiveDeviceVolume volume: Float, muted: Bool) {
        onSessionChanged(session)
    }
    
    
    public func sessionManager(_ sessionManager: GCKSessionManager, session: GCKSession, didReceiveDeviceStatus statusText: String?) {
        onSessionChanged(session)
    }
    
    public func sessionManager(_ sessionManager: GCKSessionManager, castSession session: GCKCastSession, didReceiveDeviceStatus statusText: String?) {
        
    }
    
    
    public func sessionManager(_ sessionManager: GCKSessionManager, didUpdateDefaultSessionOptionsForDeviceCategory category: String) {
        
    }
    
    
    private func onSessionChanged(_ session : GCKSession){
        channel?.invokeMethod("onCurrentSessionChanged", arguments: session.toDict())
    }
}
