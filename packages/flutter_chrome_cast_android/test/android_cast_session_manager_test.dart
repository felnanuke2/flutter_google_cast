import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast_android/flutter_chrome_cast_android.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

const _hostApiPrefix =
    'dev.flutter.pigeon.flutter_chrome_cast_platform_interface.SessionManagerHostApi';
const _flutterApiPrefix =
    'dev.flutter.pigeon.flutter_chrome_cast_platform_interface.SessionManagerFlutterApi';

/// A recorded call to a pigeon host API method.
class _HostApiCall {
  _HostApiCall(this.method, this.args);

  /// The name of the host API method that was invoked.
  final String method;

  /// The decoded arguments the host API method was invoked with.
  final List<Object?> args;
}

/// Registers a mock handler for a pigeon host API method.
///
/// The handler records the call in [calls] and replies with [result].
/// Pigeon sends `null` for methods that take no arguments, so those calls are
/// recorded with an empty argument list.
void _mockHostApi(
  String method,
  List<_HostApiCall> calls, {
  Object? result,
}) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMessageHandler('$_hostApiPrefix.$method', (ByteData? message) async {
    final decoded =
        SessionManagerHostApi.pigeonChannelCodec.decodeMessage(message);
    calls.add(
      _HostApiCall(
        method,
        decoded == null ? <Object?>[] : decoded as List<Object?>,
      ),
    );
    return SessionManagerHostApi.pigeonChannelCodec.encodeMessage(
      <Object?>[result],
    );
  });
}

/// Simulates a native event delivered through the pigeon Flutter API.
Future<void> _emitFromNative(String method, List<Object?> args) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    '$_flutterApiPrefix.$method',
    SessionManagerFlutterApi.pigeonChannelCodec.encodeMessage(args),
    (_) {},
  );
}

/// Binds the pigeon Flutter API handler to [manager].
///
/// [SessionManagerFlutterApi.setUp] installs a single, global channel
/// handler, so every test has to (re)bind it to the manager under test
/// before native events are emitted.
Future<void> _bindFlutterApi(
  GoogleCastSessionManagerAndroidMethodChannel manager,
) async {
  _mockHostApi('endSession', <_HostApiCall>[], result: true);
  await manager.endSession();
}

/// A device as it is discovered on Android.
GoogleCastDevice _device() => GoogleCastDevice(
      deviceID: 'device-1',
      friendlyName: 'Living Room TV',
      modelName: 'Chromecast',
      statusText: null,
      deviceVersion: '5',
      isOnLocalNetwork: true,
      category: 'cast',
      uniqueID: 'device-1',
    );

/// A connected session as it is reported by the native side.
CastSessionPigeon _sessionPigeon() => CastSessionPigeon(
      device: CastDevicePigeon(
        deviceId: 'device-1',
        friendlyName: 'Living Room TV',
        deviceVersion: '5',
        isOnLocalNetwork: true,
        category: 'cast',
        uniqueId: 'device-1',
      ),
      sessionId: 'session-1',
      connectionState: ConnectionStatePigeon.connected,
      currentDeviceMuted: false,
      currentDeviceVolume: 1.0,
      deviceStatusText: 'Ready To Cast',
    );

void main() {
  group('GoogleCastSessionManagerAndroidMethodChannel', () {
    late GoogleCastSessionManagerAndroidMethodChannel manager;
    late List<_HostApiCall> calls;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      calls = [];
      manager = GoogleCastSessionManagerAndroidMethodChannel();
      await _bindFlutterApi(manager);
    });

    tearDown(() {
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final method in <String>[
        'startSessionWithDevice',
        'endSession',
        'endSessionAndStopCasting',
        'resetSession',
        'addMessageChannel',
        'removeMessageChannel',
        'sendMessage',
      ]) {
        messenger.setMockMessageHandler('$_hostApiPrefix.$method', null);
      }
      manager.dispose();
    });

    test('should implement GoogleCastSessionManagerPlatformInterface', () {
      expect(manager, isA<GoogleCastSessionManagerPlatformInterface>());
    });

    test('startSessionWithDevice forwards the device id to the native side',
        () async {
      _mockHostApi('startSessionWithDevice', calls, result: true);

      final result = await manager.startSessionWithDevice(_device());

      expect(result, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'startSessionWithDevice');
      final request = calls.single.args.single as StartSessionRequest;
      expect(request.deviceId, 'device-1');
    });

    test('startSessionWithDevice propagates false from the native side',
        () async {
      _mockHostApi('startSessionWithDevice', calls, result: false);

      final result = await manager.startSessionWithDevice(_device());

      expect(result, isFalse);
      expect(calls.single.method, 'startSessionWithDevice');
    });

    test(
        'resetSession delegates to endSessionAndStopCasting on Android '
        'because stale sessions are not observed on that platform', () async {
      _mockHostApi('endSessionAndStopCasting', calls, result: true);

      final result = await manager.resetSession();

      expect(result, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'endSessionAndStopCasting');
    });

    test('resetSession propagates false from endSessionAndStopCasting',
        () async {
      _mockHostApi('endSessionAndStopCasting', calls, result: false);

      final result = await manager.resetSession();

      expect(result, isFalse);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'endSessionAndStopCasting');
    });

    test('custom message methods forward namespace and payload', () async {
      _mockHostApi('addMessageChannel', calls, result: true);
      _mockHostApi('sendMessage', calls, result: true);
      _mockHostApi('removeMessageChannel', calls, result: true);

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

      expect(calls.map((call) => call.method), <String>[
        'addMessageChannel',
        'sendMessage',
        'removeMessageChannel',
      ]);
      expect(calls[0].args, <Object?>['urn:x-cast:example.channel']);
      expect(calls[1].args, <Object?>[
        'urn:x-cast:example.channel',
        '{"command":"ping"}',
      ]);
      expect(calls[2].args, <Object?>['urn:x-cast:example.channel']);
    });

    test('emits receiver messages with their namespace', () async {
      final messageFuture = manager.messageStream.first;

      await _emitFromNative('onMessageReceived', <Object?>[
        'urn:x-cast:example.channel',
        '{"status":"ready"}',
      ]);

      final message = await messageFuture;
      expect(message.namespace, 'urn:x-cast:example.channel');
      expect(message.message, '{"status":"ready"}');
    });

    test('drops malformed receiver messages instead of throwing', () async {
      final received = <GoogleCastMessage>[];
      final subscription = manager.messageStream.listen(received.add);

      // The pigeon codec rejects payloads that do not match the API
      // signature, and they must never reach the message stream.
      await expectLater(
        _emitFromNative('onMessageReceived', <Object?>[42, 'text']),
        throwsA(isA<Error>()),
      );
      await expectLater(
        _emitFromNative('onMessageReceived', <Object?>[
          'urn:x-cast:example.channel',
        ]),
        throwsA(isA<Error>()),
      );

      expect(received, isEmpty);
      await subscription.cancel();
    });

    test('onSessionChanged updates the current session', () async {
      await _emitFromNative('onSessionChanged', <Object?>[_sessionPigeon()]);

      final session = manager.currentSession;
      expect(session, isNotNull);
      expect(session!.sessionID, 'session-1');
      expect(session.device?.deviceID, 'device-1');
      expect(session.device?.friendlyName, 'Living Room TV');
      expect(session.connectionState, GoogleCastConnectState.connected);
      expect(manager.connectionState, GoogleCastConnectState.connected);
      expect(manager.hasConnectedSession, isTrue);
    });

    test('a null session event clears the current session', () async {
      await _emitFromNative('onSessionChanged', <Object?>[_sessionPigeon()]);
      expect(manager.currentSession, isNotNull);

      await _emitFromNative('onSessionChanged', <Object?>[null]);

      expect(manager.currentSession, isNull);
      expect(manager.connectionState, GoogleCastConnectState.disconnected);
      expect(manager.hasConnectedSession, isFalse);
    });

    test('dispose closes the message stream and drops later events', () async {
      manager.dispose();

      // A closed broadcast stream emits done to new listeners immediately.
      await expectLater(manager.messageStream, emitsDone);
      // A late native event must be a no-op, not a StateError.
      await _emitFromNative('onMessageReceived', <Object?>[
        'urn:x-cast:example.channel',
        'late',
      ]);
    });

    test(
        'dispose clears the cached session and drops late session events '
        'instead of surfacing stale data', () async {
      await _emitFromNative('onSessionChanged', <Object?>[_sessionPigeon()]);

      expect(manager.currentSession?.sessionID, 'session-1');
      expect(manager.connectionState, GoogleCastConnectState.connected);
      expect(manager.hasConnectedSession, isTrue);

      manager.dispose();

      expect(manager.currentSession, isNull);
      expect(manager.connectionState, GoogleCastConnectState.disconnected);
      expect(manager.hasConnectedSession, isFalse);

      // A late native session event must be a no-op, not a StateError.
      await _emitFromNative('onSessionChanged', <Object?>[null]);
    });
  });
}
