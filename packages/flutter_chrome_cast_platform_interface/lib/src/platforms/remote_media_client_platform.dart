import 'package:flutter_chrome_cast_platform_interface/src/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/load_options.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/media_information.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/remote_media_requests.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/queue_item.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Platform interface for Google Cast remote media client functionality.
abstract class GoogleCastRemoteMediaClientPlatformInterface
    extends PlatformInterface {
  static final Object _token = Object();

  /// Creates a new [GoogleCastRemoteMediaClientPlatformInterface].
  GoogleCastRemoteMediaClientPlatformInterface() : super(token: _token);

  static GoogleCastRemoteMediaClientPlatformInterface? _instance;

  /// The current registered platform implementation.
  ///
  /// Throws [UnimplementedError] if no implementation has been registered.
  static GoogleCastRemoteMediaClientPlatformInterface get instance {
    return _instance ??
        (throw UnimplementedError(
          'No implementation registered for GoogleCastRemoteMediaClientPlatformInterface. '
          'Make sure to include a platform implementation package such as '
          'flutter_chrome_cast_android or flutter_chrome_cast_ios.',
        ));
  }

  /// Registers a platform-specific implementation.
  ///
  /// Called by endorsed platform packages in their [registerWith] method.
  static set instance(GoogleCastRemoteMediaClientPlatformInterface instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Current media status of the remote media client.
  GoggleCastMediaStatus? get mediaStatus;

  /// Stream of media status changes.
  Stream<GoggleCastMediaStatus?> get mediaStatusStream;

  /// Current player position.
  Duration get playerPosition;

  /// Stream of player position changes.
  Stream<Duration> get playerPositionStream;

  /// Stream of queue items changes.
  Stream<List<GoogleCastQueueItem>> get queueItemsStream;

  /// Current list of queue items.
  List<GoogleCastQueueItem> get queueItems;

  /// Whether the queue has a next item.
  bool get queueHasNextItem;

  /// Whether the queue has a previous item.
  bool get queueHasPreviousItem;

  /// Loads media on the remote media client.
  ///
  /// [customData] is an optional arbitrary data map that is forwarded to the
  /// Cast receiver application via the standard Google Cast SDK
  /// `MediaLoadRequestData.customData` field. The receiver application can
  /// read this map to configure playback — for example, to inject custom HTTP
  /// request headers for adaptive streams (DASH/HLS) when using a custom
  /// receiver.
  Future<void> loadMediaWithRequest(
    GoogleCastLoadMediaRequest request,
  );

  /// Loads media on the remote media client.
  @Deprecated('Use loadMediaWithRequest to reduce primitive obsession.')
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
    Map<String, dynamic>? customData,
  }) {
    return loadMediaWithRequest(
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

  /// Loads queue items on the remote media client.
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  });

  /// Sets the playback rate.
  Future<void> setPlaybackRate(double rate);

  /// Sets the active track IDs.
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs);

  /// Sets the text track style.
  Future<void> setTextTrackStyle(TextTrackStyle textTrackStyle);

  /// Pauses media playback.
  Future<void> pause();

  /// Starts or resumes media playback.
  Future<void> play();

  /// Stops media playback.
  Future<void> stop();

  /// Plays the next item in the queue.
  Future<void> queueNextItem();

  /// Plays the previous item in the queue.
  Future<void> queuePrevItem();

  /// Seeks to a specific position in the media.
  Future<void> seek(GoogleCastMediaSeekOption option);

  /// Inserts items into the queue.
  Future<void> queueInsertItemsWithRequest(
    GoogleCastQueueInsertItemsRequest request,
  );

  /// Inserts items into the queue.
  @Deprecated('Use queueInsertItemsWithRequest to reduce primitive obsession.')
  Future<void> queueInsertItems(
    List<GoogleCastQueueItem> items, {
    int? beforeItemWithId,
  }) {
    return queueInsertItemsWithRequest(
      GoogleCastQueueInsertItemsRequest(
        items: items,
        beforeItemWithId: beforeItemWithId,
      ),
    );
  }

  /// Inserts an item into the queue and plays it.
  Future<void> queueInsertItemAndPlayWithRequest(
    GoogleCastQueueInsertItemAndPlayRequest request,
  );

  /// Inserts an item into the queue and plays it.
  @Deprecated(
    'Use queueInsertItemAndPlayWithRequest to reduce primitive obsession.',
  )
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  }) {
    return queueInsertItemAndPlayWithRequest(
      GoogleCastQueueInsertItemAndPlayRequest(
        item: item,
        beforeItemWithId: beforeItemWithId,
      ),
    );
  }

  /// Removes items from the queue by their IDs.
  Future<void> queueRemoveItemsWithIds(
    List<int> itemIds,
  );

  /// Jumps to a specific item in the queue by its ID.
  Future<void> queueJumpToItemWithId(int itemId);

  /// Reorders items in the queue.
  Future<void> queueReorderItemsWithRequest(
    GoogleCastQueueReorderItemsRequest request,
  );

  /// Reorders items in the queue.
  ///
  /// [itemsIds] - List of IDs of the items to reorder.
  /// [beforeItemWithId] - The ID of the item before which the reordered items will be placed.
  ///                     If null, the items will be placed at the end of the queue.
  @Deprecated('Use queueReorderItemsWithRequest to reduce primitive obsession.')
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
}
