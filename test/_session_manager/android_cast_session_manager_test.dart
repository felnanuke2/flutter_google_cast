import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_session_manager/android_cast_session_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';
import 'package:flutter_chrome_cast/models/android/cast_device.dart';

void main() {
  group('GoogleCastSessionManagerAndroidMethodChannel', () {
    late GoogleCastSessionManagerAndroidMethodChannel manager;
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('com.felnanuke.google_cast.session_manager');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      manager = GoogleCastSessionManagerAndroidMethodChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should implement GoogleCastSessionManagerPlatformInterface', () {
      expect(manager, isA<GoogleCastSessionManagerPlatformInterface>());
    });

    test(
        'startSessionWithDevice invokes native "startSessionWithDeviceId" '
        'with the Android device ID', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return true;
      });

      final device = GoogleCastAndroidDevice(
        deviceID: 'device-1',
        friendlyName: 'Living Room TV',
        modelName: 'Chromecast',
        statusText: null,
        deviceVersion: '5',
        isOnLocalNetwork: true,
        category: 'cast',
        uniqueID: 'device-1',
      );

      final result = await manager.startSessionWithDevice(device);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('startSessionWithDeviceId'));
      expect(methodCalls.first.arguments, equals('device-1'));
    });

    test('startSessionWithDevice propagates false from the native side',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return false;
      });

      final device = GoogleCastAndroidDevice(
        deviceID: 'device-1',
        friendlyName: 'Living Room TV',
        modelName: 'Chromecast',
        statusText: null,
        deviceVersion: '5',
        isOnLocalNetwork: true,
        category: 'cast',
        uniqueID: 'device-1',
      );

      final result = await manager.startSessionWithDevice(device);

      expect(result, isFalse);
      expect(methodCalls.single.method, equals('startSessionWithDeviceId'));
    });

    test(
        'resetSession delegates to endSessionAndStopCasting on Android '
        'because stale sessions are not observed on that platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return true;
      });

      final result = await manager.resetSession();

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      // Must NOT invoke a native "resetSession" on Android — delegation only.
      expect(methodCalls.first.method, equals('endSessionAndStopCasting'));
    });

    test('resetSession propagates false from endSessionAndStopCasting',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return false;
      });

      final result = await manager.resetSession();

      expect(result, isFalse);
      expect(methodCalls.single.method, equals('endSessionAndStopCasting'));
    });
  });
}
