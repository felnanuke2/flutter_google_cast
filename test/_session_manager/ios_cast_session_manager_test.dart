import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_session_manager/ios_cast_session_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';

void main() {
  group('GoogleCastSessionManagerIOSMethodChannel', () {
    late GoogleCastSessionManagerIOSMethodChannel manager;
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('google_cast.session_manager');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      manager = GoogleCastSessionManagerIOSMethodChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should implement GoogleCastSessionManagerPlatformInterface', () {
      expect(manager, isA<GoogleCastSessionManagerPlatformInterface>());
    });

    test(
        'startSessionWithDevice invokes native "startSessionWithDevice" '
        'with the iOS discovery index', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return true;
      });

      final device = GoogleCastIosDevice(
        deviceID: 'device-1',
        friendlyName: 'Living Room TV',
        modelName: 'AirReceiver',
        statusText: 'Ready',
        deviceVersion: '5',
        isOnLocalNetwork: true,
        category: 'com.google.cast.CastDevice',
        uniqueID: 'com.google.cast.CastDevice:device-1',
        index: 1,
      );

      final result = await manager.startSessionWithDevice(device);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('startSessionWithDevice'));
      expect(methodCalls.first.arguments, equals(1));
    });

    test('startSessionWithDevice propagates false from the native side',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return false;
      });

      final device = GoogleCastIosDevice(
        deviceID: 'device-1',
        friendlyName: 'Living Room TV',
        modelName: 'AirReceiver',
        statusText: 'Ready',
        deviceVersion: '5',
        isOnLocalNetwork: true,
        category: 'com.google.cast.CastDevice',
        uniqueID: 'com.google.cast.CastDevice:device-1',
        index: 1,
      );

      final result = await manager.startSessionWithDevice(device);

      expect(result, isFalse);
      expect(methodCalls.single.method, equals('startSessionWithDevice'));
    });

    test('resetSession invokes native "resetSession" and returns its result',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return true;
      });

      final result = await manager.resetSession();

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('resetSession'));
      expect(methodCalls.first.arguments, isNull);
    });

    test('resetSession propagates false returned by the native side', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        methodCalls.add(call);
        return false;
      });

      final result = await manager.resetSession();

      expect(result, isFalse);
      expect(methodCalls.single.method, equals('resetSession'));
    });
  });
}
