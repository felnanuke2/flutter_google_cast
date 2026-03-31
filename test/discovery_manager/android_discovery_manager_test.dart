import 'package:flutter_chrome_cast_android/flutter_chrome_cast_android.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCastDiscoveryManagerMethodChannelAndroid', () {
    late GoogleCastDiscoveryManagerMethodChannelAndroid discoveryManager;

    setUp(() {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
    });

    test('implements discovery platform contract', () {
      expect(
        discoveryManager,
        isA<GoogleCastDiscoveryManagerPlatformInterface>(),
      );
    });

    test('starts with empty device cache', () {
      expect(discoveryManager.devices, isEmpty);
    });

    test('emits initial empty stream state', () async {
      await expectLater(discoveryManager.devicesStream.take(1), emits(isEmpty));
    });
  });
}