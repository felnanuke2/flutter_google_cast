import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_session_manager/ios_cast_session_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_message.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';
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

    test('startSessionWithDevice invokes native "startSessionWithDevice" '
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

    test(
      'startSessionWithDevice propagates false from the native side',
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
      },
    );

    test(
      'resetSession invokes native "resetSession" and returns its result',
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
      },
    );

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

    test('custom message methods forward namespace and payload', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
            methodCalls.add(call);
            return true;
          });

      expect(
        await manager.addMessageChannel('urn:x-cast:example.channel'),
        isTrue,
      );
      expect(
        await manager.sendMessage(
          'urn:x-cast:example.channel',
          '{"command":"ping"}',
        ),
        isTrue,
      );
      expect(
        await manager.removeMessageChannel('urn:x-cast:example.channel'),
        isTrue,
      );

      expect(methodCalls.map((call) => call.method), <String>[
        'addMessageChannel',
        'sendMessage',
        'removeMessageChannel',
      ]);
      expect(methodCalls[1].arguments, <String, dynamic>{
        'namespace': 'urn:x-cast:example.channel',
        'message': '{"command":"ping"}',
      });
    });

    test('emits receiver messages with their namespace', () async {
      final messageFuture = manager.messageStream.first;

      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onMessageReceived', <String, dynamic>{
                'namespace': 'urn:x-cast:example.channel',
                'message': '{"status":"ready"}',
              }),
            ),
            (_) {},
          );

      final message = await messageFuture;
      expect(message.namespace, 'urn:x-cast:example.channel');
      expect(message.message, '{"status":"ready"}');
    });

    test('drops malformed receiver messages instead of throwing', () async {
      final received = <GoogleCastMessage>[];
      final subscription = manager.messageStream.listen(received.add);

      Future<void> emit(Object? arguments) => TestDefaultBinaryMessengerBinding
          .instance
          .defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              MethodCall('onMessageReceived', arguments),
            ),
            (_) {},
          );

      await emit('not-a-map');
      await emit(<dynamic, dynamic>{'namespace': 42, 'message': 'text'});
      await emit(<String, dynamic>{'namespace': 'urn:x-cast:example.channel'});
      await emit(<String, dynamic>{
        'namespace': 'urn:x-cast:example.channel',
        'message': 'valid',
      });

      expect(received, hasLength(1));
      expect(received.single.message, 'valid');
      await subscription.cancel();
    });

    test('dispose closes the message stream and drops later events', () async {
      manager.dispose();

      // A closed broadcast stream emits done to new listeners immediately.
      await expectLater(manager.messageStream, emitsDone);
      // A late native event must be a no-op, not a StateError.
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec().encodeMethodCall(
              const MethodCall('onMessageReceived', <String, dynamic>{
                'namespace': 'urn:x-cast:example.channel',
                'message': 'late',
              }),
            ),
            (_) {},
          );
    });

    test('dispose clears the cached session and drops late session events '
        'instead of surfacing stale data', () async {
      Future<void> emitSession(Object? arguments) =>
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
                channel.name,
                const StandardMethodCodec().encodeMethodCall(
                  MethodCall('onCurrentSessionChanged', arguments),
                ),
                (_) {},
              );

      await emitSession(<String, dynamic>{
        'sessionID': 'session-1',
        'connectionState': 2, // GoogleCastConnectState.connected
        'currentDeviceMuted': false,
        'currentDeviceVolume': 1.0,
        'device': <String, dynamic>{
          'deviceID': 'device-1',
          'isOnLocalNetwork': true,
          'category': 'com.google.cast.CastDevice',
          'uniqueID': 'com.google.cast.CastDevice:device-1',
        },
      });

      expect(manager.currentSession?.sessionID, 'session-1');
      expect(manager.connectionState, GoogleCastConnectState.connected);
      expect(manager.hasConnectedSession, isTrue);

      manager.dispose();

      expect(manager.currentSession, isNull);
      expect(manager.connectionState, GoogleCastConnectState.disconnected);
      expect(manager.hasConnectedSession, isFalse);

      // A late native session event must be a no-op, not a StateError.
      await emitSession(null);
    });
  });
}
