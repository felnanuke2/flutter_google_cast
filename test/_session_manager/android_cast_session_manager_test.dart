import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_session_manager/android_cast_session_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_message.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';
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

      Future<void> emit(Object? arguments) =>
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec()
                .encodeMethodCall(MethodCall('onMessageReceived', arguments)),
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

    test(
        'dispose clears the cached session and drops late session events '
        'instead of surfacing stale data', () async {
      Future<void> emitSession(Object? arguments) =>
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .handlePlatformMessage(
            channel.name,
            const StandardMethodCodec()
                .encodeMethodCall(MethodCall('onSessionChanged', arguments)),
            (_) {},
          );

      await emitSession(<String, dynamic>{
        'sessionID': 'session-1',
        'connectionState': 2, // GoogleCastConnectState.connected
        'isMute': false,
        'volume': 1.0,
        'statusMessage': 'Ready To Cast',
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
