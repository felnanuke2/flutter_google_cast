import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        'packages/flutter_chrome_cast_platform_interface/lib/src/pigeon/google_cast_context_pigeon.g.dart',
    kotlinOut:
      'packages/flutter_chrome_cast_android/android/src/main/kotlin/com/felnanuke/google_cast/pigeon/GoogleCastContextPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.felnanuke.google_cast.pigeon',
      includeErrorClass: false,
    ),
    swiftOut:
      'packages/flutter_chrome_cast_ios/ios/flutter_chrome_cast/Sources/flutter_chrome_cast/GoogleCastContextPigeon.g.swift',
    swiftOptions: SwiftOptions(
      includeErrorClass: false,
    ),
    dartPackageName: 'flutter_chrome_cast_platform_interface',
  ),
)
class DiscoveryCriteriaPigeon {
  DiscoveryCriteriaPigeon({
    required this.method,
    this.applicationID,
    this.namespaces,
  });

  String method;
  String? applicationID;
  List<String?>? namespaces;
}

class CastOptionsPigeon {
  CastOptionsPigeon({
    required this.physicalVolumeButtonsWillControlDeviceVolume,
    required this.disableDiscoveryAutostart,
    required this.disableAnalyticsLogging,
    required this.suspendSessionsWhenBackgrounded,
    required this.stopReceiverApplicationWhenEndingSession,
    required this.startDiscoveryAfterFirstTapOnCastButton,
    required this.stopCastingOnAppTerminated,
    this.appId,
    this.discoveryCriteria,
  });

  bool physicalVolumeButtonsWillControlDeviceVolume;
  bool disableDiscoveryAutostart;
  bool disableAnalyticsLogging;
  bool suspendSessionsWhenBackgrounded;
  bool stopReceiverApplicationWhenEndingSession;
  bool startDiscoveryAfterFirstTapOnCastButton;
  bool stopCastingOnAppTerminated;
  String? appId;
  DiscoveryCriteriaPigeon? discoveryCriteria;
}

class CastContextInitRequest {
  CastContextInitRequest({required this.options});

  CastOptionsPigeon options;
}

@HostApi()
abstract class GoogleCastContextHostApi {
  bool setSharedInstanceWithOptions(CastContextInitRequest request);
}
