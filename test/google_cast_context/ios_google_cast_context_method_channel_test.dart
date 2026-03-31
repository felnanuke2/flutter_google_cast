import 'package:flutter_chrome_cast_ios/flutter_chrome_cast_ios.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeIosContextHostApi extends GoogleCastContextHostApi {
  _FakeIosContextHostApi({required this.result});

  final bool result;
  CastContextInitRequest? capturedRequest;

  @override
  Future<bool> setSharedInstanceWithOptions(CastContextInitRequest request) async {
    capturedRequest = request;
    return result;
  }
}

void main() {
  group('FlutterIOSGoogleCastContextMethodChannel', () {
    test('implements context platform contract', () {
      final context = FlutterIOSGoogleCastContextMethodChannel(
        hostApi: _FakeIosContextHostApi(result: true),
      );

      expect(context, isA<GoogleCastContextPlatformInterface>());
    });

    test('maps discovery criteria into pigeon payload', () async {
      final fakeHost = _FakeIosContextHostApi(result: true);
      final context = FlutterIOSGoogleCastContextMethodChannel(hostApi: fakeHost);

      final result = await context.setSharedInstanceWithOptions(
        IOSGoogleCastOptions(
          GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID('APP_ID'),
          stopCastingOnAppTerminated: true,
        ),
      );

      expect(result, isTrue);
      expect(fakeHost.capturedRequest, isNotNull);
      expect(fakeHost.capturedRequest!.options.appId, isNull);
      expect(
        fakeHost.capturedRequest!.options.discoveryCriteria?.method,
        DiscoveryCriteriaMethodPigeon.initWithApplicationID,
      );
      expect(
        fakeHost.capturedRequest!.options.discoveryCriteria?.applicationID,
        'APP_ID',
      );
    });
  });
}