import 'dart:convert';

import '../entities/media_information.dart';

///Represents an item in a media queue.
class CastQueueItem {
  /// Array of Track trackIds that should be active. If the array is not provided, the default tracks will be active. If two incompatible trackIds are provided (for example two active audio tracks) the command will fail with INVALID_PARAMETER.
  final List<int>? activeTrackIds;

  /// Whether the media will automatically play.
  final bool autoplay;

  /// Custom data set by the receiver application.
  final Map<String, dynamic>? customData;

  /// Unique identifier of the item in the queue. If used in chrome.cast.media.QueueLoad or chrome.cast.media.QueueInsert it must be null (as it will be assigned by the receiver when an item is first created/inserted). For other operations it is mandatory.
  final int? itemId;

  /// Media description.
  final GoogleCastMediaInformation? media;

  /// Playback duration of the item in seconds. If it is larger than the actual duration - startTime it will be limited to the actual duration - startTime. It can be negative, in such case the duration will be the actual item duration minus the duration provided. A duration of value zero effectively means that the item will not be played.
  final Duration? playbackDuration;

  /// This parameter is a hint for the receiver to preload this media item before it is played. It allows for a smooth transition between items played from the queue.
  ///The time is expressed in seconds, relative to the beginning of this item playback (usually the end of the previous item playback). Only positive values are valid. For example, if the value is 10 seconds, this item will be preloaded 10 seconds before the previous item has finished. The receiver will try to honor this value but will not guarantee it, for example if the value is larger than the previous item duration the receiver may just preload this item shortly after the previous item has started playing (there will never be two items being preloaded in parallel). Also, if an item is inserted in the queue just after the currentItem and the time to preload is higher than the time left on the currentItem, the preload will just happen as soon as possible.
  final Duration? preloadTime;

  /// Seconds from the beginning of the media to start playback.
  final Duration? startTime;
  CastQueueItem({
    this.activeTrackIds,
    this.autoplay = true,
    this.customData,
    this.itemId,
    required this.media,
    this.playbackDuration,
    this.preloadTime,
    this.startTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'activeTrackIds': activeTrackIds,
      'autoplay': autoplay,
      'customData': customData,
      'itemId': itemId,
      // 'media': media?.toMap(),
      'playbackDuration': playbackDuration?.inSeconds,
      'preloadTime': preloadTime?.inSeconds,
      'startTime': startTime?.inSeconds,
    }..removeWhere((key, value) => value == null);
  }

  factory CastQueueItem.fromMap(Map<String, dynamic> map) {
    return CastQueueItem(
      activeTrackIds: map['activeTrackIds'] != null
          ? List<int>.from(map['activeTrackIds'])
          : null,
      autoplay: map['autoplay'] ?? false,
      customData: map['customData'] != null
          ? Map<String, dynamic>.from(map['customData'])
          : null,
      itemId: map['itemId']?.toInt(),
      media: null,
      // media: map['media'] != null
      //     ? GoogleCastMediaInformation.fromMap(map['media'])
      //     : null,
      playbackDuration: map['playbackDuration'] != null
          ? Duration(seconds: (map['playbackDuration'])?.toInt() ?? 0)
          : null,
      preloadTime: map['preloadTime'] != null
          ? Duration(seconds: map['preloadTime']?.toInt() ?? 0)
          : null,
      startTime: map['startTime'] != null
          ? Duration(seconds: map['startTime']?.toInt() ?? 0)
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory CastQueueItem.fromJson(String source) =>
      CastQueueItem.fromMap(json.decode(source));

  CastQueueItem copyWith({
    List<int>? activeTrackIds,
    bool? autoplay,
    Map<String, dynamic>? customData,
    int? itemId,
    GoogleCastMediaInformation? media,
    Duration? playbackDuration,
    Duration? preloadTime,
    Duration? startTime,
  }) {
    return CastQueueItem(
      activeTrackIds: activeTrackIds ?? this.activeTrackIds,
      autoplay: autoplay ?? this.autoplay,
      customData: customData ?? this.customData,
      itemId: itemId ?? this.itemId,
      media: media ?? this.media,
      playbackDuration: playbackDuration ?? this.playbackDuration,
      preloadTime: preloadTime ?? this.preloadTime,
      startTime: startTime ?? this.startTime,
    );
  }
}
