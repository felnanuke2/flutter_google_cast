import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context_platform_interface.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';

import '../helpers/mock_implementations.dart';

void main() {
  group('GoogleCastContext (federated plugin facade)', () {
    late MockGoogleCastContextPlatformInterface mockPlatform;

    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      mockPlatform = MockGoogleCastContextPlatformInterface();
      // Inject the mock implementation – this is the federated plugin pattern:
      // the app-facing class delegates to whatever instance is currently set.
      GoogleCastContext.instance = mockPlatform;
    });

    tearDown(() {
      // Restore the default platform implementation by setting a fresh default.
      // Because _testInstance is nullable and checked first by the getter,
      // resetting it to null (via the internal field) would restore the default.
      // The simplest safe approach is to set the same mock that setUp created
      // so subsequent teardown code still finds a valid instance.
      GoogleCastContext.instance = mockPlatform;
    });

    test('instance returns a GoogleCastContextPlatformInterface', () {
      expect(GoogleCastContext.instance,
          isA<GoogleCastContextPlatformInterface>());
    });

    test('instance is the injected mock', () {
      expect(GoogleCastContext.instance, same(mockPlatform));
    });

    test('setSharedInstanceWithOptions delegates to platform interface', () async {
      final options = GoogleCastOptions();

      await GoogleCastContext.instance.setSharedInstanceWithOptions(options);

      expect(mockPlatform.callCount, equals(1));
      expect(mockPlatform.lastOptions, same(options));
    });

    test('setSharedInstanceWithOptions returns true when platform returns true',
        () async {
      mockPlatform.returnValue = true;

      final result = await GoogleCastContext.instance
          .setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isTrue);
    });

    test('setSharedInstanceWithOptions returns false when platform returns false',
        () async {
      mockPlatform.returnValue = false;

      final result = await GoogleCastContext.instance
          .setSharedInstanceWithOptions(GoogleCastOptions());

      expect(result, isFalse);
    });

    test('setSharedInstanceWithOptions forwards options correctly', () async {
      final options = GoogleCastOptions(
        physicalVolumeButtonsWillControlDeviceVolume: false,
        disableDiscoveryAutostart: true,
        suspendSessionsWhenBackgrounded: false,
      );

      await GoogleCastContext.instance.setSharedInstanceWithOptions(options);

      expect(mockPlatform.lastOptions, equals(options));
    });

    test('replacing the instance changes which implementation is used', () async {
      final firstMock = MockGoogleCastContextPlatformInterface()
        ..returnValue = true;
      final secondMock = MockGoogleCastContextPlatformInterface()
        ..returnValue = false;

      GoogleCastContext.instance = firstMock;
      final firstResult = await GoogleCastContext.instance
          .setSharedInstanceWithOptions(GoogleCastOptions());
      expect(firstResult, isTrue);

      GoogleCastContext.instance = secondMock;
      final secondResult = await GoogleCastContext.instance
          .setSharedInstanceWithOptions(GoogleCastOptions());
      expect(secondResult, isFalse);
    });
  });
}
