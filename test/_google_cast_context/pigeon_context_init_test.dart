import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast_android/flutter_chrome_cast_android.dart';
import 'package:flutter_chrome_cast_ios/flutter_chrome_cast_ios.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Pigeon context init Android', () {
    const methodChannel = MethodChannel('com.felnanuke.google_cast.context');

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('uses Pigeon when host API is available', () async {
      final context = GoogleCastContextAndroidMethodChannel(
        hostApi: _FakeHostApi(result: true),
      );

      final result = await context.setSharedInstanceWithOptions(
        GoogleCastOptionsAndroid(appId: 'APP_ID'),
      );

      expect(result, isTrue);
    });

    test('falls back to MethodChannel on channel-error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        if (call.method == 'setSharedInstance') {
          return true;
        }
        return null;
      });

      final context = GoogleCastContextAndroidMethodChannel(
        hostApi: _FakeHostApi(channelError: true),
      );

      final result = await context.setSharedInstanceWithOptions(
        GoogleCastOptionsAndroid(appId: 'APP_ID'),
      );

      expect(result, isTrue);
    });
  });

  group('Pigeon context init iOS', () {
    const methodChannel = MethodChannel('google_cast.context');

    tearDown(() async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    test('uses Pigeon when host API is available', () async {
      final context = FlutterIOSGoogleCastContextMethodChannel(
        hostApi: _FakeHostApi(result: true),
      );

      final result = await context.setSharedInstanceWithOptions(
        IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID('APP_ID'),
        ),
      );

      expect(result, isTrue);
    });

    test('falls back to MethodChannel on channel-error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, (call) async {
        if (call.method == 'setSharedInstanceWithOptions') {
          return true;
        }
        return null;
      });

      final context = FlutterIOSGoogleCastContextMethodChannel(
        hostApi: _FakeHostApi(channelError: true),
      );

      final result = await context.setSharedInstanceWithOptions(
        IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID('APP_ID'),
        ),
      );

      expect(result, isTrue);
    });
  });
}

class _FakeHostApi extends GoogleCastContextHostApi {
  _FakeHostApi({this.result = true, this.channelError = false});

  final bool result;
  final bool channelError;

  @override
  Future<bool> setSharedInstanceWithOptions(
      CastContextInitRequest request) async {
    if (channelError) {
      throw PlatformException(code: 'channel-error');
    }
    return result;
  }
}
