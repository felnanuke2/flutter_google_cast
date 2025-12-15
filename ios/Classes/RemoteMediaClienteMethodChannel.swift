//
//  RemoteMediaClientMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Foundation
import GoogleCast

/// Flutter method channel for Google Cast remote media client operations
/// 
/// This class manages all media-related operations for Google Cast sessions,
/// including media loading, playback control, queue management, and status monitoring.
/// It implements the Google Cast remote media client listener protocol to receive
/// media state updates and communicates these back to Flutter.
///
/// Key features:
/// - Media loading and queue management
/// - Playback controls (play, pause, stop, seek)
/// - Volume and track controls
/// - Real-time media status updates to Flutter
/// - Position tracking with automatic updates
/// - Singleton pattern for consistent media state
///
/// The class maintains internal state for queue management and provides
/// comprehensive media control capabilities to the Flutter application.
///
/// - Author: LUIZ FELIPE ALVES LIMA
/// - Since: iOS 10.0+
class RemoteMediaClienteMethodChannel :UIResponder, FlutterPlugin, GCKRemoteMediaClientListener{
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = RemoteMediaClienteMethodChannel()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared RemoteMediaClienteMethodChannel instance
    static var instance : RemoteMediaClienteMethodChannel {
        _instance
    }
    
    // MARK: - Properties
    
    /// Flutter method channel for remote media client communication
    /// Used to send media events and handle method calls from Flutter
    var channel : FlutterMethodChannel?
    
    /// Reference to the current Cast session's remote media client
    /// - Returns: The media client for the current session, or nil if no session
    private var currentRemoteMediaCliente: GCKRemoteMediaClient? {
        GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient
    }
    
    /// Timer for tracking media position updates
    /// Automatically sends position updates to Flutter during playback
    private  var positionTimer: Timer?
    
    /// Array maintaining the order of queue items
    /// Stores NSNumber IDs representing the queue item order
    private var queueOrder : [NSNumber] = []
    
    /// Dictionary storing queue items by their ID
    /// Maps queue item IDs to their corresponding GCKMediaQueueItem objects
    private var queueItems  : Dictionary<UInt, GCKMediaQueueItem> = [:]
    
    /// Computed property returning queue items in proper order
    /// - Returns: Array of queue items sorted according to queueOrder
    private var orderedQueueItems : Array<GCKMediaQueueItem> {
        var items : [GCKMediaQueueItem] = []
        
        for queueItemId in queueOrder {
            if let value = queueItems[UInt(truncating: queueItemId)] {
                items.append(value)
            }
        }
        return items
    }
    
    // MARK: - Flutter Plugin Registration
    
    
    /// Registers the remote media client method channel with Flutter
    /// 
    /// Sets up the Flutter method channel for media control communication.
    /// The channel name is "google_cast.remote_media_client" and handles all
    /// media-related method calls from Flutter.
    ///
    /// - Parameter registrar: The Flutter plugin registrar for method channel setup
    static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = RemoteMediaClienteMethodChannel.instance
        
        instance.channel = FlutterMethodChannel(name: "google_cast.remote_media_client", binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(instance, channel: instance.channel!)
    }
    
    // MARK: - Flutter Method Call Handling
    
    /// Handles method calls from the Flutter side
    /// 
    /// Processes incoming method calls for media control operations.
    /// Supports comprehensive media management including loading, playback control,
    /// queue management, and track selection.
    ///
    /// Supported methods:
    /// - `loadMedia`: Load a single media item
    /// - `queueLoadItems`: Load multiple items into a queue
    /// - `stop`: Stop media playback
    /// - `play`: Start or resume playback
    /// - `pause`: Pause playback
    /// - `setActiveTrackIDs`: Select specific media tracks
    /// - And many more media control operations...
    ///
    /// - Parameters:
    ///   - call: The Flutter method call containing method name and arguments
    ///   - result: Callback to return results or errors to Flutter
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
        case "queueInsertItems":
            queueInsertItems(call.arguments as! Dictionary<String, Any>, result:result)
            break
        case "queueInsertItemAndPlay":
            queueInsertItemAndPlay(call.arguments as! Dictionary<String, Any>, result:result)
            break
        case "queueJumpToItemWithId":
            queueJumpToItemWithId(call.arguments as! UInt, result: result)
            break
        case "queueReorderItems":
            queueReorderItems(call.arguments as! Dictionary<String,Any?>, result: result)
            break;
       
        default:
            break
        }
        
        
    }
    
    
    func queueReorderItems(_ arguments : Dictionary<String,Any?>, result: FlutterResult){
        let itemIds = arguments["itemsIds"] as! [NSNumber]
        let beforeItemIds = arguments["beforeItemWithId"] as! UInt
        currentRemoteMediaCliente?.queueReorderItems(withIDs: itemIds, insertBeforeItemWithID: beforeItemIds)
    }
    
    func queueJumpToItemWithId(_ id: UInt, result: FlutterResult){
        currentRemoteMediaCliente?.queueJumpToItem(withID: id)
        result(true)
    }
    
    
    private func queueInsertItemAndPlay(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemDict = arguments["item"] as! Dictionary<String,Any>
        let beforItemWithId = arguments["beforeItemWithId"] as! UInt
        guard let item = GCKMediaQueueItem.fromMap(itemDict) else {
            result(FlutterError(code: "INVALID_ARGUMENT", message: "Invalid item", details: nil))
            return
        }
        let request =  currentRemoteMediaCliente?.queueInsertAndPlay(item, beforeItemWithID: beforItemWithId)
        result(request?.toMap())
    }
    
    private func queueInsertItems(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemsDict = arguments["items"] as! [Dictionary<String,Any>]
        let beforItemWithId = arguments["beforeItemWithId"] as? UInt
        let items = itemsDict.compactMap{
            dict in
            GCKMediaQueueItem.fromMap(dict)
        }
        let request =  currentRemoteMediaCliente?.queueInsert(items,beforeItemWithID: beforItemWithId ?? kGCKMediaQueueInvalidItemID )
        result(request?.toMap())
    }
    
    private func queueLoadItem(_ arguments: Dictionary<String,Any>, result : FlutterResult) {
        let itemsDict = arguments["items"] as! [Dictionary<String, Any>]
        let items = itemsDict.compactMap{
            map in
            GCKMediaQueueItem.fromMap(map)
        }
        var options : GCKMediaQueueLoadOptions?
        if let optionsDict = arguments["options"] as? Dictionary<String, Any> {
            
            options = GCKMediaQueueLoadOptions.fromMap(optionsDict)
        }
        let request =  currentRemoteMediaCliente?.queueLoad(items, with: options ?? GCKMediaQueueLoadOptions.init() )
        result(request?.toMap())
    }
    
    private  func loadMedia(_ arguments : Dictionary<String,Any>, result : FlutterResult )  {
        print("[GoogleCast] loadMedia() called with arguments: \(arguments)")
        guard let mediaInfo = GCKMediaInformation.fromMap(arguments) else {
            print("[GoogleCast] loadMedia() failed to create GCKMediaInformation")
            result(FlutterError.init(code: "1", message:"fail to generate media info", details: nil))
            return
            
        }
        
        print("[GoogleCast] loadMedia() mediaInfo created - contentID: \(mediaInfo.contentID ?? "nil"), contentType: \(mediaInfo.contentType ?? "nil"), streamType: \(mediaInfo.streamType.rawValue)")
        
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
        print("[GoogleCast] loadMedia() options: autoplay=\(options.autoplay), playPosition=\(options.playPosition)")
        print("[GoogleCast] loadMedia() remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request = currentRemoteMediaCliente?.loadMedia(mediaInfo,with:  options)
        print("[GoogleCast] loadMedia() request: \(String(describing: request))")
        result(request?.toMap())
        
        
    }
    
    private func pause(_ result : FlutterResult){
        print("[GoogleCast] pause() called, remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request =  currentRemoteMediaCliente?.pause()
        print("[GoogleCast] pause() request: \(String(describing: request))")
        result(  request?.toMap() )
        
        
    }
    
    private func stop(_ result : FlutterResult){
        print("[GoogleCast] stop() called, remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request =  currentRemoteMediaCliente?.stop()
        result(  request?.toMap() )
        
        
    }
    
    private func play(_ result : FlutterResult){
        print("[GoogleCast] play() called, remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let request =  currentRemoteMediaCliente?.play()
        print("[GoogleCast] play() request: \(String(describing: request))")
        result(  request?.toMap() )
        
        
    }
    
    private func setActiveTrackIDs(_ result : FlutterResult, _ args : [NSNumber] ){
        let request =  currentRemoteMediaCliente?.setActiveTrackIDs(args)
        result(request?.toMap())
    }
    
    private func seek(_ result : FlutterResult, _ args : Dictionary<String, Any>){
        print("[GoogleCast] seek() called with args: \(args), remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        let seekOptions = GCKMediaSeekOptions.fromMap(args: args)
        print("[GoogleCast] seek() options - interval: \(seekOptions.interval), relative: \(seekOptions.relative)")
        let request =  currentRemoteMediaCliente?.seek(with: seekOptions)
        print("[GoogleCast] seek() request: \(String(describing: request))")
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
        print("[GoogleCast] startListen() called, adding listener to remoteMediaClient: \(String(describing: currentRemoteMediaCliente))")
        currentRemoteMediaCliente?.add(self)
    }
    
    
    //MARK: - GCKRemoteMediaClientListener
    

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        print("[GoogleCast] didUpdate mediaStatus - playerState: \(mediaStatus?.playerState.rawValue ?? -1), idleReason: \(mediaStatus?.idleReason.rawValue ?? -1)")
        print("[GoogleCast] mediaStatus contentID: \(mediaStatus?.mediaInformation?.contentID ?? "nil")")
        startListenPlayerPosition()
     let data = mediaStatus?.toMap()
       
        channel?.invokeMethod("onUpdateMediaStatus", arguments:data)
        if client.mediaStatus?.idleReason == .finished {
         onSessionEnd()
        }
    }
    
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceive queueItems: [GCKMediaQueueItem]) {
        for queuItem in queueItems {
            self.queueItems[queuItem.itemID] = queuItem
        }
        updateQueueItems()
      
    }
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didStartMediaSessionWithID sessionID: Int) {
        print("[GoogleCast] didStartMediaSessionWithID: \(sessionID)")
        startListenPlayerPosition()
    }
    
    
    
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didRemoveQueueItemsWithIDs queueItemIDs: [NSNumber]) {
        
        self.queueOrder.removeAll{
            index in
            queueItemIDs.contains(index)
        }
        
        for index in queueItemIDs {
            self.queueItems.removeValue(forKey: UInt(truncating: index))
        }
        
        updateQueueItems()
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdateQueueItemsWithIDs queueItemIDs: [NSNumber]) {
        client.queueFetchItems(forIDs: queueItemIDs)
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didInsertQueueItemsWithIDs queueItemIDs: [NSNumber], beforeItemWithID beforeItemID: UInt) {
        guard let index = queueOrder.firstIndex(of: NSNumber(value: beforeItemID)) else {
            queueOrder.append(contentsOf: queueItemIDs)
            client.queueFetchItems(forIDs: queueItemIDs)
            return
        }
        queueOrder.insert(contentsOf: queueItemIDs, at: index)
        client.queueFetchItems(forIDs: queueItemIDs)
        
    }
    
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didReceiveQueueItemIDs queueItemIDs: [NSNumber]) {
        queueOrder = queueItemIDs
        client.queueFetchItems(forIDs: queueItemIDs)
    }
    
    
 
  
    
    
    private func updateQueueItems() {
        
        channel?.invokeMethod("updateQueueItems", arguments: orderedQueueItems.map{
            queueItem in
            queueItem.toMap()
        })
    }
    
    public func onSessionEnd(){
        queueItems.removeAll()
        queueOrder.removeAll()
        updateQueueItems()
    }
    
    
    public func resumeSession(){
        currentRemoteMediaCliente?.queueFetchItemIDs();
    }
    
    private func startListenPlayerPosition(){
        self.positionTimer?.invalidate()
        self.positionTimer = nil
        
        self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            self.channel?.invokeMethod("onUpdatePlayerPosition", arguments: Int(self.currentRemoteMediaCliente?.approximateStreamPosition() ?? 0))

            
        }
    }
   
}
