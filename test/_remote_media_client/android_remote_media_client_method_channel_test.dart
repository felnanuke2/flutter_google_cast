import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_remote_media_client/android_remote_media_client_method_channel.dart';
import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';

void main() {
  group('GoogleCastRemoteMediaClientAndroidMethodChannel', () {
    late GoogleCastRemoteMediaClientAndroidMethodChannel remoteMediaClient;
    late List<MethodCall> methodCalls;
    const channel =
        MethodChannel('com.felnanuke.google_cast.remote_media_client');
    const channelName = 'com.felnanuke.google_cast.remote_media_client';

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    GoogleCastMediaInformation testMediaInfo({String contentId = 'cid'}) =>
        GoogleCastMediaInformation(
          contentId: contentId,
          contentType: 'video/mp4',
          streamType: CastMediaStreamType.buffered,
          contentUrl: Uri.parse('https://example.com/video.mp4'),
        );

    GoogleCastQueueItem testQueueItem() =>
        GoogleCastQueueItem(mediaInformation: testMediaInfo());

    void mockChannel(dynamic Function(MethodCall) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call);
        return handler(call);
      });
    }

    Future<void> simulatePlatformCall(String method, dynamic args) async {
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        channelName,
        const StandardMethodCodec()
            .encodeMethodCall(MethodCall(method, args)),
        (_) {},
      );
      // Allow microtask queue to settle.
      await Future.delayed(const Duration(milliseconds: 10));
    }

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      remoteMediaClient = GoogleCastRemoteMediaClientAndroidMethodChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    // -----------------------------------------------------------------------
    // Interface & initial state
    // -----------------------------------------------------------------------

    test('implements GoogleCastRemoteMediaClientPlatformInterface', () {
      expect(remoteMediaClient,
          isA<GoogleCastRemoteMediaClientPlatformInterface>());
    });

    test('initializes with correct default values', () {
      expect(remoteMediaClient.mediaStatus, isNull);
      expect(remoteMediaClient.queueItems, isEmpty);
      expect(remoteMediaClient.playerPosition, equals(Duration.zero));
      expect(remoteMediaClient.queueHasPreviousItem, isTrue);
      expect(remoteMediaClient.queueHasNextItem, isFalse);
    });

    // -----------------------------------------------------------------------
    // Streams – initial values
    // -----------------------------------------------------------------------

    test('mediaStatusStream emits initial null', () {
      expectLater(remoteMediaClient.mediaStatusStream, emitsInOrder([null]));
    });

    test('queueItemsStream emits initial empty list', () {
      expectLater(remoteMediaClient.queueItemsStream, emitsInOrder([[]]));
    });

    test('playerPositionStream emits initial zero duration', () {
      expectLater(
          remoteMediaClient.playerPositionStream, emitsInOrder([Duration.zero]));
    });

    // -----------------------------------------------------------------------
    // Outgoing method calls
    // -----------------------------------------------------------------------

    test('loadMedia sends correct arguments to the channel', () async {
      mockChannel((_) => null);

      final info = testMediaInfo(contentId: 'video-123');
      await remoteMediaClient.loadMedia(
        info,
        autoPlay: true,
        playPosition: const Duration(seconds: 30),
        playbackRate: 1.5,
        activeTrackIds: [1, 2],
        credentials: 'token',
        credentialsType: 'Bearer',
      );

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('loadMedia'));
      expect(methodCalls.first.arguments['mediaInfo'], equals(info.toMap()));
      expect(methodCalls.first.arguments['autoPlay'], isTrue);
      expect(methodCalls.first.arguments['playPosition'], equals(30));
      expect(methodCalls.first.arguments['playbackRate'], equals(1.5));
      expect(methodCalls.first.arguments['activeTrackIds'], equals([1, 2]));
      expect(methodCalls.first.arguments['credentials'], equals('token'));
      expect(methodCalls.first.arguments['credentialsType'], equals('Bearer'));
    });

    test('loadMedia forwards customData to the channel', () async {
      mockChannel((_) => null);

      await remoteMediaClient.loadMedia(
        testMediaInfo(),
        customData: {'Authorization': 'Bearer tok', 'X-Custom': 'v'},
      );

      expect(methodCalls.first.arguments['customData'],
          equals({'Authorization': 'Bearer tok', 'X-Custom': 'v'}));
    });

    test('loadMedia sends null customData when not provided', () async {
      mockChannel((_) => null);

      await remoteMediaClient.loadMedia(testMediaInfo());

      expect(methodCalls.first.arguments['customData'], isNull);
    });

    test('pause invokes pause on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.pause();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('pause'));
    });

    test('play invokes play on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.play();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('play'));
    });

    test('stop invokes stop on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.stop();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('stop'));
    });

    test('seek sends seek options to the channel', () async {
      mockChannel((_) => null);
      final option = GoogleCastMediaSeekOption(
        position: const Duration(seconds: 60),
      );
      await remoteMediaClient.seek(option);

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('seek'));
      expect(methodCalls.first.arguments, equals(option.toMap()));
    });

    test('queueLoadItems sends items and options to the channel', () async {
      mockChannel((_) => null);
      final items = [testQueueItem()];
      final opts = GoogleCastQueueLoadOptions(startIndex: 0);

      await remoteMediaClient.queueLoadItems(items, options: opts);

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('queueLoadItems'));
    });

    test('queueNextItem invokes queueNextItem on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueNextItem();

      expect(methodCalls.first.method, equals('queueNextItem'));
    });

    test('queuePrevItem invokes queuePrevItem on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queuePrevItem();

      expect(methodCalls.first.method, equals('queuePrevItem'));
    });

    test('setPlaybackRate invokes setPlaybackRate on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.setPlaybackRate(2.0);

      expect(methodCalls.first.method, equals('setPlaybackRate'));
      // The implementation sends the rate as a bare double (not wrapped in a map).
      expect(methodCalls.first.arguments, equals(2.0));
    });

    test('setActiveTrackIDs invokes setActiveTrackIds on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.setActiveTrackIDs([3, 4]);

      expect(methodCalls.first.method, equals('setActiveTrackIds'));
      expect(methodCalls.first.arguments, equals([3, 4]));
    });

    test('queueJumpToItemWithId invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueJumpToItemWithId(42);

      expect(methodCalls.first.method, equals('queueJumpToItemWithId'));
    });

    test('queueRemoveItemsWithIds invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueRemoveItemsWithIds([1, 2]);

      expect(methodCalls.first.method, equals('queueRemoveItemsWithIds'));
    });

    test('queueInsertItemAndPlay sends item to the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueInsertItemAndPlay(
        testQueueItem(),
        beforeItemWithId: 5,
      );

      expect(methodCalls.first.method, equals('queueInsertItemAndPlay'));
    });

    test('queueInsertItems sends items to the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueInsertItems([testQueueItem()],
          beforeItemWithId: 3);

      expect(methodCalls.first.method, equals('queueInsertItems'));
    });

    test('queueReorderItems sends reorder arguments to the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueReorderItems(
        itemsIds: [1, 2],
        beforeItemWithId: null,
      );

      expect(methodCalls.first.method, equals('queueReorderItems'));
    });

    // -----------------------------------------------------------------------
    // Incoming method calls (platform → Dart)
    // -----------------------------------------------------------------------

    test('onMediaStatusChanged updates mediaStatus', () async {
      final json = jsonEncode({
        'mediaSessionId': 123,
        'playerState': 'PLAYING',
        'playbackRate': 1.0,
        'volume': {'level': 0.5, 'muted': false},
        'isMuted': false,
        'repeatMode': 'OFF',
        'currentItemId': 1,
        'activeTrackIds': '[]',
        'liveSeekableRange': {
          'start': 0,
          'end': 3600,
          'isLiveDone': false,
          'isMovingWindow': true,
        },
      });

      await simulatePlatformCall('onMediaStatusChanged', json);

      expect(remoteMediaClient.mediaStatus, isNotNull);
      expect(remoteMediaClient.mediaStatus!.currentItemId, equals(1));
      expect(remoteMediaClient.mediaStatus!.mediaSessionID, equals(123));
      expect(remoteMediaClient.mediaStatus!.liveSeekableRange, isNotNull);
      expect(remoteMediaClient.mediaStatus!.liveSeekableRange!.end,
          equals(const Duration(seconds: 3600)));
    });

    test('onMediaStatusChanged with null clears mediaStatus', () async {
      await simulatePlatformCall('onMediaStatusChanged', null);

      expect(remoteMediaClient.mediaStatus, isNull);
    });

    test('onQueueStatusChanged updates queueItems', () async {
      final queueData = [
        jsonEncode({
          'itemId': 1,
          'media': {
            'contentId': 'c1',
            'contentType': 'video/mp4',
            'streamType': 'BUFFERED',
          },
          'autoplay': true,
          'startTime': 0,
          'preLoadTime': 0,
        }),
        jsonEncode({
          'itemId': 2,
          'media': {
            'contentId': 'c2',
            'contentType': 'video/mp4',
            'streamType': 'BUFFERED',
          },
          'autoplay': true,
          'startTime': 0,
          'preLoadTime': 0,
        }),
      ];

      await simulatePlatformCall('onQueueStatusChanged', queueData);

      expect(remoteMediaClient.queueItems, hasLength(2));
      expect(remoteMediaClient.queueItems[0].itemId, equals(1));
      expect(remoteMediaClient.queueItems[1].itemId, equals(2));
    });

    test('onQueueStatusChanged with null clears queueItems', () async {
      await simulatePlatformCall('onQueueStatusChanged', null);

      expect(remoteMediaClient.queueItems, isEmpty);
    });

    test('onPlayerPositionChanged updates playerPosition', () async {
      await simulatePlatformCall(
          'onPlayerPositionChanged', {'progress': 5000});

      expect(remoteMediaClient.playerPosition,
          equals(const Duration(milliseconds: 5000)));
    });

    test('onPlayerPositionChanged with null data keeps playerPosition zero',
        () async {
      await simulatePlatformCall('onPlayerPositionChanged', null);

      expect(remoteMediaClient.playerPosition, equals(Duration.zero));
    });

    test('onPlayerPositionChanged with null progress keeps playerPosition zero',
        () async {
      await simulatePlatformCall(
          'onPlayerPositionChanged', {'progress': null});

      expect(remoteMediaClient.playerPosition, equals(Duration.zero));
    });

    test('unknown method calls are handled gracefully', () async {
      await simulatePlatformCall('unknownMethod', null);

      expect(remoteMediaClient, isNotNull);
    });

    // -----------------------------------------------------------------------
    // Stream integration
    // -----------------------------------------------------------------------

    test('mediaStatusStream emits when onMediaStatusChanged is called',
        () async {
      final json = jsonEncode({
        'mediaSessionId': 99,
        'playerState': 'PLAYING',
        'playbackRate': 1.0,
        'volume': {'level': 0.5, 'muted': false},
        'isMuted': false,
        'repeatMode': 'OFF',
        'currentItemId': 99,
        'activeTrackIds': '[]',
      });

      var updated = false;
      final sub = remoteMediaClient.mediaStatusStream
          .listen((s) => updated = s?.currentItemId == 99);

      await simulatePlatformCall('onMediaStatusChanged', json);

      expect(updated, isTrue);
      await sub.cancel();
    });

    test('queueItemsStream emits when onQueueStatusChanged is called',
        () async {
      final queueData = [
        jsonEncode({
          'itemId': 100,
          'media': {
            'contentId': 'sc',
            'contentType': 'video/mp4',
            'streamType': 'BUFFERED',
          },
          'autoplay': true,
          'startTime': 0,
          'preLoadTime': 0,
        }),
      ];

      var updated = false;
      final sub = remoteMediaClient.queueItemsStream.listen(
          (items) => updated = items.isNotEmpty && items.first.itemId == 100);

      await simulatePlatformCall('onQueueStatusChanged', queueData);

      expect(updated, isTrue);
      await sub.cancel();
    });

    test('playerPositionStream emits when onPlayerPositionChanged is called',
        () async {
      var updated = false;
      final sub = remoteMediaClient.playerPositionStream.listen(
          (pos) => updated = pos == const Duration(milliseconds: 7500));

      await simulatePlatformCall(
          'onPlayerPositionChanged', {'progress': 7500});

      expect(updated, isTrue);
      await sub.cancel();
    });
  });
}
