import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:google_cast/entities/cast_media_status.dart';
import 'package:google_cast/entities/load_options.dart';
import 'package:google_cast/entities/media_seek_option.dart';
import 'package:google_cast/entities/queue_item.dart';
import 'package:google_cast/entities/request.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/models/ios/ios_media_information.dart';
import 'package:google_cast/models/ios/ios_media_status.dart';
import 'package:google_cast/models/ios/ios_request.dart';
import 'package:rxdart/rxdart.dart';

class GoogleCastRemoteMediaClientIOSMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  GoogleCastRemoteMediaClientIOSMethodChannel() {
    _channel.setMethodCallHandler(_methodCallHandler);
  }

  final _channel = const MethodChannel('google_cast.remote_media_client');

  final _mediaStatusStreamController = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);

  final _playerPositionStreamController = BehaviorSubject<Duration>()
    ..add(Duration.zero);

  @override
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusStreamController.value;

  @override
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusStreamController.stream;

  @override
  Duration get playerPosition => _playerPositionStreamController.value;

  @override
  Stream<Duration> get playerPositionStream =>
      _playerPositionStreamController.stream;

  @override
  Future<GoogleCastRequest?> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  }) async {
    mediaInfo as GoogleCastIOSMediaInformation;
    final result = await _channel.invokeMethod(
        'loadMedia',
        mediaInfo.toMap()
          ..addAll(
            {
              'autoPlay': autoPlay,
              'playPosition': playPosition.inSeconds,
              'playbackRate': playbackRate,
              'activeTrackIds': activeTrackIds,
              'credentials': credentials,
              'credentialsType': credentialsType,
            }..removeWhere((key, value) => value == null),
          ));
    if (result == null) {
      if (kDebugMode) print('load media failed. current session is null');
      return null;
    }
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> pause() async {
    final result = await _channel.invokeMethod('pause');
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> play() async {
    final result = await _channel.invokeMethod('play');
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs) async {
    final result = await _channel.invokeMethod(
        'setActiveTrackIDs', activeTrackIDs.toList());
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> setPlaybackRate(double rate) async {
    final result = await _channel.invokeMethod('setPlaybackRate', rate);
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> setTextTrackStyle(
      TextTrackStyle textTrackStyle) async {
    final result = await _channel.invokeMethod(
        'setTextTrackStyle', textTrackStyle.toMap());
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> stop() async {
    final result = await _channel.invokeMethod('stop');
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> seek(GoogleCastMediaSeekOption option) async {
    final result = await _channel.invokeMethod('seek', option.toMap());
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> queueNextItem() async {
    final result = await _channel.invokeMethod('queueNextItem');
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> queuePrevItem() async {
    final result = await _channel.invokeMethod('queuePrevItem');
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

// MARK: - MethodCallHandler
  Future _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onUpdateMediaStatus":
        return await _onUpdateMediaStatus(call.arguments);
      case "onUpdatePlayerPosition":
        return await _onUpdatePlayerPosition(call.arguments);
      default:
    }
  }

  Future _onUpdatePlayerPosition(int seconds) async {
    final duration = Duration(seconds: seconds);
    _playerPositionStreamController.add(duration);
  }

  _onUpdateMediaStatus(arguments) {
    if (arguments != null) {
      arguments = Map<String, dynamic>.from(arguments);
      final mediaStatus = GoogleCastIOSMediaStatus.fromMap(arguments);
      _mediaStatusStreamController.add(mediaStatus);
    }
  }

  @override
  Future<GoogleCastRequest?> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  }) async {
    final result = await _channel.invokeMethod(
      'queueLoadItems',
      {
        'items': queueItems.map((item) => item.toMap()).toList(),
        if (options != null) 'options': options.toMap(),
      },
    );
    if (result == null) return null;
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> queueInsertItems(
      List<GoogleCastQueueItem> items, int beforeItemWithId) {
    // TODO: implement queueInsertItems
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
}
