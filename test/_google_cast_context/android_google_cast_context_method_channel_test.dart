import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_google_cast_context/android_google_cast_context_method_channel.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

void main() {
  group('GoogleCastContextAndroidMethodChannel', () {
    late GoogleCastContextAndroidMethodChannel contextManager;
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('com.felnanuke.google_cast.context');

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      contextManager = GoogleCastContextAndroidMethodChannel();
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

    test('implements GoogleCastContextPlatformInterface', () {
      expect(contextManager, isA<GoogleCastContextPlatformInterface>());
    });

    test('setSharedInstanceWithOptions invokes setSharedInstance on the channel',
        () async {
      mockChannel((_) => true);

      await contextManager
          .setSharedInstanceWithOptions(GoogleCastOptions());

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstance'));
    });

    test('setSharedInstanceWithOptions passes options as arguments', () async {
      mockChannel((_) => true);

      final options = GoogleCastOptions(
        physicalVolumeButtonsWillControlDeviceVolume: false,
        disableDiscoveryAutostart: true,
        disableAnalyticsLogging: true,
        suspendSessionsWhenBackgrounded: false,
        stopReceiverApplicationWhenEndingSession: true,
        startDiscoveryAfterFirstTapOnCastButton: false,
      );

      await contextManager.setSharedInstanceWithOptions(options);

      expect(methodCalls.first.arguments, equals(options.toMap()));
    });

    test('setSharedInstanceWithOptions returns true when native returns true',
        () async {
      mockChannel((_) => true);

      final result =
          await contextManager.setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isTrue);
    });

    test('setSharedInstanceWithOptions returns false when native returns false',
        () async {
      mockChannel((_) => false);

      final result =
          await contextManager.setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isFalse);
    });

    test('setSharedInstanceWithOptions returns false when native returns null',
        () async {
      mockChannel((_) => null);

      final result =
          await contextManager.setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isFalse);
    });

    test(
        'setSharedInstanceWithOptions returns false when native returns non-boolean',
        () async {
      mockChannel((_) => 'success');

      final result =
          await contextManager.setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isFalse);
    });

    test('setSharedInstanceWithOptions rethrows PlatformException', () async {
      mockChannel((_) => throw PlatformException(
            code: 'TEST_ERROR',
            message: 'Test error',
          ));

      await expectLater(
        contextManager.setSharedInstanceWithOptions(GoogleCastOptions()),
        throwsA(isA<PlatformException>()
            .having((e) => e.code, 'code', 'TEST_ERROR')),
      );
    });
  });
}
