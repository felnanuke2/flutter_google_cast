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

    /// The last `contentID` that the Flutter side passed when loading media.
    ///
    /// The Google Cast Default Media Receiver does not always echo the
    /// `contentID` we sent back in the first `mediaStatus` update — in that
    /// case `GCKMediaInformation.contentID` is nil/empty. To match Android
    /// behaviour (where the originally provided `contentID` is delivered from
    /// the very first update), we cache the value sent from Flutter and
    /// substitute it into the media status whenever the receiver reports an
    /// empty `contentID`.
    private var lastLoadedContentID: String?

    /// The last `mediaSessionID` reported by the Cast SDK.
    ///
    /// Used to detect that the SDK already applied a newly loaded media item.
    private var lastKnownMediaSessionID: Int = 0

    /// Expected start position (in seconds) of a media load that is still
    /// being applied by the receiver.
    ///
    /// While a load is pending, the position ticks are suppressed: right
    /// after `loadMedia` the SDK keeps reporting the previous content's
    /// position until the new media status is applied.
    private var pendingLoadExpectedPosition: TimeInterval?

    /// The `mediaSessionID` observed at the moment `loadMedia` was called.
    private var pendingLoadPreviousMediaSessionID: Int = 0

    /// Safety timer that releases the pending load guard.
    private var pendingLoadGuardTimer: Timer?

    /// Tolerance (in seconds) used to check that the reported position
    /// converged to the requested start position.
    private static let pendingLoadGuardTolerance: TimeInterval = 5

    /// Maximum time (in seconds) the pending load guard stays armed.
    private static let pendingLoadGuardTimeout: TimeInterval = 10

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
    public static func register(with registrar: FlutterPluginRegistrar) {
        
        let instance = RemoteMediaClientMethodChannel.instance
        RemoteMediaClientHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)
        instance.flutterApi = RemoteMediaClientFlutterApi(binaryMessenger: registrar.messenger())
    }

    // MARK: - Pigeon Host API

    func loadMedia(request: LoadMediaRequestPigeon) throws {
        // Cache the contentID that Flutter passed so we can inject it into
        // the media status updates where the receiver reports no contentID
        // back (see `resolvedContentID`).
        if !request.mediaInfo.contentId.isEmpty {
            self.lastLoadedContentID = request.mediaInfo.contentId
        } else {
            self.lastLoadedContentID = nil
        }

        // Suppress the position ticks until the SDK applied the new media
        // item, otherwise the previous content's position is reported.
        armPendingLoadGuard(expectedPosition: TimeInterval(request.playPosition))

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
        FlutterGoogleCastLogger.verbose("[GoogleCast] startListen() called, adding listener to remoteMediaClient: \(String(describing: currentRemoteMediaClient))")
        currentRemoteMediaClient?.add(self)
    }

    /// Tears down media client state: removes the listener, stops the
    /// position timer and clears the queue cache. Used by session reset.
    public func cleanUp(){
        currentRemoteMediaClient?.remove(self)
        positionTimer?.invalidate()
        positionTimer = nil
        queueItems.removeAll()
        queueOrder.removeAll()
        lastLoadedContentID = nil
        releasePendingLoadGuard()
    }
    
    
    //MARK: - GCKRemoteMediaClientListener
    

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        print("[GoogleCast] didUpdate mediaStatus - playerState: \(mediaStatus?.playerState.rawValue ?? -1), idleReason: \(mediaStatus?.idleReason.rawValue ?? -1)")
        print("[GoogleCast] mediaStatus contentID: \(mediaStatus?.mediaInformation?.contentID ?? "nil")")
        if let sessionID = mediaStatus?.mediaSessionID {
            lastKnownMediaSessionID = sessionID
        }
        startListenPlayerPosition()
        Task { @MainActor in
            try? await flutterApi?.onMediaStatusChanged(status: mediaStatus.flatMap { toPigeonMediaStatus($0) })
        }
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
        lastKnownMediaSessionID = sessionID
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
        Task { @MainActor in try? await flutterApi?.onQueueStatusChanged(queueItems: items) }
    }
    
    public func onSessionEnd(){
        queueItems.removeAll()
        queueOrder.removeAll()
        lastLoadedContentID = nil
        releasePendingLoadGuard()
        updateQueueItems()
    }
    
    
    public func resumeSession(){
        currentRemoteMediaClient?.queueFetchItemIDs();
    }
    
    private func startListenPlayerPosition(){
        self.positionTimer?.invalidate()
        self.positionTimer = nil
        
        self.positionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true){ [weak self] _ in
            guard let self = self else { return }
            let position = self.currentRemoteMediaClient?.approximateStreamPosition() ?? 0
            guard self.shouldEmitPosition(position) else { return }
            self.emitPositionUpdate(progress: position)
        }
    }

    /// Emits a position update to the Flutter side.
    /// - Parameter progress: The current playback position in seconds
    private func emitPositionUpdate(progress: TimeInterval) {
        let update = PlayerPositionUpdate(
            progress: Int64(progress * 1000),
            duration: Int64((self.currentRemoteMediaClient?.mediaStatus?.mediaInformation?.streamDuration ?? 0) * 1000)
        )
        Task { @MainActor in try? await self.flutterApi?.onPlayerPositionChanged(update: update) }
    }

    /// Arms the guard that suppresses the stale position updates sent right
    /// after a `loadMedia` call.
    ///
    /// After `loadMedia` the Cast SDK keeps reporting the position of the
    /// previously loaded content until the new media status is applied. The
    /// guard is released as soon as the SDK reported a new media session and
    /// the position converged to the requested start position, or by the
    /// safety timeout when the convergence never happens.
    ///
    /// - Parameter expectedPosition: The requested start position in seconds
    private func armPendingLoadGuard(expectedPosition: TimeInterval) {
        pendingLoadExpectedPosition = expectedPosition
        pendingLoadPreviousMediaSessionID = currentMediaSessionID()
        pendingLoadGuardTimer?.invalidate()
        pendingLoadGuardTimer = Timer.scheduledTimer(
            withTimeInterval: RemoteMediaClientMethodChannel.pendingLoadGuardTimeout,
            repeats: false
        ) { [weak self] _ in
            self?.releasePendingLoadGuard()
        }
        // Publish the requested start position right away, so the Flutter
        // side does not keep showing the last position of the previous
        // content while the new one is being applied.
        emitPositionUpdate(progress: expectedPosition)
    }

    /// Releases the pending load guard and resumes the position updates.
    private func releasePendingLoadGuard() {
        pendingLoadExpectedPosition = nil
        pendingLoadGuardTimer?.invalidate()
        pendingLoadGuardTimer = nil
    }

    /// Decides whether the given position can be forwarded to the Flutter side.
    ///
    /// While a media load is pending the ticks are suppressed until the SDK
    /// reported a new media session **and** the position converged to the
    /// requested start position (±5 s).
    ///
    /// - Parameter position: The current playback position in seconds
    /// - Returns: `true` when the position can be sent to the Flutter side
    private func shouldEmitPosition(_ position: TimeInterval) -> Bool {
        guard let expectedPosition = pendingLoadExpectedPosition else { return true }
        let sessionID = currentMediaSessionID()
        let sessionChanged = sessionID != 0 && sessionID != pendingLoadPreviousMediaSessionID
        let converged = abs(position - expectedPosition) <= RemoteMediaClientMethodChannel.pendingLoadGuardTolerance
        if sessionChanged && converged {
            releasePendingLoadGuard()
            return true
        }
        return false
    }

    /// The media session ID currently reported by the Cast SDK.
    /// - Returns: The media session ID or 0 when no session is known
    private func currentMediaSessionID() -> Int {
        currentRemoteMediaClient?.mediaStatus?.mediaSessionID ?? lastKnownMediaSessionID
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
        // The HLS segment format hints are forwarded to the
        // `GCKMediaInformationBuilder` instead of the receiver. They arrive
        // in the dedicated pigeon fields; the legacy customData keys are
        // still honoured as a fallback (and stripped from the payload sent
        // to the receiver).
        var customData = mediaInfo.customData?.compactMapValues { value -> Any? in value } ?? [:]
        let customDataHlsSegmentFormat = customData.removeValue(forKey: GCKMediaInformation.hlsSegmentFormatKey) as? String
        let customDataHlsVideoSegmentFormat = customData.removeValue(forKey: GCKMediaInformation.hlsVideoSegmentFormatKey) as? String
        let hlsSegmentFormat = mediaInfo.hlsSegmentFormat ?? customDataHlsSegmentFormat
        let hlsVideoSegmentFormat = mediaInfo.hlsVideoSegmentFormat ?? customDataHlsVideoSegmentFormat

        var map: [String: Any] = [
            "contentID": mediaInfo.contentId,
            "contentType": mediaInfo.contentType,
            "streamType": mediaInfo.streamType,
            "contentURL": resolvedContentURL(mediaInfo),
            "duration": Double(mediaInfo.duration),
            "customData": customData,
        ]

        if let hlsSegmentFormat = hlsSegmentFormat {
            map["hlsSegmentFormat"] = hlsSegmentFormat
        }
        if let hlsVideoSegmentFormat = hlsVideoSegmentFormat {
            map["hlsVideoSegmentFormat"] = hlsVideoSegmentFormat
        }
        if let tracks = mediaInfo.tracks {
            map["tracks"] = tracks.compactMap{ track -> [String: Any]? in
                guard let track else { return nil }
                return [
                    "trackId": Int(track.trackId),
                    "type": Int(track.type),
                    "trackContentId": track.trackContentId,
                    "trackContentType": track.trackContentType,
                    "subtype": Int(track.subtype),
                    "name": track.name,
                    "language": track.language,
                ]
            }
        }
        if let metadata = mediaInfo.metadata {
            map["metadata"] = metadataToMap(metadata)
        }
        return map
    }

    private func mediaQueueItemToMap(_ item: MediaQueueItem) -> [String: Any] {
        var map: [String: Any] = [
            "itemId": Int(item.itemId),
            "preloadTime": Double(item.preLoadTime),
            "startTime": Double(item.startTime),
            "playbackDuration": Double(item.playbackDuration),
            "autoplay": item.autoplay,
        ]
        if let media = item.media {
            map["media"] = mediaInfoToMap(media)
        }
        if let activeTrackIds = item.activeTrackIds {
            map["activeTrackIds"] = activeTrackIds.compactMap { $0 }.map { NSNumber(value: $0) }
        }
        if let customData = item.customData?.compactMapValues({ value -> Any? in value }) {
            map["customData"] = customData
        }
        return map
    }

    /// Resolves the URL used to load the media.
    ///
    /// The content URL is used when it is available. When it is missing the
    /// content ID is used as the media URL, matching the behaviour of the
    /// other platforms.
    private func resolvedContentURL(_ mediaInfo: MediaInfo) -> String {
        if !mediaInfo.contentUrl.isEmpty {
            return mediaInfo.contentUrl
        }
        return mediaInfo.contentId
    }

    /// Converts the media metadata into the map representation understood by
    /// `GCKMediaMetadata.fromMap`, which maps the keys to the canonical Cast
    /// metadata keys.
    private func metadataToMap(_ metadata: MediaMetadataPigeon) -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["metadataType"] = Int(metadata.metadataType)
        if let title = metadata.title {
            dict["title"] = title
        }
        if let subtitle = metadata.subtitle {
            dict["subtitle"] = subtitle
        }
        if let studio = metadata.studio {
            dict["studio"] = studio
        }
        if let artist = metadata.artist {
            dict["artist"] = artist
        }
        if let albumName = metadata.albumName {
            dict["albumName"] = albumName
        }
        if let albumArtist = metadata.albumArtist {
            dict["albumArtist"] = albumArtist
        }
        if let composer = metadata.composer {
            dict["composer"] = composer
        }
        if let trackNumber = metadata.trackNumber {
            dict["trackNumber"] = Int(trackNumber)
        }
        if let discNumber = metadata.discNumber {
            dict["discNumber"] = Int(discNumber)
        }
        if let seriesTitle = metadata.seriesTitle {
            dict["seriesTitle"] = seriesTitle
        }
        if let season = metadata.season {
            dict["season"] = Int(season)
        }
        if let episode = metadata.episode {
            dict["episode"] = Int(episode)
        }
        if let location = metadata.location {
            dict["location"] = location
        }
        if let latitude = metadata.latitude {
            dict["latitude"] = latitude
        }
        if let longitude = metadata.longitude {
            dict["longitude"] = longitude
        }
        if let width = metadata.width {
            dict["width"] = Int(width)
        }
        if let height = metadata.height {
            dict["height"] = Int(height)
        }
        if let creationDateTime = metadata.creationDateTime, let millis = iso8601DateMillis(creationDateTime) {
            dict["creationDateTime"] = millis
        }
        if let releaseDate = metadata.releaseDate, let millis = iso8601DateMillis(releaseDate) {
            dict["releaseDate"] = millis
        }
        // The TV show original air date is sent under the broadcast date key,
        // the closest canonical key exposed by the GoogleCast iOS SDK.
        if let originalAirDate = metadata.originalAirDate, let millis = iso8601DateMillis(originalAirDate) {
            dict["broadcastDate"] = millis
        }
        if let images = metadata.images {
            dict["images"] = images.compactMap{ image -> [String: Any]? in
                guard let image else { return nil }
                var imageDict: [String: Any] = ["url": image.url]
                if let width = image.width {
                    imageDict["width"] = Int(width)
                }
                if let height = image.height {
                    imageDict["height"] = Int(height)
                }
                return imageDict
            }
        }
        return dict
    }

    /// Parses an ISO-8601 date string (the representation produced by
    /// `DateTime.toUtc().toIso8601String()` on the Dart side) into the epoch
    /// time in milliseconds expected by `GCKMediaMetadata.fromMap`.
    ///
    /// The value may also be a plain epoch time in milliseconds or a
    /// `yyyy-MM-dd` date-only string, the forms used by the legacy map based
    /// payloads.
    private func iso8601DateMillis(_ value: String) -> Double? {
        if let millis = Double(value) {
            return millis
        }
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: value) {
            return date.timeIntervalSince1970 * 1000
        }
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: value) {
            return date.timeIntervalSince1970 * 1000
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: value) else { return nil }
        return date.timeIntervalSince1970 * 1000
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
            contentId: resolvedContentID(info),
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
            },
            metadata: toPigeonMetadata(info.metadata),
            hlsSegmentFormat: pigeonHlsSegmentFormat(info.hlsSegmentFormat),
            hlsVideoSegmentFormat: pigeonHlsVideoSegmentFormat(info.hlsVideoSegmentFormat)
        )
    }

    /// Maps the Cast SDK HLS audio segment format back to the Flutter
    /// `CastHlsSegmentFormat` enum name.
    private func pigeonHlsSegmentFormat(_ format: GCKHLSSegmentFormat) -> String? {
        switch format {
        case .AAC: return "aac"
        case .AC3: return "ac3"
        case .MP3: return "mp3"
        case .TS: return "ts"
        case .TS_AAC: return "tsAac"
        case .E_AC3: return "eAc3"
        case .FMP4: return "fmp4"
        default: return nil
        }
    }

    /// Maps the Cast SDK HLS video segment format back to the Flutter
    /// `HlsVideoSegmentFormat` enum name.
    private func pigeonHlsVideoSegmentFormat(_ format: GCKHLSVideoSegmentFormat) -> String? {
        switch format {
        case .MPEG2_TS: return "mpeg2Ts"
        case .FMP4: return "fmp4"
        default: return nil
        }
    }

    /// Ensures the media information always carries a usable content ID.
    ///
    /// Priority:
    ///   1. The `contentID` already populated by the receiver (kept as-is).
    ///   2. The `contentID` originally passed from Flutter in `loadMedia`
    ///      (cached in `lastLoadedContentID`).
    ///   3. The `contentURL` as a last-resort fallback.
    private func resolvedContentID(_ info: GCKMediaInformation) -> String {
        if let contentID = info.contentID, !contentID.isEmpty {
            return contentID
        }
        if let cached = lastLoadedContentID, !cached.isEmpty {
            return cached
        }
        return info.contentURL?.absoluteString ?? ""
    }

    private func toPigeonMetadata(_ metadata: GCKMediaMetadata?) -> MediaMetadataPigeon? {
        guard let metadata = metadata else { return nil }

        let images = metadata.images().compactMap { item -> MediaImagePigeon? in
            guard let image = item as? GCKImage else { return nil }
            return MediaImagePigeon(
                url: image.url.absoluteString,
                width: image.width > 0 ? Int64(image.width) : nil,
                height: image.height > 0 ? Int64(image.height) : nil
            )
        }

        let title = metadata.string(forKey: kGCKMetadataKeyTitle)
        let subtitle = metadata.string(forKey: kGCKMetadataKeySubtitle)
        let studio = metadata.string(forKey: kGCKMetadataKeyStudio)
        let artist = metadata.string(forKey: kGCKMetadataKeyArtist)
        let albumName = metadata.string(forKey: kGCKMetadataKeyAlbumTitle)
        let seriesTitle = metadata.string(forKey: kGCKMetadataKeySeriesTitle)

        var season: Int64? = nil
        if metadata.containsKey(kGCKMetadataKeySeasonNumber) {
            let val = metadata.integer(forKey: kGCKMetadataKeySeasonNumber)
            if val != NSNotFound { season = Int64(val) }
        }

        var episode: Int64? = nil
        if metadata.containsKey(kGCKMetadataKeyEpisodeNumber) {
            let val = metadata.integer(forKey: kGCKMetadataKeyEpisodeNumber)
            if val != NSNotFound { episode = Int64(val) }
        }

        var releaseDate: String? = nil
        if let date = metadata.date(forKey: kGCKMetadataKeyReleaseDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            releaseDate = formatter.string(from: date)
        }

        return MediaMetadataPigeon(
            metadataType: Int64(metadata.metadataType.rawValue),
            title: title,
            subtitle: subtitle,
            studio: studio,
            artist: artist,
            albumName: albumName,
            seriesTitle: seriesTitle,
            season: season,
            episode: episode,
            releaseDate: releaseDate,
            images: images
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
