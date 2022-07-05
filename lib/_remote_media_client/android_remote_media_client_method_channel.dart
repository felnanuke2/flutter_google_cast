import 'package:google_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:google_cast/entities/cast_media_status.dart';
import 'package:google_cast/entities/load_options.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/queue_item.dart';
import 'package:google_cast/entities/media_seek_option.dart';
import 'package:google_cast/entities/request.dart';
import 'package:rxdart/subjects.dart';

class GoogleCastRemoteMediaClientAndroidMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  final _mediaStatusStreamController = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);

  @override
  Future<GoogleCastRequest?> loadMedia(GoogleCastMediaInformation mediaInfo,
      {bool autoPlay = true,
      Duration playPosition = Duration.zero,
      double playbackRate = 1.0,
      List<int>? activeTrackIds,
      String? credentials,
      String? credentialsType}) {
    // TODO: implement loadMedia
    throw UnimplementedError();
  }

  @override
  // TODO: implement mediaStatus
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusStreamController.value;

  @override
  // TODO: implement mediaStatusStream
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusStreamController.stream;

  @override
  // TODO: implement queueItems
  List<GoogleCastQueueItem> get queueItems => throw UnimplementedError();

  @override
  // TODO: implement queueItemsStream
  Stream<List<GoogleCastQueueItem>> get queueItemsStream =>
      throw UnimplementedError();

  @override
  // TODO: implement playerPosition
  Duration get playerPosition => throw UnimplementedError();

  @override
  // TODO: implement playerPositionStream
  Stream<Duration> get playerPositionStream => throw UnimplementedError();

  @override
  Future<GoogleCastRequest> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> play() {
    // TODO: implement play
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest?> queueLoadItems(
      List<GoogleCastQueueItem> queueItems,
      {GoogleCastQueueLoadOptions? options}) {
    // TODO: implement queueLoadItems
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> queueNextItem() {
    // TODO: implement queueNextItem
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> queuePrevItem() {
    // TODO: implement queuePrevItem
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> seek(GoogleCastMediaSeekOption option) {
    // TODO: implement seek
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs) {
    // TODO: implement setActiveTrackIDs
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setPlaybackRate(double rate) {
    // TODO: implement setPlaybackRate
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setTextTrackStyle(TextTrackStyle textTrackStyle) {
    // TODO: implement setTextTrackStyle
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> queueJumpToItemWithId(int itemId) {
    // TODO: implement queueJumpToItemWithId
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> queueRemoveItemsWithIds(List<int> itemIds) {
    // TODO: implement queueRemoveItemsWithIds
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> queueInsertItemAndPlay(GoogleCastQueueItem item,
      {required int beforeItemWithId}) {
    // TODO: implement queueInsertItemAndPlay
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> queueInsertItems(List<GoogleCastQueueItem> items,
      {required int beforeItemWithId}) {
    // TODO: implement queueInsertItems
    throw UnimplementedError();
  }

  @override
  // TODO: implement queueHasNextItem
  bool get queueHasNextItem => throw UnimplementedError();

  @override
  // TODO: implement queueHasPreviousItem
  bool get queueHasPreviousItem => throw UnimplementedError();
}
