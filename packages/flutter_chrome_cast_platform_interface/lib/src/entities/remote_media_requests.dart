import 'package:flutter_chrome_cast_platform_interface/src/entities/media_information.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/queue_item.dart';

/// Encapsulates all arguments required to load media on a remote client.
class GoogleCastLoadMediaRequest {
  /// Creates a new [GoogleCastLoadMediaRequest].
  const GoogleCastLoadMediaRequest({
    required this.mediaInfo,
    this.autoPlay = true,
    this.playPosition = Duration.zero,
    this.playbackRate = 1.0,
    this.activeTrackIds,
    this.credentials,
    this.credentialsType,
    this.customData,
  });

  /// Media item to load on the Cast device.
  final GoogleCastMediaInformation mediaInfo;

  /// Whether to start playback automatically after loading.
  final bool autoPlay;

  /// Offset at which playback should begin.
  final Duration playPosition;

  /// Multiplier for playback rate (1.0 = normal speed).
  final double playbackRate;

  /// IDs of the tracks to activate.
  final List<int>? activeTrackIds;

  /// Optional credentials associated with the media request.
  final String? credentials;

  /// Type qualifier for [credentials].
  final String? credentialsType;

  /// Arbitrary data forwarded to the receiver application.
  final Map<String, dynamic>? customData;
}

/// Encapsulates arguments required to insert items into a Cast media queue.
class GoogleCastQueueInsertItemsRequest {
  /// Creates a new [GoogleCastQueueInsertItemsRequest].
  const GoogleCastQueueInsertItemsRequest({
    required this.items,
    this.beforeItemWithId,
  });

  /// Items to insert into the queue.
  final List<GoogleCastQueueItem> items;

  /// Item ID before which the new items are inserted; appends to end when null.
  final int? beforeItemWithId;
}

/// Encapsulates arguments required to insert an item and immediately play it.
class GoogleCastQueueInsertItemAndPlayRequest {
  /// Creates a new [GoogleCastQueueInsertItemAndPlayRequest].
  const GoogleCastQueueInsertItemAndPlayRequest({
    required this.item,
    required this.beforeItemWithId,
  });

  /// The queue item to insert and play.
  final GoogleCastQueueItem item;

  /// Item ID before which the new item is inserted.
  final int beforeItemWithId;
}

/// Encapsulates arguments required to reorder items in a Cast media queue.
class GoogleCastQueueReorderItemsRequest {
  /// Creates a new [GoogleCastQueueReorderItemsRequest].
  const GoogleCastQueueReorderItemsRequest({
    required this.itemsIds,
    this.beforeItemWithId,
  });

  /// IDs of items to reorder.
  final List<int> itemsIds;

  /// Item ID before which the reordered items are placed; appends to end when null.
  final int? beforeItemWithId;
}
