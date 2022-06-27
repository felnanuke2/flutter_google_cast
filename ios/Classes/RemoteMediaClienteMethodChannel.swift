//
//  RemoteMediaClienteMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

class RemoteMediaClienteMethodChannel :UIResponder, FlutterPlugin {
    
    var channel : FlutterMethodChannel?
    
    private var currentRemoteMediaCliente: GCKRemoteMediaClient? {
        GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient
    }
    
    
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = RemoteMediaClienteMethodChannel()
        
        instance.channel = FlutterMethodChannel(name: "google_cast.remote_media_client", binaryMessenger: registrar.messenger())
        
        
      
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        
        
        
        
        
    }
    
    
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        
        
        switch call.method {
        case "loadMedia":
            loadMedia(call.arguments as! Dictionary<String,Any>,result: result)
           
            break
        default:
            break
        }
        
        
    }
    
    
    func loadMedia(_ arguments : Dictionary<String,Any>, result : FlutterResult )  {
        guard let mediaInfo = GCKMediaInformation.fromMap(arguments) else {
            
            result(FlutterError.init(code: "1", message:"fail to generate media info", details: nil))
            return
            
        }
        
        
        let request = currentRemoteMediaCliente?.loadMedia(mediaInfo)
      
  
        result(request?.toMap())
        
        
    }
    
    
}
