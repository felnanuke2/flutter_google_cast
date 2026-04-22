import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_session_manager/ios_cast_session_manager.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';

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

    test('resetSession propagates false returned by the native side',
        () async {
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
