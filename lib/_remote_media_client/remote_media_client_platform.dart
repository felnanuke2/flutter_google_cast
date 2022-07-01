import 'package:google_cast/entities/cast_media_status.dart';
import 'package:google_cast/entities/load_options.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/media_seek_option.dart';
import 'package:google_cast/entities/queue_item.dart';
import 'package:google_cast/entities/request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GoogleCastRemoteMediaClientPlatformInterface
    implements PlatformInterface {
  GoggleCastMediaStatus? get mediaStatus;

  Stream<GoggleCastMediaStatus?> get mediaStatusStream;

  Duration get playerPosition;

  Stream<Duration> get playerPositionStream;

  Future<GoogleCastRequest?> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  });

  Future<GoogleCastRequest?> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  });

  Future<GoogleCastRequest> setPlaybackRate(double rate);

  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs);

  Future<GoogleCastRequest> setTextTrackStyle(TextTrackStyle textTrackStyle);

  Future<GoogleCastRequest> pause();

  Future<GoogleCastRequest> play();

  Future<GoogleCastRequest> stop();

  Future<GoogleCastRequest> queueNextItem();

  Future<GoogleCastRequest> queuePrevItem();

  Future<GoogleCastRequest> seek(GoogleCastMediaSeekOption option);

  Future<GoogleCastRequest> queueInsertItems(
    List<GoogleCastQueueItem> items,
    int beforeItemWithId,
  );

  Future<GoogleCastRequest> queueRemoveItemsWithIds(
    List<int> itemIds,
  );

  Future<GoogleCastRequest> queueJumpToItemWithId(int itemId);
}
