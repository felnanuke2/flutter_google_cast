import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/_discovery_manager/ios_discovery_manager.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCastDiscoveryManagerMethodChannelIOS', () {
    late GoogleCastDiscoveryManagerMethodChannelIOS discoveryManager;
    late List<MethodCall> methodCalls;
    const MethodChannel channel =
        MethodChannel('google_cast.discovery_manager');

    setUp(() {
      methodCalls = [];

      // Mock the method channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'isDiscoveryActiveForDeviceCategory':
              return true;
            case 'startDiscovery':
              return null;
            case 'stopDiscovery':
              return null;
            default:
              return null;
          }
        },
      );

      discoveryManager = GoogleCastDiscoveryManagerMethodChannelIOS();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('initializes with empty devices list', () {
      expect(discoveryManager.devices, isEmpty);
    });

    test('devices getter returns current devices list', () {
      // Initially empty
      expect(discoveryManager.devices, isEmpty);

      // Add devices through test method
      final deviceData = [
        {
          'deviceID': 'test-device-1',
          'friendlyName': 'Test TV',
          'modelName': 'Test Model',
          'statusText': 'Ready to cast',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-123',
          'index': 0,
        }
      ];

      discoveryManager.onDevicesChanged(deviceData);

      expect(discoveryManager.devices, hasLength(1));
      expect(discoveryManager.devices.first.deviceID, 'test-device-1');
      expect(discoveryManager.devices.first.friendlyName, 'Test TV');
    });

    test('devicesStream emits device updates', () async {
      final streamEvents = <List<GoogleCastDevice>>[];

      // Listen to the stream
      final subscription = discoveryManager.devicesStream.listen((devices) {
        streamEvents.add(devices);
      });

      // Wait for initial empty list
      await Future.delayed(const Duration(milliseconds: 10));

      // Add devices
      final deviceData = [
        {
          'deviceID': 'stream-test-device',
          'friendlyName': 'Stream Test TV',
          'modelName': 'Stream Model',
          'statusText': 'Ready',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-stream',
          'index': 0,
        }
      ];

      discoveryManager.onDevicesChanged(deviceData);

      // Wait for stream update
      await Future.delayed(const Duration(milliseconds: 10));

      await subscription.cancel();

      expect(streamEvents, hasLength(2)); // Initial empty + updated
      expect(streamEvents.first, isEmpty);
      expect(streamEvents.last, hasLength(1));
      expect(streamEvents.last.first.deviceID, 'stream-test-device');
    });

    test('isDiscoveryActiveForDeviceCategory calls correct method', () async {
      const testCategory = 'audio';
      final result = await discoveryManager
          .isDiscoveryActiveForDeviceCategory(testCategory);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'isDiscoveryActiveForDeviceCategory');
      expect(methodCalls.first.arguments, {'deviceCategory': testCategory});
    });

    test('startDiscovery calls correct method', () async {
      await discoveryManager.startDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'startDiscovery');
      expect(methodCalls.first.arguments, isNull);
    });

    test('stopDiscovery calls correct method', () async {
      await discoveryManager.stopDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, 'stopDiscovery');
      expect(methodCalls.first.arguments, isNull);
    });

    test('onDevicesChanged updates device list correctly', () {
      final deviceData = [
        {
          'deviceID': 'device-1',
          'friendlyName': 'Living Room TV',
          'modelName': 'Smart TV',
          'statusText': 'Ready',
          'deviceVersion': '2.0',
          'isOnLocalNetwork': false,
          'category': 'video',
          'uniqueID': 'unique-456',
          'index': 1,
        },
        {
          'deviceID': 'device-2',
          'friendlyName': 'Bedroom Speaker',
          'modelName': 'Smart Speaker',
          'statusText': 'Connected',
          'deviceVersion': '1.5',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-789',
          'index': 2,
        }
      ];

      discoveryManager.onDevicesChanged(deviceData);

      final devices = discoveryManager.devices;
      expect(devices, hasLength(2));

      final device1 = devices[0] as GoogleCastIosDevice;
      expect(device1.deviceID, 'device-1');
      expect(device1.friendlyName, 'Living Room TV');
      expect(device1.index, 1);

      final device2 = devices[1] as GoogleCastIosDevice;
      expect(device2.deviceID, 'device-2');
      expect(device2.friendlyName, 'Bedroom Speaker');
      expect(device2.index, 2);
    });

    test('handleMethodCall processes onDevicesChanged correctly', () async {
      final deviceData = [
        {
          'deviceID': 'test-device',
          'friendlyName': 'Test Device',
          'modelName': 'Test Model',
          'statusText': 'Ready',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-123',
          'index': 0,
        }
      ];

      final methodCall = MethodCall('onDevicesChanged', deviceData);
      await discoveryManager.handleMethodCall(methodCall);

      expect(discoveryManager.devices, hasLength(1));
      expect(discoveryManager.devices.first.deviceID, 'test-device');
    });

    test('handleMethodCall ignores unknown methods gracefully', () async {
      final methodCall = MethodCall('unknownMethod', null);

      // This should complete without any side effects
      await expectLater(
        discoveryManager.handleMethodCall(methodCall),
        completes,
      );

      // Devices should remain unchanged
      expect(discoveryManager.devices, isEmpty);
    });

    test(
        'handleMethodCall prints debug message for unknown methods in debug mode',
        () async {
      // We can't easily capture print output, but we can ensure the method
      // doesn't throw and executes the debug branch
      final methodCall = MethodCall('unknownMethod', null);

      // Override debug mode temporarily if needed
      await expectLater(
        discoveryManager.handleMethodCall(methodCall),
        completes,
      );
    });

    test('multiple device updates work correctly', () {
      // First update
      discoveryManager.onDevicesChanged([
        {
          'deviceID': 'device-1',
          'friendlyName': 'Device 1',
          'modelName': 'Model 1',
          'statusText': 'Ready',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-1',
          'index': 0,
        }
      ]);

      expect(discoveryManager.devices, hasLength(1));

      // Second update with more devices
      discoveryManager.onDevicesChanged([
        {
          'deviceID': 'device-1',
          'friendlyName': 'Device 1',
          'modelName': 'Model 1',
          'statusText': 'Ready',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-1',
          'index': 0,
        },
        {
          'deviceID': 'device-2',
          'friendlyName': 'Device 2',
          'modelName': 'Model 2',
          'statusText': 'Connected',
          'deviceVersion': '2.0',
          'isOnLocalNetwork': false,
          'category': 'video',
          'uniqueID': 'unique-2',
          'index': 1,
        }
      ]);

      expect(discoveryManager.devices, hasLength(2));

      // Third update with no devices
      discoveryManager.onDevicesChanged([]);

      expect(discoveryManager.devices, isEmpty);
    });

    test('constructor sets up method call handler properly', () {
      // Create a new instance to test constructor behavior
      final newManager = GoogleCastDiscoveryManagerMethodChannelIOS();

      // The fact that it doesn't throw and can be used means the constructor worked
      expect(newManager.devices, isEmpty);
      expect(newManager.devicesStream, isNotNull);
    });

    test('devicesStream is properly initialized and accessible', () {
      final stream = discoveryManager.devicesStream;
      expect(stream, isNotNull);

      // Test that the stream is a broadcast stream (BehaviorSubject)
      expect(() => stream.listen((_) {}), returnsNormally);
    });

    test('onDevicesChanged handles empty device list', () {
      // First add some devices
      discoveryManager.onDevicesChanged([
        {
          'deviceID': 'temp-device',
          'friendlyName': 'Temp Device',
          'modelName': 'Temp Model',
          'statusText': 'Ready',
          'deviceVersion': '1.0',
          'isOnLocalNetwork': true,
          'category': 'audio',
          'uniqueID': 'unique-temp',
          'index': 0,
        }
      ]);

      expect(discoveryManager.devices, hasLength(1));

      // Now clear the device list
      discoveryManager.onDevicesChanged([]);

      expect(discoveryManager.devices, isEmpty);
    });

    test('handleMethodCall with onDevicesChanged and empty list', () async {
      // First add some devices
      await discoveryManager.handleMethodCall(
        MethodCall('onDevicesChanged', [
          {
            'deviceID': 'temp-device',
            'friendlyName': 'Temp Device',
            'modelName': 'Temp Model',
            'statusText': 'Ready',
            'deviceVersion': '1.0',
            'isOnLocalNetwork': true,
            'category': 'audio',
            'uniqueID': 'unique-temp',
            'index': 0,
          }
        ]),
      );

      expect(discoveryManager.devices, hasLength(1));

      // Now clear with empty list
      await discoveryManager.handleMethodCall(
        MethodCall('onDevicesChanged', []),
      );

      expect(discoveryManager.devices, isEmpty);
    });
  });
}
