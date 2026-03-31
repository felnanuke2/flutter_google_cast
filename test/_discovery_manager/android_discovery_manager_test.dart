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
    const channel =
        MethodChannel('com.felnanuke.google_cast.discovery_manager');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    void mockChannel(dynamic Function(MethodCall) handler) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        methodCalls.add(call);
        return handler(call);
      });
    }

    /// Simulates the native side sending an [onDevicesChanged] method call
    /// with [json] as the argument and returns once the message is delivered.
    Future<void> simulateDevicesChanged(String json) async {
      const codec = StandardMethodCodec();
      final message =
          codec.encodeMethodCall(MethodCall('onDevicesChanged', json));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
              'com.felnanuke.google_cast.discovery_manager', message, (_) {});
    }

    // -----------------------------------------------------------------------
    // Construction / interface
    // -----------------------------------------------------------------------

    test('implements GoogleCastDiscoveryManagerPlatformInterface', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      expect(
          discoveryManager, isA<GoogleCastDiscoveryManagerPlatformInterface>());
    });

    test('initializes with empty devices list', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      expect(discoveryManager.devices, isEmpty);
    });

    test('devicesStream emits the initial empty list', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      expect(
          discoveryManager.devicesStream, isA<Stream<List<GoogleCastDevice>>>());

      discoveryManager.devicesStream
          .listen(expectAsync1((devices) => expect(devices, isEmpty)));
    });

    // -----------------------------------------------------------------------
    // Outgoing method calls
    // -----------------------------------------------------------------------

    test('startDiscovery invokes startDiscovery on the channel', () async {
      mockChannel((_) => null);
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      await discoveryManager.startDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('startDiscovery'));
      expect(methodCalls.first.arguments, isNull);
    });

    test('stopDiscovery invokes stopDiscovery on the channel', () async {
      mockChannel((_) => null);
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      await discoveryManager.stopDiscovery();

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('stopDiscovery'));
    });

    test('isDiscoveryActiveForDeviceCategory throws UnimplementedError', () {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();
      expect(
        () => discoveryManager.isDiscoveryActiveForDeviceCategory('test'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    // -----------------------------------------------------------------------
    // Incoming method calls – onDevicesChanged
    // -----------------------------------------------------------------------

    test('onDevicesChanged parses a single device correctly', () async {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      const json = '''[{
        "id": "device1",
        "name": "Living Room TV",
        "model_name": "Chromecast",
        "device_version": "1.0.0",
        "is_on_local_network": true
      }]''';

      final completer = Completer<List<GoogleCastDevice>>();
      discoveryManager.devicesStream
          .skip(1)
          .take(1)
          .listen(completer.complete);

      await simulateDevicesChanged(json);

      final devices = await completer.future
          .timeout(const Duration(seconds: 2), onTimeout: () => []);

      expect(devices, hasLength(1));
      expect(devices.first.deviceID, equals('device1'));
      expect(devices.first.friendlyName, equals('Living Room TV'));
      expect(devices.first.modelName, equals('Chromecast'));
    });

    test('onDevicesChanged deduplicates devices with the same name and model',
        () async {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      // Two entries with identical name + model → should collapse to one.
      const json = '''[
        {"id":"d1","name":"TV","model_name":"Chromecast","device_version":"1.0","is_on_local_network":true},
        {"id":"d2","name":"TV","model_name":"Chromecast","device_version":"1.0","is_on_local_network":true},
        {"id":"d3","name":"Kitchen","model_name":"Nest Hub","device_version":"2.0","is_on_local_network":true}
      ]''';

      final completer = Completer<List<GoogleCastDevice>>();
      discoveryManager.devicesStream
          .skip(1)
          .take(1)
          .listen(completer.complete);

      await simulateDevicesChanged(json);

      final devices = await completer.future
          .timeout(const Duration(seconds: 2), onTimeout: () => []);

      expect(devices, hasLength(2));
      final names = devices.map((d) => d.friendlyName).toSet();
      expect(names, containsAll(['TV', 'Kitchen']));
    });

    test('onDevicesChanged with empty array clears the device list', () async {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      final completer = Completer<List<GoogleCastDevice>>();
      discoveryManager.devicesStream
          .skip(1)
          .take(1)
          .listen(completer.complete);

      await simulateDevicesChanged('[]');

      final devices = await completer.future
          .timeout(const Duration(seconds: 2), onTimeout: () => []);

      expect(devices, isEmpty);
    });

    test('unknown method calls are handled gracefully', () async {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      const codec = StandardMethodCodec();
      final message =
          codec.encodeMethodCall(const MethodCall('unknownMethod', null));
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
              'com.felnanuke.google_cast.discovery_manager', message, (_) {});

      expect(discoveryManager.devices, isEmpty);
    });

    test('invalid JSON in onDevicesChanged is handled gracefully', () async {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      // Invalid JSON should be caught internally and not crash the app.
      await simulateDevicesChanged('not valid json');

      // Devices list remains unchanged (empty).
      expect(discoveryManager.devices, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Integration: full discovery workflow
    // -----------------------------------------------------------------------

    test('complete discovery workflow: start → receive devices → stop',
        () async {
      mockChannel((_) => null);
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      await discoveryManager.startDiscovery();
      expect(methodCalls.last.method, equals('startDiscovery'));

      const json = '''[{
        "id": "tv1",
        "name": "Living Room",
        "model_name": "Chromecast Ultra",
        "device_version": "1.0",
        "is_on_local_network": true
      }]''';

      final completer = Completer<List<GoogleCastDevice>>();
      discoveryManager.devicesStream
          .skip(1)
          .take(1)
          .listen(completer.complete);

      await simulateDevicesChanged(json);

      final devices = await completer.future
          .timeout(const Duration(seconds: 2), onTimeout: () => []);

      expect(devices, hasLength(1));
      expect(devices.first.friendlyName, equals('Living Room'));

      await discoveryManager.stopDiscovery();
      expect(methodCalls.last.method, equals('stopDiscovery'));
    });

    test('device list is replaced on each onDevicesChanged update', () async {
      discoveryManager = GoogleCastDiscoveryManagerMethodChannelAndroid();

      // First update: 1 device.
      final firstCompleter = Completer<List<GoogleCastDevice>>();
      discoveryManager.devicesStream
          .skip(1)
          .take(1)
          .listen(firstCompleter.complete);

      await simulateDevicesChanged('''[{
        "id":"d1","name":"First","model_name":"Model A",
        "device_version":"1.0","is_on_local_network":true
      }]''');

      final first = await firstCompleter.future;
      expect(first, hasLength(1));

      // Second update: 2 devices.
      final secondCompleter = Completer<List<GoogleCastDevice>>();
      discoveryManager.devicesStream
          .skip(1)
          .take(1)
          .listen(secondCompleter.complete);

      await simulateDevicesChanged('''[
        {"id":"d1","name":"First","model_name":"Model A","device_version":"1.0","is_on_local_network":true},
        {"id":"d2","name":"Second","model_name":"Model B","device_version":"2.0","is_on_local_network":true}
      ]''');

      final second = await secondCompleter.future;
      expect(second, hasLength(2));
    });
  });
}
