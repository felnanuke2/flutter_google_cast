import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        'packages/flutter_chrome_cast_platform_interface/lib/src/pigeon/remote_media_client_pigeon.g.dart',
    kotlinOut:
        'packages/flutter_chrome_cast_android/android/src/main/kotlin/com/felnanuke/google_cast/pigeon/RemoteMediaClientPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.felnanuke.google_cast.pigeon',
      includeErrorClass: false,
    ),
    swiftOut:
        'packages/flutter_chrome_cast_ios/ios/flutter_chrome_cast/Sources/flutter_chrome_cast/RemoteMediaClientPigeon.g.swift',
    swiftOptions: SwiftOptions(
      includeErrorClass: false,
    ),
    dartPackageName: 'flutter_chrome_cast_platform_interface',
  ),
)
enum RepeatModePigeon {
  off,
  all,
  single,
  allAndShuffle,
}

enum MediaResumeStatePigeon {
  play,
  pause,
  unchanged,
}

/// Media track information
class MediaTrack {
  MediaTrack({
    required this.trackId,
    required this.type,
    required this.trackContentId,
    required this.trackContentType,
    required this.subtype,
    required this.name,
    required this.language,
  });

  int trackId;
  int type;
  String trackContentId;
  String trackContentType;
  int subtype;
  String name;
  String language;
}

/// Live seekable range for live media streams
class LiveSeekableRange {
  LiveSeekableRange({
    required this.start,
    required this.end,
    required this.isMovingWindow,
    required this.isLiveDone,
  });

  int start;
  int end;
  bool isMovingWindow;
  bool isLiveDone;
}

/// Media information including content and track details
class MediaInfo {
  MediaInfo({
    required this.contentId,
    required this.contentType,
    required this.streamType,
    required this.contentUrl,
    required this.duration,
    this.customData,
    this.tracks,
  });

  String contentId;
  String contentType;
  String streamType;
  String contentUrl;
  int duration;
  Map<String, Object?>? customData;
  List<MediaTrack?>? tracks;
}

/// Volume information
class Volume {
  Volume({
    required this.level,
    required this.muted,
  });

  double level;
  bool muted;
}

/// Media queue item
class MediaQueueItem {
  MediaQueueItem({
    required this.itemId,
    required this.preLoadTime,
    required this.startTime,
    required this.playbackDuration,
    this.media,
    required this.autoplay,
    this.activeTrackIds,
    this.customData,
  });

  int itemId;
  int preLoadTime;
  int startTime;
  int playbackDuration;
  MediaInfo? media;
  bool autoplay;
  List<int?>? activeTrackIds;
  Map<String, Object?>? customData;
}

/// Complete media status
class MediaStatus {
  MediaStatus({
    required this.mediaSessionId,
    required this.playerState,
    required this.idleReason,
    required this.playbackRate,
    this.media,
    required this.volume,
    required this.repeatMode,
    required this.currentItemId,
    this.activeTrackIds,
    this.liveSeekableRange,
  });

  int mediaSessionId;
  String playerState;
  String idleReason;
  double playbackRate;
  MediaInfo? media;
  Volume volume;
  String repeatMode;
  int currentItemId;
  List<int?>? activeTrackIds;
  LiveSeekableRange? liveSeekableRange;
}

class QueueLoadOptionsPigeon {
  QueueLoadOptionsPigeon({
    required this.startIndex,
    required this.playPosition,
    required this.repeatMode,
    this.customData,
  });

  int startIndex;
  int playPosition;
  RepeatModePigeon repeatMode;
  Map<String, Object?>? customData;
}

class SeekOptionPigeon {
  SeekOptionPigeon({
    required this.position,
    required this.relative,
    required this.resumeState,
    required this.seekToInfinity,
  });

  int position;
  bool relative;
  MediaResumeStatePigeon resumeState;
  bool seekToInfinity;
}

class SetPlaybackRateRequestPigeon {
  SetPlaybackRateRequestPigeon({
    required this.rate,
  });

  double rate;
}

class LoadMediaRequestPigeon {
  LoadMediaRequestPigeon({
    required this.mediaInfo,
    required this.autoPlay,
    required this.playPosition,
    required this.playbackRate,
    this.activeTrackIds,
    this.credentials,
    this.credentialsType,
    this.customData,
  });

  MediaInfo mediaInfo;
  bool autoPlay;
  int playPosition;
  double playbackRate;
  List<int?>? activeTrackIds;
  String? credentials;
  String? credentialsType;
  Map<String, Object?>? customData;
}

class QueueLoadRequestPigeon {
  QueueLoadRequestPigeon({
    required this.items,
    this.options,
  });

  List<MediaQueueItem?> items;
  QueueLoadOptionsPigeon? options;
}

class QueueInsertItemsRequestPigeon {
  QueueInsertItemsRequestPigeon({
    required this.items,
    this.beforeItemWithId,
  });

  List<MediaQueueItem?> items;
  int? beforeItemWithId;
}

class QueueInsertItemAndPlayRequestPigeon {
  QueueInsertItemAndPlayRequestPigeon({
    required this.item,
    required this.beforeItemWithId,
  });

  MediaQueueItem item;
  int beforeItemWithId;
}

class QueueReorderItemsRequestPigeon {
  QueueReorderItemsRequestPigeon({
    required this.itemsIds,
    this.beforeItemWithId,
  });

  List<int?> itemsIds;
  int? beforeItemWithId;
}

/// Player position update
class PlayerPositionUpdate {
  PlayerPositionUpdate({
    required this.progress,
    required this.duration,
  });

  int progress;
  int duration;
}

class TextTrackStylePigeon {
  TextTrackStylePigeon({
    this.backgroundColor,
    this.customData,
    this.edgeColor,
    this.fontFamily,
    this.fontGenericFamily,
    this.fontScale,
    this.fontStyle,
    this.foregroundColor,
    this.windowColor,
    this.windowRoundedCornerRadius,
    this.windowType,
  });

  String? backgroundColor;
  Map<String, Object?>? customData;
  String? edgeColor;
  String? fontFamily;
  String? fontGenericFamily;
  int? fontScale;
  String? fontStyle;
  String? foregroundColor;
  String? windowColor;
  double? windowRoundedCornerRadius;
  String? windowType;
}

@HostApi()
abstract class RemoteMediaClientHostApi {
  void loadMedia(LoadMediaRequestPigeon request);

  void queueLoadItems(QueueLoadRequestPigeon request);

  void queueInsertItems(QueueInsertItemsRequestPigeon request);

  void queueInsertItemAndPlay(QueueInsertItemAndPlayRequestPigeon request);

  void queueNextItem();

  void queuePrevItem();

  void queueJumpToItemWithId(int itemId);

  void queueRemoveItemsWithIds(List<int?> itemIds);

  void queueReorderItems(QueueReorderItemsRequestPigeon request);

  void seek(SeekOptionPigeon request);

  void setActiveTrackIds(List<int?> trackIds);

  void setPlaybackRate(SetPlaybackRateRequestPigeon request);

  void setTextTrackStyle(TextTrackStylePigeon textTrackStyle);

  void play();

  void pause();

  void stop();
}

@FlutterApi()
abstract class RemoteMediaClientFlutterApi {
  void onMediaStatusChanged(MediaStatus? status);

  void onQueueStatusChanged(List<MediaQueueItem?> queueItems);

  void onPlayerPositionChanged(PlayerPositionUpdate update);
}
