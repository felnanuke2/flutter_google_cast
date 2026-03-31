import 'package:flutter_chrome_cast_platform_interface/src/entities/media_information.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/queue_item.dart';

/// Encapsulates arguments required to load media on a remote client.
class GoogleCastLoadMediaRequest {
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

  final GoogleCastMediaInformation mediaInfo;
  final bool autoPlay;
  final Duration playPosition;
  final double playbackRate;
  final List<int>? activeTrackIds;
  final String? credentials;
  final String? credentialsType;
  final Map<String, dynamic>? customData;
}

/// Encapsulates queue insertion arguments.
class GoogleCastQueueInsertItemsRequest {
  const GoogleCastQueueInsertItemsRequest({
    required this.items,
    this.beforeItemWithId,
  });

  final List<GoogleCastQueueItem> items;
  final int? beforeItemWithId;
}

/// Encapsulates queue insertion and playback arguments.
class GoogleCastQueueInsertItemAndPlayRequest {
  const GoogleCastQueueInsertItemAndPlayRequest({
    required this.item,
    required this.beforeItemWithId,
  });

  final GoogleCastQueueItem item;
  final int beforeItemWithId;
}

/// Encapsulates queue reordering arguments.
class GoogleCastQueueReorderItemsRequest {
  const GoogleCastQueueReorderItemsRequest({
    required this.itemsIds,
    this.beforeItemWithId,
  });

  final List<int> itemsIds;
  final int? beforeItemWithId;
}