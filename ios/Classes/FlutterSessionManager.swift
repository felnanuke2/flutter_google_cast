//
//  FlutterSessionManager.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 23/06/22.
//

import Foundation
import GoogleCast

public class FlutterSessionManager : UIResponder, FlutterPlugin{
    
    var channel : FlutterMethodChannel?
    
    private var sessionManager : GCKSessionManager  {
        GCKCastContext.sharedInstance().sessionManager
    }
    
    private var discoveryManager: GCKDiscoveryManager  {
        GCKCastContext.sharedInstance().discoveryManager
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
       
        
        
    }
    
   public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startSessionWithDevice":
        result(startSessionWithDevice(deviceIndex: call.arguments as! Int))
            break
            
        default:
            result(FlutterError(code: "1", message: "No Method Handler", details: nil))
            break
        }
        
        
        
    }
    
    private func startSessionWithDevice(deviceIndex : Int ) -> Bool {
        
        let device = discoveryManager.device(at: UInt(deviceIndex))
        return sessionManager.startSession(with: device)
        
    }
    
    
}
