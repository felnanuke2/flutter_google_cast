import 'package:flutter_chrome_cast_ios/flutter_chrome_cast_ios.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCastRemoteMediaClientIOSMethodChannel', () {
    late GoogleCastRemoteMediaClientIOSMethodChannel remoteMediaClient;

    setUp(() {
      remoteMediaClient = GoogleCastRemoteMediaClientIOSMethodChannel();
    });

    test('implements remote media platform contract', () {
      expect(
        remoteMediaClient,
        isA<GoogleCastRemoteMediaClientPlatformInterface>(),
      );
    });

    test('starts with safe defaults', () {
      expect(remoteMediaClient.mediaStatus, isNull);
      expect(remoteMediaClient.playerPosition, Duration.zero);
      expect(remoteMediaClient.queueItems, isEmpty);
      expect(remoteMediaClient.queueHasNextItem, isFalse);
      expect(remoteMediaClient.queueHasPreviousItem, isFalse);
    });

    test('streams expose initial values', () async {
      await expectLater(
        remoteMediaClient.mediaStatusStream.take(1),
        emits(isNull),
      );
      await expectLater(
        remoteMediaClient.playerPositionStream.take(1),
        emits(Duration.zero),
      );
      await expectLater(
        remoteMediaClient.queueItemsStream.take(1),
        emits(isEmpty),
      );
    });
  });
}