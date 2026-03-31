import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

/// iOS-specific implementation of Google Cast context functionality.
///
/// This class provides the iOS platform implementation for initializing
/// and managing the Google Cast context using method channels.
class FlutterIOSGoogleCastContextMethodChannel
    extends GoogleCastContextPlatformInterface {
  /// Creates the iOS Google Cast context bridge.
  FlutterIOSGoogleCastContextMethodChannel({GoogleCastContextHostApi? hostApi})
    : _hostApi = hostApi ?? GoogleCastContextHostApi();

  final GoogleCastContextHostApi _hostApi;

  @override
  Future<bool> setSharedInstanceWithOptions(
    GoogleCastOptions castOptions,
  ) async {
    final result = await _hostApi.setSharedInstanceWithOptions(
      CastContextInitRequest(options: _toCastOptionsPigeon(castOptions)),
    );
    return result == true;
  }

  CastOptionsPigeon _toCastOptionsPigeon(GoogleCastOptions castOptions) {
    return CastOptionsPigeon(
      physicalVolumeButtonsWillControlDeviceVolume:
          castOptions.physicalVolumeButtonsWillControlDeviceVolume,
      disableDiscoveryAutostart: castOptions.disableDiscoveryAutostart,
      disableAnalyticsLogging: castOptions.disableAnalyticsLogging,
      suspendSessionsWhenBackgrounded:
          castOptions.suspendSessionsWhenBackgrounded,
      stopReceiverApplicationWhenEndingSession:
          castOptions.stopReceiverApplicationWhenEndingSession,
      startDiscoveryAfterFirstTapOnCastButton:
          castOptions.startDiscoveryAfterFirstTapOnCastButton,
      stopCastingOnAppTerminated: castOptions.stopCastingOnAppTerminated,
      appId: null,
      discoveryCriteria: castOptions.discoveryCriteria != null
          ? DiscoveryCriteriaPigeon(
              method: _toDiscoveryCriteriaMethodPigeon(
                castOptions.discoveryCriteria!.method,
              ),
              applicationID: castOptions.discoveryCriteria!.applicationID,
              namespaces: castOptions.discoveryCriteria!.namespaces?.toList(),
            )
          : null,
    );
  }

  DiscoveryCriteriaMethodPigeon _toDiscoveryCriteriaMethodPigeon(
    GoogleCastDiscoveryCriteriaInitMethod method,
  ) {
    switch (method) {
      case GoogleCastDiscoveryCriteriaInitMethod.initWithApplicationID:
        return DiscoveryCriteriaMethodPigeon.initWithApplicationID;
      case GoogleCastDiscoveryCriteriaInitMethod.initWithNamespaces:
        return DiscoveryCriteriaMethodPigeon.initWithNamespaces;
    }
  }
}
