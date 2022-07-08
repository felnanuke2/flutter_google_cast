import 'package:google_cast/lib.dart';
import 'package:google_cast/models/android/android_media_information.dart';

class GoogleCastAndroidMediaStatus extends GoggleCastMediaStatus {
  GoogleCastAndroidMediaStatus({
    required super.mediaSessionID,
    required super.playerState,
    required super.playbackRate,
    required super.volume,
    required super.isMuted,
    required super.repeatMode,
    required super.queueHasCurrentItem,
    required super.queueHasNextItem,
    required super.queueHasPreviousItem,
    required super.queueHasLoadingItem,
    required super.preloadedItemId,
    required super.loadingItemId,
    super.activeTrackIds,
    super.adBreakStatus,
    super.currentItemId,
    super.currentQueueItem,
    super.idleReason,
    super.liveSeekableRange,
    super.mediaInformation,
    super.nextQueueItem,
  });
  factory GoogleCastAndroidMediaStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastAndroidMediaStatus(
      mediaSessionID: map['mediaSessionID']?.toInt() ?? 0,
      playerState: CastMediaPlayerState.values[map['playerState']],
      idleReason: map['idleReason'] != null
          ? GoogleCastMediaIdleReason.values[map['idleReason']]
          : null,
      playbackRate: map['playbackRate'] ?? 1,
      mediaInformation: map['mediaInfo'] != null
          ? GoogleCastMediaInformationAndroid.fromMap(
              Map<String, dynamic>.from(map['mediaInfo']))
          : null,

      volume: map['volume'] ?? 0,
      isMuted: map['isMuted'] ?? true,
      repeatMode: GoogleCastMediaRepeatMode.values[map['queueRepeatMode']],
      currentItemId: map['currentItemId']?.toInt(),
      queueHasCurrentItem: map['queueHasCurrentItem'] ?? false,
      // currentQueueItem: map['currentQueueItem'] != null
      //     ? GoogleCastQueueItem.fromMap(map['currentQueueItem'])
      //     : null,
      queueHasNextItem: map['queueHasNextItem'] ?? false,
      // nextQueueItem: map['nextQueueItem'] != null
      //     ? GoogleCastQueueItem.fromMap(map['nextQueueItem'])
      //     : null,
      queueHasPreviousItem: map['queueHasPreviousItem'] ?? false,
      queueHasLoadingItem: map['queueHasLoadingItem'] ?? false,
      preloadedItemId: map['preloadedItemId']?.toInt() ?? 0,
      loadingItemId: map['loadingItemId']?.toInt() ?? 0,
      activeTrackIds: List<int>.from(map['activeTrackIds'] ?? []),
      // adBreakStatus: map['adBreakStatus'] != null
      //     ? GoogleCastBrakeStatus.fromMap(map['adBreakStatus'])
      //     : null,
      // liveSeekableRange: map['liveSeekableRange'] != null
      //     ? GoogleCastMediaLiveSeekableRange.fromMap(map['liveSeekableRange'])
      //     : null,
      // queueData: map['queueData'] != null
      //     ? GoogleCastMediaQueueData.fromMap(map['queueData'])
      //     : null,
    );
  }
}
