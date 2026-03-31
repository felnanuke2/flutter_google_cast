import 'package:flutter_chrome_cast_ios/flutter_chrome_cast_ios.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCastDiscoveryManagerMethodChannelIOS', () {
    late GoogleCastDiscoveryManagerMethodChannelIOS discoveryManager;

    setUp(() {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelIOS();
    });

    test('implements discovery platform contract', () {
      expect(
        discoveryManager,
        isA<GoogleCastDiscoveryManagerPlatformInterface>(),
      );
    });

    test('starts with empty device list', () {
      expect(discoveryManager.devices, isEmpty);
    });

    test('maps pigeon callback devices to domain entities', () {
      discoveryManager.onDevicesChanged([
        CastDevicePigeon(
          deviceId: 'id-1',
          friendlyName: 'Bedroom TV',
          modelName: 'Chromecast Ultra',
          statusText: 'Ready to cast',
          deviceVersion: '2.0',
          isOnLocalNetwork: true,
          category: 'cast',
          uniqueId: 'u-1',
        ),
      ]);

      expect(discoveryManager.devices, hasLength(1));
      expect(discoveryManager.devices.first.deviceID, 'id-1');
      expect(discoveryManager.devices.first.friendlyName, 'Bedroom TV');
    });
  });
}