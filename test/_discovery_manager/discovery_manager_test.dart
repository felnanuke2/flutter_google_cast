import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';

import '../helpers/mock_implementations.dart';

GoogleCastDevice _device({
  String deviceID = 'd1',
  String friendlyName = 'Test TV',
}) =>
    GoogleCastDevice(
      deviceID: deviceID,
      friendlyName: friendlyName,
      modelName: 'Test Model',
      statusText: null,
      deviceVersion: '1.0',
      isOnLocalNetwork: true,
      category: 'audio',
      uniqueID: 'unique-$deviceID',
    );

void main() {
  group('GoogleCastDiscoveryManager (federated plugin facade)', () {
    late MockGoogleCastDiscoveryManagerPlatformInterface mockPlatform;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockPlatform = MockGoogleCastDiscoveryManagerPlatformInterface();
      // Inject the mock – this is how a federated plugin test decouples
      // the app-facing facade from a real platform implementation.
      GoogleCastDiscoveryManager.instance = mockPlatform;
    });

    tearDown(() {
      // Reset to a fresh mock to guarantee subsequent tests start with a clean
      // state. Using a fresh mock avoids any residual state from the current
      // test while also preventing null-pointer issues if the instance is
      // accessed between tearDown and the next setUp.
      GoogleCastDiscoveryManager.instance =
          MockGoogleCastDiscoveryManagerPlatformInterface();
    });

    // -----------------------------------------------------------------------
    // Instance / interface contract
    // -----------------------------------------------------------------------

    test('instance returns a GoogleCastDiscoveryManagerPlatformInterface', () {
      expect(GoogleCastDiscoveryManager.instance,
          isA<GoogleCastDiscoveryManagerPlatformInterface>());
    });

    test('instance is the injected mock', () {
      expect(GoogleCastDiscoveryManager.instance, same(mockPlatform));
    });

    // -----------------------------------------------------------------------
    // Devices
    // -----------------------------------------------------------------------

    test('devices is initially empty', () {
      expect(GoogleCastDiscoveryManager.instance.devices, isEmpty);
    });

    test('devices reflects updates emitted by the platform', () {
      final device = _device();
      mockPlatform.emitDevices([device]);

      expect(GoogleCastDiscoveryManager.instance.devices, hasLength(1));
      expect(
          GoogleCastDiscoveryManager.instance.devices.first.deviceID, 'd1');
    });

    test('devicesStream emits the current list', () async {
      expect(
        GoogleCastDiscoveryManager.instance.devicesStream,
        isA<Stream<List<GoogleCastDevice>>>(),
      );

      mockPlatform.emitDevices([_device(deviceID: 'd2')]);

      final emitted = await GoogleCastDiscoveryManager.instance.devicesStream
          .first;
      expect(emitted, hasLength(1));
    });

    // -----------------------------------------------------------------------
    // Discovery lifecycle
    // -----------------------------------------------------------------------

    test('startDiscovery delegates to platform interface', () async {
      await GoogleCastDiscoveryManager.instance.startDiscovery();

      expect(mockPlatform.startDiscoveryCalled, isTrue);
    });

    test('stopDiscovery delegates to platform interface', () async {
      await GoogleCastDiscoveryManager.instance.stopDiscovery();

      expect(mockPlatform.stopDiscoveryCalled, isTrue);
    });

    test('isDiscoveryActiveForDeviceCategory delegates to platform interface',
        () async {
      mockPlatform.isDiscoveryActiveReturnValue = true;
      const category = 'audio';

      final result = await GoogleCastDiscoveryManager.instance
          .isDiscoveryActiveForDeviceCategory(category);

      expect(result, isTrue);
      expect(mockPlatform.lastDeviceCategory, equals(category));
    });

    // -----------------------------------------------------------------------
    // Replacing the instance
    // -----------------------------------------------------------------------

    test('replacing the instance changes which implementation is used',
        () async {
      final secondMock = MockGoogleCastDiscoveryManagerPlatformInterface();
      GoogleCastDiscoveryManager.instance = secondMock;

      await GoogleCastDiscoveryManager.instance.startDiscovery();

      expect(mockPlatform.startDiscoveryCalled, isFalse);
      expect(secondMock.startDiscoveryCalled, isTrue);
    });
  });
}
