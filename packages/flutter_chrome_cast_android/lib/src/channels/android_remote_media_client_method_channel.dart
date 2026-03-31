import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:rxdart/subjects.dart';

class _RemoteMediaFlutterApiHandler extends RemoteMediaClientFlutterApi {
  _RemoteMediaFlutterApiHandler({
    required this.onMediaStatusChangedCallback,
    required this.onQueueStatusChangedCallback,
    required this.onPlayerPositionChangedCallback,
  });

  final void Function(MediaStatus? status) onMediaStatusChangedCallback;
  final void Function(List<MediaQueueItem?> queueItems)
      onQueueStatusChangedCallback;
  final void Function(PlayerPositionUpdate update)
      onPlayerPositionChangedCallback;

  @override
  void onMediaStatusChanged(MediaStatus? status) {
    onMediaStatusChangedCallback(status);
  }

  @override
  void onQueueStatusChanged(List<MediaQueueItem?> queueItems) {
    onQueueStatusChangedCallback(queueItems);
  }

  @override
  void onPlayerPositionChanged(PlayerPositionUpdate update) {
    onPlayerPositionChangedCallback(update);
  }
}

/// Android-specific implementation of Google Cast remote media client functionality.
class GoogleCastRemoteMediaClientAndroidMethodChannel
    extends GoogleCastRemoteMediaClientPlatformInterface {
  /// Creates a new Android remote media client method channel.
  GoogleCastRemoteMediaClientAndroidMethodChannel() {
    RemoteMediaClientFlutterApi.setUp(
      _RemoteMediaFlutterApiHandler(
        onMediaStatusChangedCallback: _onMediaStatusChanged,
        onQueueStatusChangedCallback: _onQueueStatusChanged,
        onPlayerPositionChangedCallback: _onPlayerPositionChanged,
      ),
    );
  }

  final _hostApi = RemoteMediaClientHostApi();

  // Media Status
  final _mediaStatusStreamController = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);

  @override
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusStreamController.value;

  @override
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusStreamController.stream;

  // QueueItems
  final _queueItemsStreamController =
      BehaviorSubject<List<GoogleCastQueueItem>>()..add([]);

  @override
  List<GoogleCastQueueItem> get queueItems => _queueItemsStreamController.value;

  @override
  Stream<List<GoogleCastQueueItem>> get queueItemsStream =>
      _queueItemsStreamController.stream;

  // PlayerPosition
  final _playerPositionStreamController = BehaviorSubject<Duration>()
    ..add(Duration.zero);
  @override
  Duration get playerPosition => _playerPositionStreamController.value;

  @override
  Stream<Duration> get playerPositionStream =>
      _playerPositionStreamController.stream;

  // Queue has Next or revious item
  @override
  bool get queueHasNextItem {
    final currentQueueItemId = mediaStatus?.currentItemId;
    final currentItemIndex = queueItems
        .map((e) => e.itemId)
        .toList()
        .lastIndexOf(currentQueueItemId);
    return (queueItems.length - 1) > currentItemIndex;
  }

  @override
  bool get queueHasPreviousItem {
    final currentQueueItemId = mediaStatus?.currentItemId;
    final currentItemIndex = queueItems
        .map((e) => e.itemId)
        .toList()
        .lastIndexOf(currentQueueItemId);
    return currentItemIndex > 0;
  }

  @override
  Future<void> loadMediaWithRequest(
    GoogleCastLoadMediaRequest request,
  ) async {
    await _hostApi.loadMedia(
      LoadMediaRequestPigeon(
        mediaInfo: _toMediaInfo(request.mediaInfo),
        autoPlay: request.autoPlay,
        playPosition: request.playPosition.inSeconds,
        playbackRate: request.playbackRate,
        activeTrackIds: request.activeTrackIds,
        credentials: request.credentials,
        credentialsType: request.credentialsType,
        customData: request.customData,
      ),
    );
  }

  @override
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
    Map<String, dynamic>? customData,
  }) async {
    await loadMediaWithRequest(
      GoogleCastLoadMediaRequest(
        mediaInfo: mediaInfo,
        autoPlay: autoPlay,
        playPosition: playPosition,
        playbackRate: playbackRate,
        activeTrackIds: activeTrackIds,
        credentials: credentials,
        credentialsType: credentialsType,
        customData: customData,
      ),
    );
  }

  @override
  Future<void> pause() async {
    await _hostApi.pause();
  }

  @override
  Future<void> play() async {
    await _hostApi.play();
  }

  @override
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  }) async {
    await _hostApi.queueLoadItems(
      QueueLoadRequestPigeon(
        items: queueItems.map(_toMediaQueueItem).toList(),
        options: options == null
            ? null
            : QueueLoadOptionsPigeon(
                startIndex: options.startIndex,
                playPosition: options.playPosition.inSeconds,
                repeatMode: _toRepeatMode(options.repeatMode),
                customData: options.customData,
              ),
      ),
    );
  }

  @override
  Future<void> queueNextItem() async {
    await _hostApi.queueNextItem();
  }

  @override
  Future<void> queuePrevItem() async {
    await _hostApi.queuePrevItem();
  }

  @override
  Future<void> seek(GoogleCastMediaSeekOption option) async {
    await _hostApi.seek(
      SeekOptionPigeon(
        position: option.position.inSeconds,
        relative: option.relative,
        resumeState: _toResumeState(option.resumeState),
        seekToInfinity: option.seekToInfinity,
      ),
    );
  }

  @override
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs) async {
    await _hostApi.setActiveTrackIds(activeTrackIDs);
  }

  @override
  Future<void> setPlaybackRate(double rate) async {
    await _hostApi.setPlaybackRate(SetPlaybackRateRequestPigeon(rate: rate));
  }

  @override
  Future<void> setTextTrackStyle(
    TextTrackStyle textTrackStyle,
  ) async {
    await _hostApi.setTextTrackStyle(_toTextTrackStylePigeon(textTrackStyle));
  }

  @override
  Future<void> stop() async {
    await _hostApi.stop();
  }

  @override
  Future<void> queueJumpToItemWithId(int itemId) async {
    await _hostApi.queueJumpToItemWithId(itemId);
  }

  @override
  Future<void> queueRemoveItemsWithIds(List<int> itemIds) async {
    await _hostApi.queueRemoveItemsWithIds(itemIds);
  }

  @override
  Future<void> queueInsertItemAndPlayWithRequest(
    GoogleCastQueueInsertItemAndPlayRequest request,
  ) async {
    await _hostApi.queueInsertItemAndPlay(
      QueueInsertItemAndPlayRequestPigeon(
        item: _toMediaQueueItem(request.item),
        beforeItemWithId: request.beforeItemWithId,
      ),
    );
  }

  @override
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  }) async {
    await queueInsertItemAndPlayWithRequest(
      GoogleCastQueueInsertItemAndPlayRequest(
        item: item,
        beforeItemWithId: beforeItemWithId,
      ),
    );
  }

  @override
  Future<void> queueInsertItemsWithRequest(
    GoogleCastQueueInsertItemsRequest request,
  ) async {
    await _hostApi.queueInsertItems(
      QueueInsertItemsRequestPigeon(
        items: request.items.map(_toMediaQueueItem).toList(),
        beforeItemWithId: request.beforeItemWithId,
      ),
    );
  }

  @override
  Future<void> queueInsertItems(
    List<GoogleCastQueueItem> items, {
    int? beforeItemWithId,
  }) async {
    await queueInsertItemsWithRequest(
      GoogleCastQueueInsertItemsRequest(
        items: items,
        beforeItemWithId: beforeItemWithId,
      ),
    );
  }

  Future<void> _onMediaStatusChanged(MediaStatus? status) async {
    if (status == null) {
      _mediaStatusStreamController.add(null);
      return;
    }
    final mediaStatus = _toMediaStatus(status);

    _mediaStatusStreamController.add(mediaStatus);
  }

  Future<void> _onQueueStatusChanged(List<MediaQueueItem?> arguments) async {
    final queueItems = arguments
        .whereType<MediaQueueItem>()
        .map(_toQueueItem)
        .toList();
    _queueItemsStreamController.add(queueItems);
  }

  Future<void> _onPlayerPositionChanged(PlayerPositionUpdate arguments) async {
    final playerPosition = Duration(milliseconds: arguments.progress);
    _playerPositionStreamController.add(playerPosition);
  }

  @override
  Future<void> queueReorderItemsWithRequest(
    GoogleCastQueueReorderItemsRequest request,
  ) {
    return _hostApi.queueReorderItems(
      QueueReorderItemsRequestPigeon(
        itemsIds: request.itemsIds,
        beforeItemWithId: request.beforeItemWithId,
      ),
    );
  }

  @override
  Future<void> queueReorderItems({
    required List<int> itemsIds,
    required int? beforeItemWithId,
  }) {
    return queueReorderItemsWithRequest(
      GoogleCastQueueReorderItemsRequest(
        itemsIds: itemsIds,
        beforeItemWithId: beforeItemWithId,
      ),
    );
  }

  MediaInfo _toMediaInfo(GoogleCastMediaInformation mediaInfo) {
    return MediaInfo(
      contentId: mediaInfo.contentId,
      contentType: mediaInfo.contentType,
      streamType: mediaInfo.streamType.value,
      contentUrl: mediaInfo.contentUrl?.toString() ?? '',
      duration: mediaInfo.duration?.inSeconds ?? 0,
      customData: mediaInfo.customData,
      tracks: mediaInfo.tracks
          ?.map(
            (track) => MediaTrack(
              trackId: track.trackId,
              type: track.type.index,
              trackContentId: track.trackContentId ?? '',
              trackContentType: track.trackContentType,
              subtype: track.subtype?.index ?? 0,
              name: track.name ?? '',
              language: track.language?.toString() ?? '',
            ),
          )
          .toList(),
    );
  }

  MediaQueueItem _toMediaQueueItem(GoogleCastQueueItem item) {
    return MediaQueueItem(
      itemId: item.itemId ?? 0,
      preLoadTime: item.preLoadTime?.inSeconds ?? 0,
      startTime: item.startTime?.inSeconds ?? 0,
      playbackDuration: item.playbackDuration?.inSeconds ?? 0,
      media: _toMediaInfo(item.mediaInformation),
      autoplay: item.autoPlay,
      activeTrackIds: item.activeTrackIds,
      customData: item.customData,
    );
  }

  RepeatModePigeon _toRepeatMode(GoogleCastMediaRepeatMode mode) {
    switch (mode) {
      case GoogleCastMediaRepeatMode.off:
        return RepeatModePigeon.off;
      case GoogleCastMediaRepeatMode.all:
        return RepeatModePigeon.all;
      case GoogleCastMediaRepeatMode.single:
        return RepeatModePigeon.single;
      case GoogleCastMediaRepeatMode.allAndShuffle:
        return RepeatModePigeon.allAndShuffle;
      case GoogleCastMediaRepeatMode.unchanged:
        return RepeatModePigeon.off;
    }
  }

  MediaResumeStatePigeon _toResumeState(GoogleCastMediaResumeState state) {
    switch (state) {
      case GoogleCastMediaResumeState.play:
        return MediaResumeStatePigeon.play;
      case GoogleCastMediaResumeState.pause:
        return MediaResumeStatePigeon.pause;
      case GoogleCastMediaResumeState.unchanged:
        return MediaResumeStatePigeon.unchanged;
    }
  }

  GoggleCastMediaStatus _toMediaStatus(MediaStatus status) {
    return GoggleCastMediaStatus(
      mediaSessionID: status.mediaSessionId,
      playerState: _playerStateFromString(status.playerState),
      idleReason: _idleReasonFromString(status.idleReason),
      playbackRate: status.playbackRate,
      mediaInformation:
          status.media == null ? null : _toMediaInformation(status.media!),
      volume: status.volume.level,
      isMuted: status.volume.muted,
      repeatMode: _repeatModeFromString(status.repeatMode),
      currentItemId: status.currentItemId,
      activeTrackIds: status.activeTrackIds?.whereType<int>().toList(),
      liveSeekableRange: status.liveSeekableRange == null
          ? null
          : GoogleCastMediaLiveSeekableRange(
              start: Duration(seconds: status.liveSeekableRange!.start),
              end: Duration(seconds: status.liveSeekableRange!.end),
              isMovingWindow: status.liveSeekableRange!.isMovingWindow,
              isLiveDone: status.liveSeekableRange!.isLiveDone,
            ),
    );
  }

  GoogleCastQueueItem _toQueueItem(MediaQueueItem item) {
    return GoogleCastQueueItem(
      itemId: item.itemId,
      preLoadTime: Duration(seconds: item.preLoadTime),
      startTime: Duration(seconds: item.startTime),
      playbackDuration: Duration(seconds: item.playbackDuration),
      mediaInformation: item.media == null
          ? GoogleCastMediaInformation(
              contentId: '',
              streamType: CastMediaStreamType.none,
              contentType: '',
            )
          : _toMediaInformation(item.media!),
      autoPlay: item.autoplay,
      activeTrackIds: item.activeTrackIds?.whereType<int>().toList(),
      customData: item.customData?.cast<String, dynamic>(),
    );
  }

  GoogleCastMediaInformation _toMediaInformation(MediaInfo media) {
    return GoogleCastMediaInformation(
      contentId: media.contentId,
      streamType: CastMediaStreamType.fromMap(media.streamType),
      contentType: media.contentType,
      contentUrl: media.contentUrl.isEmpty ? null : Uri.tryParse(media.contentUrl),
      duration: Duration(seconds: media.duration),
      customData: media.customData?.cast<String, dynamic>(),
      tracks: media.tracks
          ?.whereType<MediaTrack>()
          .map(
            (track) => GoogleCastMediaTrack(
              trackId: track.trackId,
              type: _trackTypeFromIndex(track.type),
              trackContentId: track.trackContentId,
              trackContentType: track.trackContentType,
              subtype: _textTrackTypeFromIndex(track.subtype),
              name: track.name,
              language: Rfc5646Language.fromMap(track.language),
            ),
          )
          .toList(),
    );
  }

  CastMediaPlayerState _playerStateFromString(String value) {
    switch (value) {
      case 'IDLE':
        return CastMediaPlayerState.idle;
      case 'PLAYING':
        return CastMediaPlayerState.playing;
      case 'PAUSED':
        return CastMediaPlayerState.paused;
      case 'BUFFERING':
        return CastMediaPlayerState.buffering;
      case 'LOADING':
        return CastMediaPlayerState.loading;
      default:
        return CastMediaPlayerState.unknown;
    }
  }

  GoogleCastMediaIdleReason _idleReasonFromString(String value) {
    switch (value) {
      case 'FINISHED':
        return GoogleCastMediaIdleReason.finished;
      case 'CANCELED':
        return GoogleCastMediaIdleReason.cancelled;
      case 'INTERRUPTED':
        return GoogleCastMediaIdleReason.interrupted;
      case 'ERROR':
        return GoogleCastMediaIdleReason.error;
      default:
        return GoogleCastMediaIdleReason.none;
    }
  }

  GoogleCastMediaRepeatMode _repeatModeFromString(String value) {
    switch (value) {
      case 'ALL':
        return GoogleCastMediaRepeatMode.all;
      case 'SINGLE':
        return GoogleCastMediaRepeatMode.single;
      case 'ALL_AND_SHUFFLE':
        return GoogleCastMediaRepeatMode.allAndShuffle;
      default:
        return GoogleCastMediaRepeatMode.off;
    }
  }

  TrackType _trackTypeFromIndex(int index) {
    if (index < 0 || index >= TrackType.values.length) {
      return TrackType.unknown;
    }
    return TrackType.values[index];
  }

  TextTrackType _textTrackTypeFromIndex(int index) {
    if (index < 0 || index >= TextTrackType.values.length) {
      return TextTrackType.unknown;
    }
    return TextTrackType.values[index];
  }

  TextTrackStylePigeon _toTextTrackStylePigeon(TextTrackStyle style) {
    return TextTrackStylePigeon(
      backgroundColor: style.backgroundColor?.hexColor,
      customData: style.customData,
      edgeColor: style.edgeColor?.hexColor,
      fontFamily: style.fontFamily,
      fontGenericFamily: style.fontGenericFamily?.name,
      fontScale: style.fontScale,
      fontStyle: style.fontStyle?.name,
      foregroundColor: style.foregroundColor?.hexColor,
      windowColor: style.windowColor?.hexColor,
      windowRoundedCornerRadius: style.windowRoundedCornerRadius,
      windowType: style.windowType?.name,
    );
  }
}
