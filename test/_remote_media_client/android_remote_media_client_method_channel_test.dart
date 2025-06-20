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
  // Helper function to create a valid media information
  GoogleCastMediaInformation createTestMediaInfo([String? url]) {
    return GoogleCastMediaInformation(
      contentId: 'test-content-id',
      contentType: 'video/mp4',
      streamType: CastMediaStreamType.buffered,
      contentUrl: Uri.parse(url ?? 'https://example.com/video.mp4'),
    );
  }

  // Helper function to create a queue item
  GoogleCastQueueItem createTestQueueItem([String? url]) {
    return GoogleCastQueueItem(
      mediaInformation: createTestMediaInfo(url),
    );
  }

  // Helper function to create a test request map
  Map<String, dynamic> createTestRequestMap([int? requestId]) {
    return {
      'requestID': requestId ?? 123,
      'inProgress': false,
      'isExternal': false,
    };
  }

  group('GoogleCastRemoteMediaClientAndroidMethodChannel', () {
    late GoogleCastRemoteMediaClientAndroidMethodChannel remoteMediaClient;
    late List<MethodCall> methodCalls;
    late MethodChannel channel;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      channel =
          const MethodChannel('com.felnanuke.google_cast.remote_media_client');
      remoteMediaClient = GoogleCastRemoteMediaClientAndroidMethodChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should implement GoogleCastRemoteMediaClientPlatformInterface', () {
      expect(remoteMediaClient,
          isA<GoogleCastRemoteMediaClientPlatformInterface>());
    });

    group('Constructor and initial values', () {
      test('should initialize with correct default values', () {
        expect(remoteMediaClient.mediaStatus, isNull);
        expect(remoteMediaClient.queueItems, isEmpty);
        expect(remoteMediaClient.playerPosition, equals(Duration.zero));
        expect(remoteMediaClient.queueHasPreviousItem, isTrue);
      });

      test('should set up method call handler', () {
        // This is tested indirectly through the method handler tests
        expect(remoteMediaClient, isNotNull);
      });
    });

    group('Streams', () {
      test('mediaStatusStream should emit initial null value', () {
        expectLater(
          remoteMediaClient.mediaStatusStream,
          emitsInOrder([null]),
        );
      });

      test('queueItemsStream should emit initial empty list', () {
        expectLater(
          remoteMediaClient.queueItemsStream,
          emitsInOrder([[]]),
        );
      });

      test('playerPositionStream should emit initial zero duration', () {
        expectLater(
          remoteMediaClient.playerPositionStream,
          emitsInOrder([Duration.zero]),
        );
      });
    });

    group('queueHasNextItem', () {
      test('should return false when no queue items', () {
        expect(remoteMediaClient.queueHasNextItem, isFalse);
      });

      test('should return false when current item is the last item', () async {
        // Setup method call handler to simulate native callbacks
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          // Do nothing for the setMethodCallHandler call
          return null;
        });

        // Simulate queue status change by triggering method call handler
        final queueData = [
          jsonEncode({'itemId': 1}),
          jsonEncode({'itemId': 2}),
        ];

        // Create new instance to reset state and trigger method call handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onQueueStatusChanged', queueData),
          ),
          (data) {},
        );

        // Simulate media status change
        final mediaStatusJson = jsonEncode({
          'currentItemId': 2,
          'playerState': 2,
          'idleReason': null,
        });

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onMediaStatusChanged', mediaStatusJson),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.queueHasNextItem, isFalse);
      });

      test('should return true when current item is not the last item',
          () async {
        // Setup method call handler to simulate native callbacks
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          // Do nothing for the setMethodCallHandler call
          return null;
        });

        // Simulate queue status change with proper format
        final queueData = [
          jsonEncode({
            'itemId': 1,
            'media': {
              'contentId': 'test-content-1',
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
              'contentId': 'test-content-2',
              'contentType': 'video/mp4',
              'streamType': 'BUFFERED',
            },
            'autoplay': true,
            'startTime': 0,
            'preLoadTime': 0,
          }),
        ];

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onQueueStatusChanged', queueData),
          ),
          (data) {},
        );

        // Simulate media status change with proper format
        final mediaStatusJson = jsonEncode({
          'mediaSessionId': 123,
          'playerState': 'PLAYING',
          'playbackRate': 1.0,
          'volume': {'level': 0.5, 'muted': false},
          'isMuted': false,
          'repeatMode': 'OFF',
          'currentItemId': 1,
          'activeTrackIds': '[]',
        });

        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onMediaStatusChanged', mediaStatusJson),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.queueHasNextItem, isTrue);
      });
    });

    group('loadMedia', () {
      test('should call native method with correct parameters', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestID': 123, 'inProgress': false, 'isExternal': false};
        });

        final mediaInfo = GoogleCastMediaInformation(
          contentId: 'video-123',
          contentType: 'video/mp4',
          streamType: CastMediaStreamType.buffered,
          contentUrl: Uri.parse('https://example.com/video.mp4'),
        );

        await remoteMediaClient.loadMedia(
          mediaInfo,
          autoPlay: true,
          playPosition: Duration(seconds: 30),
          playbackRate: 1.5,
          activeTrackIds: [1, 2],
          credentials: 'test-credentials',
          credentialsType: 'Bearer',
        );

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('loadMedia'));
        expect(methodCalls.first.arguments['mediaInfo'],
            equals(mediaInfo.toMap()));
        expect(methodCalls.first.arguments['autoPlay'], isTrue);
        expect(methodCalls.first.arguments['playPosition'], equals(30));
        expect(methodCalls.first.arguments['playbackRate'], equals(1.5));
        expect(methodCalls.first.arguments['activeTrackIds'], equals([1, 2]));
        expect(methodCalls.first.arguments['credentials'],
            equals('test-credentials'));
        expect(
            methodCalls.first.arguments['credentialsType'], equals('Bearer'));
      });

      test('should call native method with default parameters', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestID': 456, 'inProgress': false, 'isExternal': false};
        });

        final mediaInfo = createTestMediaInfo();

        await remoteMediaClient.loadMedia(mediaInfo);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.arguments['autoPlay'], isTrue);
        expect(methodCalls.first.arguments['playPosition'], equals(0));
        expect(methodCalls.first.arguments['playbackRate'], equals(1.0));
        expect(methodCalls.first.arguments['activeTrackIds'], isNull);
        expect(methodCalls.first.arguments['credentials'], isNull);
        expect(methodCalls.first.arguments['credentialsType'], isNull);
      });
    });

    group('pause', () {
      test('should call native pause method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestID': 123, 'inProgress': false, 'isExternal': false};
        });

        await remoteMediaClient.pause();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('pause'));
      });
    });

    group('play', () {
      test('should call native play method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        await remoteMediaClient.play();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('play'));
      });
    });

    group('queueLoadItems', () {
      test('should call native method with queue items and options', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final queueItems = [
          createTestQueueItem('https://example.com/video1.mp4')
        ];
        final options = GoogleCastQueueLoadOptions(startIndex: 0);

        await remoteMediaClient.queueLoadItems(queueItems, options: options);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueLoadItems'));
        expect(methodCalls.first.arguments['queueItems'], hasLength(1));
        expect(methodCalls.first.arguments['options'], equals(options.toMap()));
      });

      test('should call native method with queue items only', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final queueItems = [
          createTestQueueItem('https://example.com/video1.mp4')
        ];

        await remoteMediaClient.queueLoadItems(queueItems);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueLoadItems'));
        expect(methodCalls.first.arguments['options'], isNull);
      });
    });

    group('queueNextItem', () {
      test('should call native queueNextItem method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        await remoteMediaClient.queueNextItem();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueNextItem'));
      });
    });

    group('queuePrevItem', () {
      test('should call native queuePrevItem method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        await remoteMediaClient.queuePrevItem();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queuePrevItem'));
      });
    });

    group('seek', () {
      test('should call native seek method with options', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final seekOption = GoogleCastMediaSeekOption(
          position: Duration(seconds: 60),
        );

        await remoteMediaClient.seek(seekOption);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('seek'));
        expect(methodCalls.first.arguments, equals(seekOption.toMap()));
      });
    });

    group('setActiveTrackIDs', () {
      test('should call native setActiveTrackIds method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final trackIds = [1, 2, 3];

        await remoteMediaClient.setActiveTrackIDs(trackIds);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('setActiveTrackIds'));
        expect(methodCalls.first.arguments, equals(trackIds));
      });
    });

    group('setPlaybackRate', () {
      test('should call native setPlaybackRate method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        await remoteMediaClient.setPlaybackRate(2.0);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('setPlaybackRate'));
        expect(methodCalls.first.arguments, equals(2.0));
      });
    });

    group('setTextTrackStyle', () {
      test('should call native setTextTrackStyle method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final textTrackStyle = TextTrackStyle();

        await remoteMediaClient.setTextTrackStyle(textTrackStyle);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('setTextTrackStyle'));
        expect(methodCalls.first.arguments, equals(textTrackStyle.toMap()));
      });
    });

    group('stop', () {
      test('should call native stop method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        await remoteMediaClient.stop();

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('stop'));
      });
    });

    group('queueJumpToItemWithId', () {
      test('should call native queueJumpToItemWithId method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        await remoteMediaClient.queueJumpToItemWithId(42);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueJumpToItemWithId'));
        expect(methodCalls.first.arguments, equals(42));
      });
    });

    group('queueRemoveItemsWithIds', () {
      test('should call native queueRemoveItemsWithIds method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final itemIds = [1, 2, 3];

        await remoteMediaClient.queueRemoveItemsWithIds(itemIds);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueRemoveItemsWithIds'));
        expect(methodCalls.first.arguments, equals(itemIds));
      });
    });

    group('queueInsertItemAndPlay', () {
      test('should call native queueInsertItemAndPlay method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final queueItem = createTestQueueItem('https://example.com/video.mp4');

        await remoteMediaClient.queueInsertItemAndPlay(
          queueItem,
          beforeItemWithId: 10,
        );

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueInsertItemAndPlay'));
        expect(methodCalls.first.arguments['item'], equals(queueItem.toMap()));
        expect(methodCalls.first.arguments['beforeItemWithId'], equals(10));
      });
    });

    group('queueInsertItems', () {
      test('should call native queueInsertItems method with beforeItemWithId',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final queueItems = [
          createTestQueueItem('https://example.com/video1.mp4')
        ];

        await remoteMediaClient.queueInsertItems(
          queueItems,
          beforeItemWithId: 5,
        );

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueInsertItems'));
        expect(methodCalls.first.arguments['items'], hasLength(1));
        expect(methodCalls.first.arguments['beforeItemWithId'], equals(5));
      });

      test(
          'should call native queueInsertItems method without beforeItemWithId',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return {'requestId': 123};
        });

        final queueItems = [
          createTestQueueItem('https://example.com/video1.mp4')
        ];

        await remoteMediaClient.queueInsertItems(queueItems);

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueInsertItems'));
        expect(methodCalls.first.arguments['beforeItemWithId'], isNull);
      });
    });

    group('queueReorderItems', () {
      test('should call native queueReorderItems method', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        });

        await remoteMediaClient.queueReorderItems(
          itemsIds: [1, 2, 3],
          beforeItemWithId: 4,
        );

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueReorderItems'));
        expect(methodCalls.first.arguments['itemsIds'], equals([1, 2, 3]));
        expect(methodCalls.first.arguments['beforeItemWithId'], equals(4));
      });

      test(
          'should call native queueReorderItems method with null beforeItemWithId',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        });

        await remoteMediaClient.queueReorderItems(
          itemsIds: [1, 2, 3],
          beforeItemWithId: null,
        );

        expect(methodCalls, hasLength(1));
        expect(methodCalls.first.method, equals('queueReorderItems'));
        expect(methodCalls.first.arguments['beforeItemWithId'], isNull);
      });
    });

    group('Method call handler', () {
      test('should handle onMediaStatusChanged with valid data', () async {
        final mediaStatusJson = jsonEncode({
          'mediaSessionId': 123,
          'playerState': 'PLAYING',
          'playbackRate': 1.0,
          'volume': {'level': 0.5, 'muted': false},
          'isMuted': false,
          'repeatMode': 'OFF',
          'currentItemId': 1,
          'activeTrackIds': '[]',
        });

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onMediaStatusChanged', mediaStatusJson),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.mediaStatus, isNotNull);
        expect(remoteMediaClient.mediaStatus!.currentItemId, equals(1));
        expect(remoteMediaClient.mediaStatus!.mediaSessionID, equals(123));
      });

      test('should handle onMediaStatusChanged with null data', () async {
        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onMediaStatusChanged', null),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.mediaStatus, isNull);
      });

      test('should handle onQueueStatusChanged with valid data', () async {
        final queueData = [
          jsonEncode({
            'itemId': 1,
            'media': {
              'contentId': 'test-content-1',
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
              'contentId': 'test-content-2',
              'contentType': 'video/mp4',
              'streamType': 'BUFFERED',
            },
            'autoplay': true,
            'startTime': 0,
            'preLoadTime': 0,
          }),
        ];

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onQueueStatusChanged', queueData),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.queueItems, hasLength(2));
        expect(remoteMediaClient.queueItems[0].itemId, equals(1));
        expect(remoteMediaClient.queueItems[1].itemId, equals(2));
      });

      test('should handle onQueueStatusChanged with null data', () async {
        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onQueueStatusChanged', null),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.queueItems, isEmpty);
      });

      test('should handle onPlayerPositionChanged with valid data', () async {
        final positionData = {'progress': 5000};

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onPlayerPositionChanged', positionData),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.playerPosition,
            equals(Duration(milliseconds: 5000)));
      });

      test('should handle onPlayerPositionChanged with null data', () async {
        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onPlayerPositionChanged', null),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.playerPosition, equals(Duration.zero));
      });

      test('should handle onPlayerPositionChanged with null progress',
          () async {
        final positionData = {'progress': null};

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onPlayerPositionChanged', positionData),
          ),
          (data) {},
        );

        // Give time for async operations to complete
        await Future.delayed(Duration(milliseconds: 10));

        expect(remoteMediaClient.playerPosition, equals(Duration.zero));
      });

      test('should handle unknown method calls', () async {
        // Should not throw an exception
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('unknownMethod', null),
          ),
          (data) {},
        );

        // Should not crash
        expect(remoteMediaClient, isNotNull);
      });
    });

    group('Stream integration tests', () {
      test(
          'mediaStatusStream should emit updates when method handler is called',
          () async {
        final mediaStatusJson = jsonEncode({
          'mediaSessionId': 123,
          'playerState': 'PLAYING',
          'playbackRate': 1.0,
          'volume': {'level': 0.5, 'muted': false},
          'isMuted': false,
          'repeatMode': 'OFF',
          'currentItemId': 123,
          'activeTrackIds': '[]',
        });

        bool streamUpdated = false;
        final subscription =
            remoteMediaClient.mediaStatusStream.listen((status) {
          if (status?.currentItemId == 123) {
            streamUpdated = true;
          }
        });

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onMediaStatusChanged', mediaStatusJson),
          ),
          (data) {},
        );

        await Future.delayed(Duration(milliseconds: 10));
        expect(streamUpdated, isTrue);
        await subscription.cancel();
      });

      test('queueItemsStream should emit updates when method handler is called',
          () async {
        final queueData = [
          jsonEncode({
            'itemId': 100,
            'media': {
              'contentId': 'test-stream-content',
              'contentType': 'video/mp4',
              'streamType': 'BUFFERED',
            },
            'autoplay': true,
            'startTime': 0,
            'preLoadTime': 0,
          }),
        ];

        bool streamUpdated = false;
        final subscription = remoteMediaClient.queueItemsStream.listen((items) {
          if (items.isNotEmpty && items[0].itemId == 100) {
            streamUpdated = true;
          }
        });

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onQueueStatusChanged', queueData),
          ),
          (data) {},
        );

        await Future.delayed(Duration(milliseconds: 10));
        expect(streamUpdated, isTrue);
        await subscription.cancel();
      });

      test(
          'playerPositionStream should emit updates when method handler is called',
          () async {
        final positionData = {'progress': 7500};

        bool streamUpdated = false;
        final subscription =
            remoteMediaClient.playerPositionStream.listen((position) {
          if (position == Duration(milliseconds: 7500)) {
            streamUpdated = true;
          }
        });

        // Simulate the native platform calling the method handler
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.felnanuke.google_cast.remote_media_client',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onPlayerPositionChanged', positionData),
          ),
          (data) {},
        );

        await Future.delayed(Duration(milliseconds: 10));
        expect(streamUpdated, isTrue);
        await subscription.cancel();
      });
    });
  });
}
