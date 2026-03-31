import 'package:flutter_chrome_cast_android/flutter_chrome_cast_android.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAndroidContextHostApi extends GoogleCastContextHostApi {
  _FakeAndroidContextHostApi({required this.result});

  final bool result;
  CastContextInitRequest? capturedRequest;

  @override
  Future<bool> setSharedInstanceWithOptions(
    CastContextInitRequest request,
  ) async {
    capturedRequest = request;
    return result;
  }
}

void main() {
  group('GoogleCastContextAndroidMethodChannel', () {
    test('implements context platform contract', () {
      final context = GoogleCastContextAndroidMethodChannel(
        hostApi: _FakeAndroidContextHostApi(result: true),
      );

      expect(context, isA<GoogleCastContextPlatformInterface>());
    });

    test('maps Android options into pigeon payload', () async {
      final fakeHost = _FakeAndroidContextHostApi(result: true);
      final context = GoogleCastContextAndroidMethodChannel(hostApi: fakeHost);

      final success = await context.setSharedInstanceWithOptions(
        GoogleCastOptionsAndroid(
          appId: 'CC1AD845',
          stopCastingOnAppTerminated: true,
        ),
      );

      expect(success, isTrue);
      expect(fakeHost.capturedRequest, isNotNull);
      expect(fakeHost.capturedRequest!.options.appId, 'CC1AD845');
      expect(fakeHost.capturedRequest!.options.discoveryCriteria, isNull);
      expect(
        fakeHost.capturedRequest!.options.stopCastingOnAppTerminated,
        isTrue,
      );
    });
  });
}
