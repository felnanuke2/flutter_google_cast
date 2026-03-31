import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'package:flutter_chrome_cast/google_cast_context/google_cast_context.dart';
import 'package:flutter_chrome_cast/google_cast_context/google_cast_context_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakeContextPlatform extends GoogleCastContextPlatformInterface
    with MockPlatformInterfaceMixin {
  _FakeContextPlatform(this.valueToReturn);

  final bool valueToReturn;
  GoogleCastOptions? lastOptions;

  @override
  Future<bool> setSharedInstanceWithOptions(
    GoogleCastOptions castOptions,
  ) async {
    lastOptions = castOptions;
    return valueToReturn;
  }
}

void main() {
  group('GoogleCastContext facade', () {
    test('delegates calls to registered platform implementation', () async {
      final fakePlatform = _FakeContextPlatform(true);
      GoogleCastContextPlatformInterface.instance = fakePlatform;

      final result = await GoogleCastContext.instance
          .setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isTrue);
      expect(fakePlatform.lastOptions, isNotNull);
      expect(GoogleCastContext.instance, same(fakePlatform));
    });
  });
}
