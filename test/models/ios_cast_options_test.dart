import 'package:flutter_chrome_cast_ios/flutter_chrome_cast_ios.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IOSGoogleCastOptions', () {
    final criteria =
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID('CC1AD845');

    test('extends base cast options contract', () {
      final options = IOSGoogleCastOptions(criteria);
      expect(options, isA<GoogleCastOptions>());
    });

    test('exposes provided discovery criteria', () {
      final options = IOSGoogleCastOptions(criteria);
      expect(options.discoveryCriteria, same(criteria));
      expect(options.discoveryCriteria.applicationID, 'CC1AD845');
    });

    test('keeps inherited option flags', () {
      final options = IOSGoogleCastOptions(
        criteria,
        disableDiscoveryAutostart: true,
        stopCastingOnAppTerminated: true,
      );

      expect(options.disableDiscoveryAutostart, isTrue);
      expect(options.stopCastingOnAppTerminated, isTrue);
      expect(options.startDiscoveryAfterFirstTapOnCastButton, isTrue);
    });
  });
}
