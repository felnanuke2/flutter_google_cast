import Flutter
import UIKit
import GoogleCast

public class SwiftGoogleCastPlugin:GCKCastContext,GCKDiscoveryManagerListener,GCKLoggerDelegate, FlutterPlugin, UIApplicationDelegate    {
    
    var devices : [UInt : GCKDevice] = [:]
    let kReceiverAppID = kGCKDefaultMediaReceiverApplicationID
    let kDebugLoggingEnabled = true
    private var channel : FlutterMethodChannel?
   
    
    public override var sessionManager: GCKSessionManager {
        GCKCastContext.sharedInstance().sessionManager
    }
    
    public override var discoveryManager: GCKDiscoveryManager{
        GCKCastContext.sharedInstance().discoveryManager
    }
    


    
    
    

    //MARK: - RegisterMethodChannel
  public static func register(with registrar: FlutterPluginRegistrar) {
   
      let instance = SwiftGoogleCastPlugin()
      
      instance.channel = FlutterMethodChannel(name: "google_cast.context", binaryMessenger: registrar.messenger())
    
      registrar.addMethodCallDelegate(instance, channel: instance.channel!)
      FGCSessionManagerMethodChannel.register(with: registrar)
      FGCSessionMethodChannel.register(with: registrar)
      RemoteMediaClienteMethodChannel.register(with: registrar)
      
      
    
  }

    
    //MARK: - FlutterPlugin
  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {

      switch call.method {
      case "setSharedInstanceWithOptions":
          setSharedInstanceWithOption(arguments: call.arguments as! Dictionary<String, Any>, result: result)
          break
      default:
          break
      }

      
  }
    
    
    
    
    private func setSharedInstanceWithOption(arguments: Dictionary<String, Any> ,result: @escaping FlutterResult){
        let option = GCKCastOptions.fromMap(arguments)
        GCKCastContext.setSharedInstanceWith(option)
        GCKLogger.sharedInstance().consoleLoggingEnabled = true
        GCKLogger.sharedInstance().delegate = self
        discoveryManager.add(self)
        sessionManager.add(FGCSessionManagerMethodChannel.instance )
        discoveryManager.startDiscovery()
       
    
    }
    
    
    //MARK: - GCKDiscoveryManagerListener
    
    public func didUpdate(_ device: GCKDevice, at index: UInt) {
        devices[index] = device
    }
    
    public func didInsert(_ device: GCKDevice, at index: UInt) {
        devices[index] = device
    }
    
    public func didRemove(_ device: GCKDevice, at index: UInt) {
        devices.removeValue(forKey: index)
    }
    
    public func didUpdateDeviceList() {
        
        
        channel!.invokeMethod("onDevicesChanged" , arguments:
            devices.map{
                deviceMap -> Dictionary<String , Any> in
            let device = deviceMap.value
            
            var dict =  device.toDict()
            dict["index"] = deviceMap.key
               return dict
                
                
            }
        )
        
    }
    
    
    //MARK: - GCKLoggerDelegate

    public func logMessage(_ message: String,
                      at level: GCKLoggerLevel,
                      fromFunction function: String,
                      location: String) {

          print(function + " - " + message)
        
      }
    
  

    
    
    
    
    
    
}




