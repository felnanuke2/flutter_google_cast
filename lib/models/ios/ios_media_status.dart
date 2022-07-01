import 'package:google_cast/common/repeat_mode.dart';
import 'package:google_cast/entities/cast_media_status.dart';
import 'package:google_cast/enums/idle_reason.dart';
import 'package:google_cast/enums/player_state.dart';
import 'package:google_cast/models/ios/ios_media_information.dart';

class GoogleCastIOSMediaStatus extends GoggleCastMediaStatus {
  GoogleCastIOSMediaStatus({
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
    // super.queueData,
  });

  factory GoogleCastIOSMediaStatus.fromMap(Map<String, dynamic> map) {
    return GoogleCastIOSMediaStatus(
      mediaSessionID: map['mediaSessionID']?.toInt() ?? 0,
      playerState: CastMediaPlayerState.values[map['playerState']],
      idleReason: map['idleReason'] != null
          ? GoogleCastMediaIdleReason.values[map['idleReason']]
          : null,
      playbackRate: map['playbackRate'] ?? 0,
      mediaInformation: map['mediaInformation'] != null
          ? GoogleCastMediaInformationIOS.fromMap(
              Map<String, dynamic>.from(map['mediaInformation']))
          : null,

      volume: map['volume'] ?? 0,
      isMuted: map['isMuted'] ?? true,
      repeatMode: GoogleCastMediaRepeatMode.values[map['repeatMode']],
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
