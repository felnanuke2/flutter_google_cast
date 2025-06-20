import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_discovery_manager/android_discovery_manager.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';

void main() {
  group('GoogleCastDiscoveryManagerMethodChannelAndroid', () {
    late GoogleCastDiscoveryManagerMethodChannelAndroid discoveryManager;
    late List<MethodCall> methodCalls;
    late MethodChannel channel;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      channel =
          const MethodChannel('com.felnanuke.google_cast.discovery_manager');
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('constructor should set up method call handler', () {
      // Test constructor execution (line 18-19)
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      expect(discoveryManager, isNotNull);
      expect(
          discoveryManager, isA<GoogleCastDiscoveryManagerPlatformInterface>());
    });

    test('should implement GoogleCastDiscoveryManagerPlatformInterface', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      expect(
          discoveryManager, isA<GoogleCastDiscoveryManagerPlatformInterface>());
    });

    test('should initialize with empty devices list', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      // Test devices getter (line 29)
      expect(discoveryManager.devices, isEmpty);
    });

    test('should provide devices stream', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      // Test devicesStream getter (line 33)
      expect(discoveryManager.devicesStream,
          isA<Stream<List<GoogleCastDevice>>>());

      // Test initial empty state
      discoveryManager.devicesStream.listen(expectAsync1((devices) {
        expect(devices, isEmpty);
      }));
    });

    test('should call startDiscovery method on native side', () async {
      // Set up the mock to capture outgoing calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      // Test startDiscovery method (line 42)
      await discoveryManager.startDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('startDiscovery'));
      expect(methodCalls.first.arguments, isNull);
    });

    test('should call stopDiscovery method on native side', () async {
      // Set up the mock to capture outgoing calls
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      // Test stopDiscovery method (line 48)
      await discoveryManager.stopDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('stopDiscovery'));
      expect(methodCalls.first.arguments, isNull);
    });

    test(
        'should throw UnimplementedError for isDiscoveryActiveForDeviceCategory',
        () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      // Test line 37
      expect(
        () => discoveryManager.isDiscoveryActiveForDeviceCategory('test'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    group('Method Channel Handler Tests', () {
      setUp(() {
        discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      });

      test('should handle onDevicesChanged method call from native', () async {
        const testDevicesJson = '''[
          {
            "id": "device1",
            "name": "Living Room TV",
            "model_name": "Chromecast",
            "device_version": "1.0.0",
            "is_on_local_network": true
          }
        ]''';

        // Create a completer to wait for stream updates
        final streamCompleter = Completer<List<GoogleCastDevice>>();
        late StreamSubscription subscription;

        subscription = discoveryManager.devicesStream.skip(1).take(1).listen(
          (devices) {
            streamCompleter.complete(devices);
            subscription.cancel();
          },
        );

        // Simulate method call from native side
        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('onDevicesChanged', testDevicesJson);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        // Wait for the stream to update
        final devices = await streamCompleter.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <GoogleCastDevice>[],
        );

        // Verify devices were parsed and added
        expect(devices, hasLength(1));
        expect(devices.first.deviceID, equals('device1'));
        expect(devices.first.friendlyName, equals('Living Room TV'));
        expect(devices.first.modelName, equals('Chromecast'));
      });

      test('should handle multiple devices with deduplication', () async {
        const testDevicesJson = '''[
          {
            "id": "device1",
            "name": "Living Room TV",
            "model_name": "Chromecast",
            "device_version": "1.0.0",
            "is_on_local_network": true
          },
          {
            "id": "device2",
            "name": "Living Room TV",
            "model_name": "Chromecast",
            "device_version": "1.0.0",
            "is_on_local_network": true
          },
          {
            "id": "device3",
            "name": "Kitchen Display",
            "model_name": "Google Nest Hub",
            "device_version": "2.0.0",
            "is_on_local_network": true
          }
        ]''';

        final streamCompleter = Completer<List<GoogleCastDevice>>();
        late StreamSubscription subscription;

        subscription = discoveryManager.devicesStream.skip(1).take(1).listen(
          (devices) {
            streamCompleter.complete(devices);
            subscription.cancel();
          },
        );

        // Simulate method call from native side
        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('onDevicesChanged', testDevicesJson);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        final devices = await streamCompleter.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <GoogleCastDevice>[],
        );

        // Should only have 2 devices due to deduplication (same name + model)
        expect(devices, hasLength(2));

        // Check that deduplication worked correctly
        final deviceNames = devices.map((d) => d.friendlyName).toSet();
        expect(deviceNames, contains('Living Room TV'));
        expect(deviceNames, contains('Kitchen Display'));

        final chromecastDevices =
            devices.where((d) => d.modelName == 'Chromecast').toList();
        expect(chromecastDevices,
            hasLength(1)); // Only one Chromecast with same name
      });

      test('should handle empty devices list', () async {
        const testDevicesJson = '[]';

        final streamCompleter = Completer<List<GoogleCastDevice>>();
        late StreamSubscription subscription;

        subscription = discoveryManager.devicesStream.skip(1).take(1).listen(
          (devices) {
            streamCompleter.complete(devices);
            subscription.cancel();
          },
        );

        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('onDevicesChanged', testDevicesJson);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        final devices = await streamCompleter.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <GoogleCastDevice>[],
        );

        expect(devices, isEmpty);
      });

      test('should handle unknown method calls gracefully', () async {
        // Simulate unknown method call (tests default case in line 57)
        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('unknownMethod', null);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        // Should not affect devices
        expect(discoveryManager.devices, isEmpty);
      });
    });

    group('Integration Tests', () {
      setUp(() {
        // Set up mock to capture outgoing method calls for integration tests
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          methodCalls.add(methodCall);
          return null;
        });
        discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      });

      test('should handle complete discovery workflow', () async {
        // Start discovery
        await discoveryManager.startDiscovery();
        expect(methodCalls.last.method, equals('startDiscovery'));

        // Simulate device discovery
        const testDevicesJson = '''[
          {
            "id": "integration_device",
            "name": "Integration Test TV",
            "model_name": "Test Chromecast",
            "device_version": "1.0.0",
            "is_on_local_network": true
          }
        ]''';

        final streamCompleter = Completer<List<GoogleCastDevice>>();
        late StreamSubscription subscription;

        subscription = discoveryManager.devicesStream.skip(1).take(1).listen(
          (devices) {
            streamCompleter.complete(devices);
            subscription.cancel();
          },
        );

        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('onDevicesChanged', testDevicesJson);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        final devices = await streamCompleter.future.timeout(
          const Duration(seconds: 2),
          onTimeout: () => <GoogleCastDevice>[],
        );

        // Verify device was discovered
        expect(devices, hasLength(1));
        expect(devices.first.friendlyName, equals('Integration Test TV'));

        // Stop discovery
        await discoveryManager.stopDiscovery();
        expect(methodCalls.last.method, equals('stopDiscovery'));
      });

      test('should maintain devices state across multiple updates', () async {
        // First update
        const firstDevicesJson = '''[
          {
            "id": "device1",
            "name": "First Device",
            "model_name": "Chromecast",
            "device_version": "1.0.0",
            "is_on_local_network": true
          }
        ]''';

        final firstCompleter = Completer<List<GoogleCastDevice>>();
        late StreamSubscription firstSubscription;

        firstSubscription =
            discoveryManager.devicesStream.skip(1).take(1).listen(
          (devices) {
            firstCompleter.complete(devices);
            firstSubscription.cancel();
          },
        );

        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('onDevicesChanged', firstDevicesJson);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        final firstDevices = await firstCompleter.future;
        expect(firstDevices, hasLength(1));

        // Second update with additional device
        const secondDevicesJson = '''[
          {
            "id": "device1",
            "name": "First Device",
            "model_name": "Chromecast",
            "device_version": "1.0.0",
            "is_on_local_network": true
          },
          {
            "id": "device2",
            "name": "Second Device",
            "model_name": "Google TV",
            "device_version": "2.0.0",
            "is_on_local_network": true
          }
        ]''';

        final secondCompleter = Completer<List<GoogleCastDevice>>();
        late StreamSubscription secondSubscription;

        secondSubscription =
            discoveryManager.devicesStream.skip(1).take(1).listen(
          (devices) {
            secondCompleter.complete(devices);
            secondSubscription.cancel();
          },
        );

        final binding2 = TestDefaultBinaryMessengerBinding.instance;
        final codec2 = const StandardMethodCodec();
        final call2 = MethodCall('onDevicesChanged', secondDevicesJson);
        final message2 = codec2.encodeMethodCall(call2);

        await binding2.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message2,
          (data) {},
        );

        final secondDevices = await secondCompleter.future;
        expect(secondDevices, hasLength(2));
        expect(
            secondDevices.map((d) => d.friendlyName), contains('First Device'));
        expect(secondDevices.map((d) => d.friendlyName),
            contains('Second Device'));
      });
    });

    group('Error Handling Tests', () {
      setUp(() {
        discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      });

      test('should handle invalid JSON gracefully', () async {
        // This tests the catch block and rethrow in line 97-99
        const invalidJson = 'invalid json format';

        // We expect the method channel to handle the error
        // The error will be caught and rethrown in the _onDevicesChanged method
        final binding = TestDefaultBinaryMessengerBinding.instance;
        final codec = const StandardMethodCodec();
        final call = MethodCall('onDevicesChanged', invalidJson);
        final message = codec.encodeMethodCall(call);

        await binding.defaultBinaryMessenger.handlePlatformMessage(
          'com.felnanuke.google_cast.discovery_manager',
          message,
          (data) {},
        );

        // Devices should remain empty after error
        expect(discoveryManager.devices, isEmpty);
      });
    });
  });
}
