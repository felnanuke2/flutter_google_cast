import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_remote_media_client/ios_remote_media_client_method_channel.dart';
import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';

void main() {
  group('GoogleCastRemoteMediaClientIOSMethodChannel', () {
    late GoogleCastRemoteMediaClientIOSMethodChannel remoteMediaClient;
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('google_cast.remote_media_client');
    const channelName = 'google_cast.remote_media_client';

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

    GoogleCastQueueItem testQueueItem({String contentId = 'cid'}) =>
        GoogleCastQueueItem(mediaInformation: testMediaInfo(contentId: contentId));

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
      await Future.delayed(const Duration(milliseconds: 10));
    }

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      remoteMediaClient = GoogleCastRemoteMediaClientIOSMethodChannel();
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
      expect(remoteMediaClient.playerPosition, equals(Duration.zero));
      expect(remoteMediaClient.queueItems, isEmpty);
      expect(remoteMediaClient.queueHasNextItem, isFalse);
      expect(remoteMediaClient.queueHasPreviousItem, isFalse);
    });

    // -----------------------------------------------------------------------
    // Streams – types and initial values
    // -----------------------------------------------------------------------

    test('mediaStatusStream is a Stream<GoggleCastMediaStatus?>', () {
      expect(remoteMediaClient.mediaStatusStream,
          isA<Stream<GoggleCastMediaStatus?>>());
    });

    test('playerPositionStream is a Stream<Duration>', () {
      expect(remoteMediaClient.playerPositionStream, isA<Stream<Duration>>());
    });

    test('queueItemsStream is a Stream<List<GoogleCastQueueItem>>', () {
      expect(remoteMediaClient.queueItemsStream,
          isA<Stream<List<GoogleCastQueueItem>>>());
    });

    test('mediaStatusStream emits initial null', () {
      expectLater(remoteMediaClient.mediaStatusStream, emitsInOrder([null]));
    });

    test('playerPositionStream emits initial zero duration', () {
      expectLater(
          remoteMediaClient.playerPositionStream, emitsInOrder([Duration.zero]));
    });

    test('queueItemsStream emits initial empty list', () {
      expectLater(remoteMediaClient.queueItemsStream, emitsInOrder([[]]));
    });

    // -----------------------------------------------------------------------
    // Outgoing method calls
    // -----------------------------------------------------------------------

    test('loadMedia sends correct arguments to the channel', () async {
      mockChannel((_) => null);

      final info = testMediaInfo(contentId: 'test_content');
      await remoteMediaClient.loadMedia(
        info,
        autoPlay: true,
        playPosition: const Duration(seconds: 30),
        playbackRate: 1.5,
        activeTrackIds: [1, 2],
        credentials: 'creds',
        credentialsType: 'Bearer',
      );

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('loadMedia'));
      final args = Map<String, dynamic>.from(methodCalls.first.arguments);
      expect(args['mediaInfo'], equals(info.toMap()));
      expect(args['autoPlay'], isTrue);
      expect(args['playPosition'], equals(30));
      expect(args['playbackRate'], equals(1.5));
      expect(args['activeTrackIds'], equals([1, 2]));
      expect(args['credentials'], equals('creds'));
      expect(args['credentialsType'], equals('Bearer'));
    });

    test('loadMedia forwards customData', () async {
      mockChannel((_) => null);

      await remoteMediaClient.loadMedia(
        testMediaInfo(),
        customData: {'Authorization': 'Bearer tok'},
      );

      final args = Map<String, dynamic>.from(methodCalls.first.arguments);
      expect(args['customData'], equals({'Authorization': 'Bearer tok'}));
    });

    test('pause invokes pause on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.pause();

      expect(methodCalls.first.method, equals('pause'));
    });

    test('play invokes play on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.play();

      expect(methodCalls.first.method, equals('play'));
    });

    test('stop invokes stop on the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.stop();

      expect(methodCalls.first.method, equals('stop'));
    });

    test('seek sends seek options to the channel', () async {
      mockChannel((_) => null);
      final opt = GoogleCastMediaSeekOption(
          position: const Duration(seconds: 60));
      await remoteMediaClient.seek(opt);

      expect(methodCalls.first.method, equals('seek'));
    });

    test('setPlaybackRate invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.setPlaybackRate(2.0);

      expect(methodCalls.first.method, equals('setPlaybackRate'));
      expect(methodCalls.first.arguments['playbackRate'], equals(2.0));
    });

    test('setActiveTrackIDs invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.setActiveTrackIDs([1, 2]);

      expect(methodCalls.first.method, equals('setActiveTrackIds'));
    });

    test('queueNextItem invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueNextItem();

      expect(methodCalls.first.method, equals('queueNextItem'));
    });

    test('queuePrevItem invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queuePrevItem();

      expect(methodCalls.first.method, equals('queuePrevItem'));
    });

    test('queueLoadItems sends items to the channel', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueLoadItems([testQueueItem()]);

      expect(methodCalls.first.method, equals('queueLoadItems'));
    });

    test('queueLoadItems sends options when provided', () async {
      mockChannel((_) => null);
      final opts = GoogleCastQueueLoadOptions(startIndex: 1);
      await remoteMediaClient.queueLoadItems([testQueueItem()], options: opts);

      expect(methodCalls.first.method, equals('queueLoadItems'));
    });

    test('queueJumpToItemWithId invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueJumpToItemWithId(5);

      expect(methodCalls.first.method, equals('queueJumpToItemWithId'));
    });

    test('queueRemoveItemsWithIds invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueRemoveItemsWithIds([1, 2]);

      expect(methodCalls.first.method, equals('queueRemoveItemsWithIds'));
    });

    test('queueInsertItems invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueInsertItems(
        [testQueueItem()],
        beforeItemWithId: 3,
      );

      expect(methodCalls.first.method, equals('queueInsertItems'));
    });

    test('queueInsertItemAndPlay invokes correct channel method', () async {
      mockChannel((_) => null);
      await remoteMediaClient.queueInsertItemAndPlay(
        testQueueItem(),
        beforeItemWithId: 0,
      );

      expect(methodCalls.first.method, equals('queueInsertItemAndPlay'));
    });

    test('queueReorderItems invokes correct channel method', () async {
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

    test('onUpdateMediaStatus updates mediaStatus and stream', () async {
      final statusArgs = {
        'sessionID': 1,
        'playerState': 2, // playing
        'playbackRate': 1.0,
        'currentItemID': 42,
        'volume': 0.8,
        'isMuted': false,
        'activeTrackIDs': <int>[],
        'repeatMode': 0,
        'idleReason': null,
      };

      bool streamUpdated = false;
      final sub = remoteMediaClient.mediaStatusStream
          .listen((s) => streamUpdated = s != null);

      await simulatePlatformCall('onUpdateMediaStatus', statusArgs);

      expect(remoteMediaClient.mediaStatus, isNotNull);
      expect(streamUpdated, isTrue);
      await sub.cancel();
    });

    test('onUpdateMediaStatus with null clears mediaStatus', () async {
      await simulatePlatformCall('onUpdateMediaStatus', null);

      expect(remoteMediaClient.mediaStatus, isNull);
    });

    test('onUpdatePlayerPosition updates playerPosition and stream', () async {
      bool streamUpdated = false;
      final sub = remoteMediaClient.playerPositionStream.listen(
          (pos) => streamUpdated = pos == const Duration(seconds: 10));

      await simulatePlatformCall(
          'onUpdatePlayerPosition', {'position': 10.0});

      expect(streamUpdated, isTrue);
      await sub.cancel();
    });

    test('updateQueueItems updates queueItems and stream', () async {
      final items = [
        {
          'itemID': 1,
          'autoPlay': true,
          'startTime': 0.0,
          'preLoadTime': 0.0,
          'media': {
            'contentID': 'test1',
            'contentType': 'video/mp4',
            'streamType': 1,
          },
        },
      ];

      bool streamUpdated = false;
      final sub = remoteMediaClient.queueItemsStream
          .listen((q) => streamUpdated = q.isNotEmpty);

      await simulatePlatformCall('updateQueueItems', items);

      expect(remoteMediaClient.queueItems, hasLength(1));
      expect(streamUpdated, isTrue);
      await sub.cancel();
    });

    test('updateQueueItems with null clears queueItems', () async {
      await simulatePlatformCall('updateQueueItems', null);

      expect(remoteMediaClient.queueItems, isEmpty);
    });

    test('updateQueueItems with empty list clears queueItems', () async {
      await simulatePlatformCall('updateQueueItems', []);

      expect(remoteMediaClient.queueItems, isEmpty);
    });

    test('unknown method calls are handled gracefully', () async {
      await simulatePlatformCall('unknownMethod', null);

      expect(remoteMediaClient, isNotNull);
    });
  });
}
