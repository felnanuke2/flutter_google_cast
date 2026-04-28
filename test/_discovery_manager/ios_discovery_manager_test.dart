import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_discovery_manager/ios_discovery_manager.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCastDiscoveryManagerMethodChannelIOS', () {
    late GoogleCastDiscoveryManagerMethodChannelIOS discoveryManager;
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('google_cast.discovery_manager');

    /// A minimal device map in the iOS format expected by [GoogleCastIosDevice.fromMap].
    Map<String, dynamic> deviceMap({
      String deviceID = 'test-device',
      String friendlyName = 'Test TV',
      int index = 0,
    }) =>
        {
          'deviceID': deviceID,
          'friendlyName': friendlyName,
          'modelName': 'Test Model',
          'statusText': 'Ready',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-$deviceID',
          'index': index,
        };

    setUp(() {
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call);
        switch (call.method) {
          case 'isDiscoveryActiveForDeviceCategory':
            return true;
          default:
            return null;
        }
      });

      discoveryManager = GoogleCastDiscoveryManagerMethodChannelIOS();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    // -----------------------------------------------------------------------
    // Construction / interface
    // -----------------------------------------------------------------------

    test('implements GoogleCastDiscoveryManagerPlatformInterface', () {
      expect(
          discoveryManager, isA<GoogleCastDiscoveryManagerPlatformInterface>());
    });

    test('initializes with empty devices list', () {
      expect(discoveryManager.devices, isEmpty);
    });

    test('devicesStream is accessible and a broadcast stream', () {
      final stream = discoveryManager.devicesStream;
      expect(stream, isNotNull);
      expect(() => stream.listen((_) {}), returnsNormally);
    });

    // -----------------------------------------------------------------------
    // Outgoing method calls
    // -----------------------------------------------------------------------

    test('startDiscovery invokes startDiscovery on the channel', () async {
      await discoveryManager.startDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('startDiscovery'));
      expect(methodCalls.first.arguments, isNull);
    });

    test('stopDiscovery invokes stopDiscovery on the channel', () async {
      await discoveryManager.stopDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('stopDiscovery'));
      expect(methodCalls.first.arguments, isNull);
    });

    test('isDiscoveryActiveForDeviceCategory invokes correct method', () async {
      const category = 'audio';
      final result =
          await discoveryManager.isDiscoveryActiveForDeviceCategory(category);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method,
          equals('isDiscoveryActiveForDeviceCategory'));
      expect(methodCalls.first.arguments, equals({'deviceCategory': category}));
    });

    // -----------------------------------------------------------------------
    // onDevicesChanged (internal helper exposed for testing)
    // -----------------------------------------------------------------------

    test('onDevicesChanged updates the devices list', () {
      discoveryManager.onDevicesChanged([deviceMap()]);

      expect(discoveryManager.devices, hasLength(1));
      expect(discoveryManager.devices.first.deviceID, equals('test-device'));
      expect(discoveryManager.devices.first.friendlyName, equals('Test TV'));
    });

    test('onDevicesChanged parses devices as GoogleCastIosDevice', () {
      discoveryManager.onDevicesChanged([
        deviceMap(deviceID: 'd1', friendlyName: 'Speaker', index: 2),
      ]);

      final device = discoveryManager.devices.first as GoogleCastIosDevice;
      expect(device.deviceID, equals('d1'));
      expect(device.friendlyName, equals('Speaker'));
      expect(device.index, equals(2));
    });

    test('onDevicesChanged with multiple devices', () {
      discoveryManager.onDevicesChanged([
        deviceMap(deviceID: 'd1', friendlyName: 'TV', index: 0),
        deviceMap(deviceID: 'd2', friendlyName: 'Speaker', index: 1),
      ]);

      expect(discoveryManager.devices, hasLength(2));
    });

    test('onDevicesChanged with empty list clears devices', () {
      discoveryManager.onDevicesChanged([deviceMap()]);
      expect(discoveryManager.devices, hasLength(1));

      discoveryManager.onDevicesChanged([]);
      expect(discoveryManager.devices, isEmpty);
    });

    test('onDevicesChanged emits updated devices on the stream', () async {
      final events = <List<GoogleCastDevice>>[];
      final subscription = discoveryManager.devicesStream.listen(events.add);

      await Future.delayed(const Duration(milliseconds: 10));

      discoveryManager.onDevicesChanged([deviceMap()]);

      await Future.delayed(const Duration(milliseconds: 10));
      await subscription.cancel();

      expect(events, hasLength(2)); // initial empty + update
      expect(events.first, isEmpty);
      expect(events.last, hasLength(1));
      expect(events.last.first.deviceID, equals('test-device'));
    });

    // -----------------------------------------------------------------------
    // handleMethodCall (exposed for testing)
    // -----------------------------------------------------------------------

    test('handleMethodCall processes onDevicesChanged', () async {
      await discoveryManager.handleMethodCall(
        MethodCall('onDevicesChanged', [deviceMap()]),
      );

      expect(discoveryManager.devices, hasLength(1));
      expect(discoveryManager.devices.first.deviceID, equals('test-device'));
    });

    test('handleMethodCall with empty list clears devices', () async {
      discoveryManager.onDevicesChanged([deviceMap()]);

      await discoveryManager.handleMethodCall(
        const MethodCall('onDevicesChanged', []),
      );

      expect(discoveryManager.devices, isEmpty);
    });

    test('handleMethodCall ignores unknown methods gracefully', () async {
      await expectLater(
        discoveryManager.handleMethodCall(const MethodCall('unknownMethod')),
        completes,
      );
      expect(discoveryManager.devices, isEmpty);
    });
  });
}
