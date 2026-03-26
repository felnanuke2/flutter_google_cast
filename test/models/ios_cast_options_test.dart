import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'package:flutter_chrome_cast/entities/discovery_criteria.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_options.dart';

void main() {
  group('IOSGoogleCastOptions.toMap', () {
    final discoveryCriteria =
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID('CC1AD845');

    test('includes discoveryCriteria in map', () {
      final options = IOSGoogleCastOptions(discoveryCriteria);
      final map = options.toMap();

      expect(map.containsKey('discoveryCriteria'), isTrue);
      expect(map['discoveryCriteria'], isA<Map>());
    });

    test('includes all base GoogleCastOptions fields in map', () {
      final options = IOSGoogleCastOptions(discoveryCriteria);
      final map = options.toMap();

      expect(map.containsKey('physicalVolumeButtonsWillControlDeviceVolume'),
          isTrue);
      expect(map.containsKey('suspendSessionsWhenBackgrounded'), isTrue);
      expect(map.containsKey('disableDiscoveryAutostart'), isTrue);
      expect(map.containsKey('disableAnalyticsLogging'), isTrue);
      expect(
          map.containsKey('stopReceiverApplicationWhenEndingSession'), isTrue);
      expect(
          map.containsKey('startDiscoveryAfterFirstTapOnCastButton'), isTrue);
      expect(map.containsKey('stopCastingOnAppTerminated'), isTrue);
    });

    test('default values match GoogleCastOptions defaults', () {
      final options = IOSGoogleCastOptions(discoveryCriteria);
      final map = options.toMap();

      // These mirror the defaults in GoogleCastOptions
      expect(map['physicalVolumeButtonsWillControlDeviceVolume'], isTrue);
      expect(map['suspendSessionsWhenBackgrounded'], isTrue);
      expect(map['disableDiscoveryAutostart'], isFalse);
      expect(map['disableAnalyticsLogging'], isFalse);
      expect(map['stopReceiverApplicationWhenEndingSession'], isFalse);
      expect(map['startDiscoveryAfterFirstTapOnCastButton'], isTrue);
      expect(map['stopCastingOnAppTerminated'], isFalse);
    });

    test('respects suspendSessionsWhenBackgrounded = false', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        suspendSessionsWhenBackgrounded: false,
      );
      final map = options.toMap();

      expect(map['suspendSessionsWhenBackgrounded'], isFalse);
    });

    test('respects physicalVolumeButtonsWillControlDeviceVolume = false', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        physicalVolumeButtonsWillControlDeviceVolume: false,
      );
      final map = options.toMap();

      expect(map['physicalVolumeButtonsWillControlDeviceVolume'], isFalse);
    });

    test('respects disableDiscoveryAutostart = true', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        disableDiscoveryAutostart: true,
      );
      final map = options.toMap();

      expect(map['disableDiscoveryAutostart'], isTrue);
    });

    test('respects disableAnalyticsLogging = true', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        disableAnalyticsLogging: true,
      );
      final map = options.toMap();

      expect(map['disableAnalyticsLogging'], isTrue);
    });

    test('respects stopReceiverApplicationWhenEndingSession = true', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        stopReceiverApplicationWhenEndingSession: true,
      );
      final map = options.toMap();

      expect(map['stopReceiverApplicationWhenEndingSession'], isTrue);
    });

    test('respects startDiscoveryAfterFirstTapOnCastButton = false', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        startDiscoveryAfterFirstTapOnCastButton: false,
      );
      final map = options.toMap();

      expect(map['startDiscoveryAfterFirstTapOnCastButton'], isFalse);
    });

    test('respects stopCastingOnAppTerminated = true', () {
      final options = IOSGoogleCastOptions(
        discoveryCriteria,
        stopCastingOnAppTerminated: true,
      );
      final map = options.toMap();

      expect(map['stopCastingOnAppTerminated'], isTrue);
    });

    test('is a subtype of GoogleCastOptions', () {
      final options = IOSGoogleCastOptions(discoveryCriteria);
      expect(options, isA<GoogleCastOptions>());
    });

    test('toMap with namespaces discovery criteria', () {
      final nsDiscoveryCriteria =
          GoogleCastDiscoveryCriteriaInitialize.initWithNamespaces(
              {'urn:x-cast:com.example'});
      final options = IOSGoogleCastOptions(nsDiscoveryCriteria);
      final map = options.toMap();

      expect(map['discoveryCriteria']['method'], 'initWithNamespaces');
    });
  });
}
