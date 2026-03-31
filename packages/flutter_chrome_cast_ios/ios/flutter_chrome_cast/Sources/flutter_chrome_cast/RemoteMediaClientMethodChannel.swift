//
//  RemoteMediaClientMethodChannel.swift
//  google_cast
//
//  Created by LUIZ FELIPE ALVES LIMA on 27/06/22.
//

import Flutter
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
class RemoteMediaClientMethodChannel :UIResponder, FlutterPlugin, GCKRemoteMediaClientListener, RemoteMediaClientHostApi{
    
    // MARK: - Singleton Implementation
    
    /// Private initializer to enforce singleton pattern
    private override init() {
        
    }
    
    /// Shared singleton instance
    static private let _instance = RemoteMediaClientMethodChannel()
    
    /// Public accessor for the singleton instance
    /// - Returns: The shared RemoteMediaClientMethodChannel instance
    static var instance : RemoteMediaClientMethodChannel {
        _instance
    }
    
    // MARK: - Properties
    
    /// Typed Flutter API for callback events.
    private var flutterApi: RemoteMediaClientFlutterApi?
    
    /// Reference to the current Cast session's remote media client
    /// - Returns: The media client for the current session, or nil if no session
    private var currentRemoteMediaClient: GCKRemoteMediaClient? {
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
        
        let instance = RemoteMediaClientMethodChannel.instance
        RemoteMediaClientHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        instance.flutterApi = RemoteMediaClientFlutterApi(binaryMessenger: registrar.messenger())
    }

    // MARK: - Pigeon Host API

    func loadMedia(request: LoadMediaRequestPigeon) throws {
        guard let mediaInfo = GCKMediaInformation.fromMap(mediaInfoToMap(request.mediaInfo)) else {
            throw NSError(
                domain: "INVALID_ARGUMENT",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Invalid mediaInfo payload"]
            )
        }

        let requestDataBuilder = GCKMediaLoadRequestDataBuilder()
        requestDataBuilder.mediaInformation = mediaInfo
        requestDataBuilder.autoplay = NSNumber(value: request.autoPlay)
        requestDataBuilder.startTime = TimeInterval(request.playPosition)
        requestDataBuilder.playbackRate = Float(request.playbackRate)
        requestDataBuilder.activeTrackIDs = request.activeTrackIds?.compactMap { $0 }.map { NSNumber(value: $0) }
        requestDataBuilder.credentials = request.credentials
        requestDataBuilder.credentialsType = request.credentialsType

        if let customData = request.customData as? [String: Any] {
            requestDataBuilder.customData = customData as NSObject
        }

        _ = currentRemoteMediaClient?.loadMedia(with: requestDataBuilder.build())
    }

    func queueLoadItems(request: QueueLoadRequestPigeon) throws {
        let items = request.items.compactMap { item -> GCKMediaQueueItem? in
            guard let item else { return nil }
            return GCKMediaQueueItem.fromMap(mediaQueueItemToMap(item))
        }

        let options = GCKMediaQueueLoadOptions.init()
        if let requestOptions = request.options {
            options.startIndex = UInt(requestOptions.startIndex)
            options.playPosition = TimeInterval(requestOptions.playPosition)
            options.repeatMode = repeatModeFromPigeon(requestOptions.repeatMode)
            options.customData = requestOptions.customData as? [String: Any]
        }

        _ = currentRemoteMediaClient?.queueLoad(items, with: options)
    }

    func queueInsertItems(request: QueueInsertItemsRequestPigeon) throws {
        let items = request.items.compactMap { item -> GCKMediaQueueItem? in
            guard let item else { return nil }
            return GCKMediaQueueItem.fromMap(mediaQueueItemToMap(item))
        }

        _ = currentRemoteMediaClient?.queueInsert(
            items,
            beforeItemWithID: request.beforeItemWithId.map { UInt($0) } ?? kGCKMediaQueueInvalidItemID
        )
    }

    func queueInsertItemAndPlay(request: QueueInsertItemAndPlayRequestPigeon) throws {
        guard let item = GCKMediaQueueItem.fromMap(mediaQueueItemToMap(request.item)) else {
            throw NSError(
                domain: "INVALID_ARGUMENT",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Invalid queue item payload"]
            )
        }

        _ = currentRemoteMediaClient?.queueInsertAndPlay(item, beforeItemWithID: UInt(request.beforeItemWithId))
    }

    func queueNextItem() throws {
        _ = currentRemoteMediaClient?.queueNextItem()
    }

    func queuePrevItem() throws {
        _ = currentRemoteMediaClient?.queuePreviousItem()
    }

    func queueJumpToItemWithId(itemId: Int64) throws {
        currentRemoteMediaClient?.queueJumpToItem(withID: UInt(itemId))
    }

    func queueRemoveItemsWithIds(itemIds: [Int64?]) throws {
        let ids = itemIds.compactMap { $0 }.map { NSNumber(value: $0) }
        currentRemoteMediaClient?.queueRemoveItems(withIDs: ids)
    }

    func queueReorderItems(request: QueueReorderItemsRequestPigeon) throws {
        let itemIds = request.itemsIds.compactMap { $0 }.map { NSNumber(value: $0) }
        let beforeItemId = request.beforeItemWithId.map { UInt($0) } ?? kGCKMediaQueueInvalidItemID
        currentRemoteMediaClient?.queueReorderItems(withIDs: itemIds, insertBeforeItemWithID: beforeItemId)
    }

    func seek(request: SeekOptionPigeon) throws {
        let options = GCKMediaSeekOptions.init()
        options.interval = TimeInterval(request.position)
        options.relative = request.relative
        options.resumeState = GCKMediaResumeState(rawValue: mediaResumeStateToInt(request.resumeState)) ?? .play
        options.seekToInfinite = request.seekToInfinity
        _ = currentRemoteMediaClient?.seek(with: options)
    }

    func setActiveTrackIds(trackIds: [Int64?]) throws {
        _ = currentRemoteMediaClient?.setActiveTrackIDs(trackIds.compactMap { $0 }.map { NSNumber(value: $0) })
    }

    func setPlaybackRate(request: SetPlaybackRateRequestPigeon) throws {
        let playbackRate = try PlaybackRate(request.rate)
        _ = currentRemoteMediaClient?.setPlaybackRate(playbackRate.nativeValue)
    }

    func setTextTrackStyle(textTrackStyle: TextTrackStylePigeon) throws {
        // TODO: map TextTrackStylePigeon to native GCKMediaTextTrackStyle without legacy map extensions.
        _ = textTrackStyle
    }

    func play() throws {
        _ = currentRemoteMediaClient?.play()
    }

    func pause() throws {
        _ = currentRemoteMediaClient?.pause()
    }

    func stop() throws {
        _ = currentRemoteMediaClient?.stop()
    }
    
    public func startListen(){
        print("[GoogleCast] startListen() called, adding listener to remoteMediaClient: \(String(describing: currentRemoteMediaClient))")
        currentRemoteMediaClient?.add(self)
    }
    
    
    //MARK: - GCKRemoteMediaClientListener
    

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        print("[GoogleCast] didUpdate mediaStatus - playerState: \(mediaStatus?.playerState.rawValue ?? -1), idleReason: \(mediaStatus?.idleReason.rawValue ?? -1)")
        print("[GoogleCast] mediaStatus contentID: \(mediaStatus?.mediaInformation?.contentID ?? "nil")")
        startListenPlayerPosition()
        flutterApi?.onMediaStatusChanged(status: mediaStatus.flatMap { toPigeonMediaStatus($0) }) { _ in }
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
        let items = orderedQueueItems.map { toPigeonQueueItem($0) }
        flutterApi?.onQueueStatusChanged(queueItems: items) { _ in }
    }
    
    public func onSessionEnd(){
        queueItems.removeAll()
        queueOrder.removeAll()
        updateQueueItems()
    }
    
    
    public func resumeSession(){
        currentRemoteMediaClient?.queueFetchItemIDs();
    }
    
    private func startListenPlayerPosition(){
        self.positionTimer?.invalidate()
        self.positionTimer = nil
        
        self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){_ in
            let update = PlayerPositionUpdate(
                progress: Int64((self.currentRemoteMediaClient?.approximateStreamPosition() ?? 0) * 1000),
                duration: Int64((self.currentRemoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration ?? 0) * 1000)
            )
            self.flutterApi?.onPlayerPositionChanged(update: update) { _ in }

            
        }
    }

    private func repeatModeToString(_ mode: RepeatModePigeon) -> String {
        switch mode {
        case .off:
            return "OFF"
        case .all:
            return "ALL"
        case .single:
            return "SINGLE"
        case .allAndShuffle:
            return "ALL_AND_SHUFFLE"
        }
    }

    private func repeatModeFromPigeon(_ mode: RepeatModePigeon) -> GCKMediaRepeatMode {
        switch mode {
        case .off:
            return .off
        case .all:
            return .all
        case .single:
            return .single
        case .allAndShuffle:
            return .allAndShuffle
        }
    }

    private func mediaResumeStateToInt(_ state: MediaResumeStatePigeon) -> Int {
        switch state {
        case .play:
            return 0
        case .pause:
            return 1
        case .unchanged:
            return 2
        }
    }

    private struct PlaybackRate {
        let value: Double

        init(_ value: Double) throws {
            guard value.isFinite else {
                throw NSError(
                    domain: "INVALID_ARGUMENT",
                    code: 3,
                    userInfo: [NSLocalizedDescriptionKey: "Playback rate must be a finite number"]
                )
            }
            self.value = value
        }

        var nativeValue: Float {
            Float(value)
        }
    }

    private enum PigeonPlayerState: String {
        case unknown = "UNKNOWN"
        case idle = "IDLE"
        case playing = "PLAYING"
        case paused = "PAUSED"
        case buffering = "BUFFERING"

        init(_ native: GCKMediaPlayerState) {
            switch native {
            case .playing:
                self = .playing
            case .paused:
                self = .paused
            case .buffering:
                self = .buffering
            case .idle:
                self = .idle
            default:
                self = .unknown
            }
        }
    }

    private enum PigeonIdleReason: String {
        case none = "NONE"
        case finished = "FINISHED"
        case canceled = "CANCELED"
        case interrupted = "INTERRUPTED"
        case error = "ERROR"

        init(_ native: GCKMediaPlayerIdleReason) {
            switch native {
            case .finished:
                self = .finished
            case .cancelled:
                self = .canceled
            case .interrupted:
                self = .interrupted
            case .error:
                self = .error
            default:
                self = .none
            }
        }
    }

    private enum PigeonRepeatModeValue: String {
        case off = "OFF"
        case all = "ALL"
        case single = "SINGLE"
        case allAndShuffle = "ALL_AND_SHUFFLE"

        init(_ native: GCKMediaRepeatMode) {
            switch native {
            case .all:
                self = .all
            case .single:
                self = .single
            case .allAndShuffle:
                self = .allAndShuffle
            default:
                self = .off
            }
        }
    }

    private enum PigeonStreamTypeValue: String {
        case none = "NONE"
        case buffered = "BUFFERED"
        case live = "LIVE"

        init(_ native: GCKMediaStreamType) {
            switch native {
            case .buffered:
                self = .buffered
            case .live:
                self = .live
            default:
                self = .none
            }
        }
    }

    private func mediaInfoToMap(_ mediaInfo: MediaInfo) -> [String: Any] {
        return [
            "contentID": mediaInfo.contentId,
            "contentType": mediaInfo.contentType,
            "streamType": mediaInfo.streamType,
            "contentURL": mediaInfo.contentUrl,
            "duration": mediaInfo.duration,
            "customData": mediaInfo.customData as Any,
            "tracks": mediaInfo.tracks?.compactMap { track -> [String: Any]? in
                guard let track else { return nil }
                return [
                    "trackID": track.trackId,
                    "type": track.type,
                    "contentID": track.trackContentId,
                    "contentType": track.trackContentType,
                    "subtype": track.subtype,
                    "name": track.name,
                    "language": track.language,
                ]
            } as Any,
        ]
    }

    private func mediaQueueItemToMap(_ item: MediaQueueItem) -> [String: Any] {
        return [
            "itemId": item.itemId,
            "preLoadTime": item.preLoadTime,
            "startTime": item.startTime,
            "playbackDuration": item.playbackDuration,
            "mediaInformation": item.media.map(mediaInfoToMap) as Any,
            "autoPlay": item.autoplay,
            "activeTracksIds": item.activeTrackIds as Any,
            "customData": item.customData as Any,
        ]
    }

    private func toPigeonMediaStatus(_ status: GCKMediaStatus) -> MediaStatus {
        let playerState = PigeonPlayerState(status.playerState).rawValue
        let idleReason = PigeonIdleReason(status.idleReason).rawValue

        return MediaStatus(
            mediaSessionId: Int64(status.mediaSessionID),
            playerState: playerState,
            idleReason: idleReason,
            playbackRate: Double(status.playbackRate),
            media: status.mediaInformation == nil ? nil : toPigeonMediaInfo(status.mediaInformation!),
            volume: Volume(level: 0, muted: status.isMuted),
            repeatMode: PigeonRepeatModeValue(status.queueRepeatMode).rawValue,
            currentItemId: 0,
            activeTrackIds: nil,
            liveSeekableRange: nil
        )
    }

    private func toPigeonMediaInfo(_ info: GCKMediaInformation) -> MediaInfo {
        return MediaInfo(
            contentId: info.contentID ?? "",
            contentType: info.contentType ?? "",
            streamType: PigeonStreamTypeValue(info.streamType).rawValue,
            contentUrl: info.contentURL?.absoluteString ?? "",
            duration: Int64(info.streamDuration),
            customData: info.customData as? [String: Any?],
            tracks: info.mediaTracks?.map { track in
                MediaTrack(
                    trackId: Int64(track.identifier),
                    type: Int64(track.type.rawValue),
                    trackContentId: track.contentIdentifier ?? "",
                    trackContentType: track.contentType,
                    subtype: Int64(track.textSubtype.rawValue),
                    name: track.name ?? "",
                    language: track.languageCode ?? ""
                )
            }
        )
    }

    private func toPigeonQueueItem(_ item: GCKMediaQueueItem) -> MediaQueueItem {
        return MediaQueueItem(
            itemId: Int64(item.itemID),
            preLoadTime: Int64(item.preloadTime),
            startTime: Int64(item.startTime),
            playbackDuration: Int64(item.playbackDuration),
            media: toPigeonMediaInfo(item.mediaInformation),
            autoplay: item.autoplay,
            activeTrackIds: item.activeTrackIDs.map { Int64(truncating: $0) },
            customData: item.customData as? [String: Any?]
        )
    }
   
}
