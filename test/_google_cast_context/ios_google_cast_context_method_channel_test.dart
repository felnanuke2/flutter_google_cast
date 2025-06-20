import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_google_cast_context/ios_google_cast_context_method_channel.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

void main() {
  group('FlutterIOSGoogleCastContextMethodChannel', () {
    late FlutterIOSGoogleCastContextMethodChannel contextManager;
    late List<MethodCall> methodCalls;
    late MethodChannel channel;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      methodCalls = [];
      channel = const MethodChannel('google_cast.context');
      contextManager = FlutterIOSGoogleCastContextMethodChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('should implement GoogleCastContextPlatformInterface', () {
      expect(contextManager, isA<GoogleCastContextPlatformInterface>());
    });

    test(
        'setSharedInstanceWithOptions should return true when native method returns true',
        () async {
      // Set up the mock to return true
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return true;
      });

      final castOptions = GoogleCastOptions(
        physicalVolumeButtonsWillControlDeviceVolume: true,
        disableDiscoveryAutostart: false,
        disableAnalyticsLogging: false,
        suspendSessionsWhenBackgrounded: true,
        stopReceiverApplicationWhenEndingSession: false,
        startDiscoveryAfterFirstTapOnCastButton: true,
      );

      final result =
          await contextManager.setSharedInstanceWithOptions(castOptions);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
      expect(methodCalls.first.arguments, equals(castOptions.toMap()));
    });

    test(
        'setSharedInstanceWithOptions should return false when native method returns false',
        () async {
      // Set up the mock to return false
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return false;
      });

      final castOptions = GoogleCastOptions();

      final result =
          await contextManager.setSharedInstanceWithOptions(castOptions);

      expect(result, isFalse);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
    });

    test(
        'setSharedInstanceWithOptions should return false when native method returns null',
        () async {
      // Set up the mock to return null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return null;
      });

      final castOptions = GoogleCastOptions();

      final result =
          await contextManager.setSharedInstanceWithOptions(castOptions);

      expect(result, isFalse);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
    });

    test(
        'setSharedInstanceWithOptions should return false when native method returns non-boolean',
        () async {
      // Set up the mock to return a string
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return 'success';
      });

      final castOptions = GoogleCastOptions();

      final result =
          await contextManager.setSharedInstanceWithOptions(castOptions);

      expect(result, isFalse);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
    });

    test(
        'setSharedInstanceWithOptions should rethrow exceptions from native method',
        () async {
      final testException = PlatformException(
        code: 'TEST_ERROR',
        message: 'Test error message',
      );

      // Set up the mock to throw an exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        throw testException;
      });

      final castOptions = GoogleCastOptions();

      expect(
        () => contextManager.setSharedInstanceWithOptions(castOptions),
        throwsA(isA<PlatformException>()
            .having(
              (e) => e.code,
              'code',
              'TEST_ERROR',
            )
            .having(
              (e) => e.message,
              'message',
              'Test error message',
            )),
      );

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
    });

    test(
        'setSharedInstanceWithOptions should handle custom cast options correctly',
        () async {
      // Set up the mock to return true
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return true;
      });

      final castOptions = GoogleCastOptions(
        physicalVolumeButtonsWillControlDeviceVolume: false,
        disableDiscoveryAutostart: true,
        disableAnalyticsLogging: true,
        suspendSessionsWhenBackgrounded: false,
        stopReceiverApplicationWhenEndingSession: true,
        startDiscoveryAfterFirstTapOnCastButton: false,
      );

      final result =
          await contextManager.setSharedInstanceWithOptions(castOptions);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
      expect(
          methodCalls.first.arguments,
          equals({
            'physicalVolumeButtonsWillControlDeviceVolume': false,
            'disableDiscoveryAutostart': true,
            'disableAnalyticsLogging': true,
            'suspendSessionsWhenBackgrounded': false,
            'stopReceiverApplicationWhenEndingSession': true,
            'startDiscoveryAfterFirstTapOnCastButton': false,
          }));
    });

    test(
        'setSharedInstanceWithOptions should handle default cast options correctly',
        () async {
      // Set up the mock to return true
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        return true;
      });

      final castOptions = GoogleCastOptions();

      final result =
          await contextManager.setSharedInstanceWithOptions(castOptions);

      expect(result, isTrue);
      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
      expect(
          methodCalls.first.arguments,
          equals({
            'physicalVolumeButtonsWillControlDeviceVolume': true,
            'disableDiscoveryAutostart': false,
            'disableAnalyticsLogging': false,
            'suspendSessionsWhenBackgrounded': true,
            'stopReceiverApplicationWhenEndingSession': false,
            'startDiscoveryAfterFirstTapOnCastButton': true,
          }));
    });

    test('setSharedInstanceWithOptions should handle method channel exceptions',
        () async {
      // Set up the mock to throw a general exception
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);
        throw Exception('General error');
      });

      final castOptions = GoogleCastOptions();

      expect(
        () => contextManager.setSharedInstanceWithOptions(castOptions),
        throwsA(isA<Exception>()),
      );

      expect(methodCalls, hasLength(1));
      expect(methodCalls.first.method, equals('setSharedInstanceWithOptions'));
    });

    test('should use correct method channel name', () {
      // Verify that the class uses the correct method channel
      expect(contextManager, isA<FlutterIOSGoogleCastContextMethodChannel>());
      expect(contextManager, isA<GoogleCastContextPlatformInterface>());
    });
  });
}
