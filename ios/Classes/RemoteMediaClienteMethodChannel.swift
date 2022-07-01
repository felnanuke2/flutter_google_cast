//
//  RemoteMediaClienteMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

class RemoteMediaClienteMethodChannel :UIResponder, FlutterPlugin, GCKRemoteMediaClientListener {
    private override init() {
        
    }
    
    static private let _instance = RemoteMediaClienteMethodChannel()
    static var instance : RemoteMediaClienteMethodChannel {
        _instance
    }
    
    var channel : FlutterMethodChannel?
    
    private var currentRemoteMediaCliente: GCKRemoteMediaClient? {
        GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient
        
    }
    
    private  var positionTimer: Timer?
    
    
    
    
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = RemoteMediaClienteMethodChannel.instance
        
        instance.channel = FlutterMethodChannel(name: "google_cast.remote_media_client", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
        
        
    }
    
    
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        
        
        switch call.method {
        case "loadMedia":
            loadMedia(call.arguments as! Dictionary<String,Any>,result: result)
            break
        case "queueLoadItems":
            queueLoadItem(call.arguments as! Dictionary, result: result)
            break
        case "stop":
            stop(result)
            break
        case "play":
            play(result)
            break
        case "pause":
            pause(result)
            break
        case "setActiveTrackIDs":
            setActiveTrackIDs(result, call.arguments as! [NSNumber])
            break
        case "seek":
            seek(result, call.arguments as! Dictionary<String, Any>)
            break
        case "queueNextItem":
            queueNextItem(result)
            break
        case "queuePrevItem":
            queuePreviousItem(result)
            break
        default:
            break
        }
        
        
    }
    
    private func queuInserItems(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        currentRemoteMediaCliente?.queueInsert(<#T##queueItems: [GCKMediaQueueItem]##[GCKMediaQueueItem]#>, beforeItemWithID: 100)
    }
    
    private func queueLoadItem(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemsDict = arguments["items"] as! [Dictionary<String, Any>]
        let items = itemsDict.map{
            map in
            GCKMediaQueueItem.fromMap(map)
        }
        var options : GCKMediaQueueLoadOptions?
        if let optionsDict = arguments["options"] as? Dictionary<String, Any> {
          
            options = GCKMediaQueueLoadOptions.fromMap(optionsDict)
        }
        print("\(options)")
        let request =  currentRemoteMediaCliente?.queueLoad(items, with: options ?? GCKMediaQueueLoadOptions.init() )
        result(request?.toMap())
    }
    
    private  func loadMedia(_ arguments : Dictionary<String,Any>, result : FlutterResult )  {
        guard let mediaInfo = GCKMediaInformation.fromMap(arguments) else {
            
            result(FlutterError.init(code: "1", message:"fail to generate media info", details: nil))
            return
            
        }
        
       
        
        let options = GCKMediaLoadOptions.init()
        if let autoPlay = arguments["autoPlay"] as? Bool {
            options.autoplay = autoPlay
        }
        if let playPosition = arguments["playPosition"] as? TimeInterval {
            options.playPosition = playPosition
        }

        if let playbackRate = arguments["playbackRate"] as? Float {
            options.playbackRate = playbackRate
        }
        if let activeTrackIds = arguments["activeTrackIds"] as? [NSNumber] {
            options.activeTrackIDs = activeTrackIds
        }
        if let credentialType = arguments["credentialsType"] as? String {
            options.credentialsType = credentialType
        }
        if let credentials = arguments["credentials"] as? String {
            options.credentials = credentials
        }
        print("\(options)")
        let request = currentRemoteMediaCliente?.loadMedia(mediaInfo,with:  options)
        result(request?.toMap())
        
        
    }
    
    private func pause(_ result : FlutterResult){
        let request =  currentRemoteMediaCliente?.pause()
        result(  request?.toMap() )
        
        
    }
    
    private func stop(_ result : FlutterResult){
        
        let request =  currentRemoteMediaCliente?.stop()
        result(  request?.toMap() )
        
        
    }
    
    private func play(_ result : FlutterResult){
        let request =  currentRemoteMediaCliente?.play()
        result(  request?.toMap() )
        
        
    }
    
    private func setActiveTrackIDs(_ result : FlutterResult, _ args : [NSNumber] ){
        let request =  currentRemoteMediaCliente?.setActiveTrackIDs(args)
        result(request?.toMap())
    }
    
    private func seek(_ result : FlutterResult, _ args : Dictionary<String, Any>){
        let request =  currentRemoteMediaCliente?.seek(with: GCKMediaSeekOptions.fromMap(args: args))
        result(request?.toMap())
    }
    
    private func queueNextItem(_ result : FlutterResult){
        let request =  currentRemoteMediaCliente?.queueNextItem()
        result(request?.toMap())
    }
    
    private func queuePreviousItem(_ result : FlutterResult){
        let request =  currentRemoteMediaCliente?.queuePreviousItem()
        result(request?.toMap())
    }
    
    public func startListen(){
        currentRemoteMediaCliente?.add(self)
    }
    
    
    //MARK: - GCKRemoteMediaClientListener
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceiveQueueItemIDs queueItemIDs: [NSNumber]) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        self.positionTimer?.invalidate()
        self.positionTimer = nil
        self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            self.channel?.invokeMethod("onUpdatePlayerPosition", arguments: Int(client.approximateStreamPosition()))
        }
        channel?.invokeMethod("onUpdateMediaStatus", arguments: mediaStatus?.toMap())
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaMetadata: GCKMediaMetadata?) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceive queueItems: [GCKMediaQueueItem]) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didRemoveQueueItemsWithIDs queueItemIDs: [NSNumber]) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdateQueueItemsWithIDs queueItemIDs: [NSNumber]) {
        
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didInsertQueueItemsWithIDs queueItemIDs: [NSNumber], beforeItemWithID beforeItemID: UInt) {
        
    }
}
