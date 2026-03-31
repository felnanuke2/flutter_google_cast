import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

/// Android-specific implementation of Google Cast context functionality.
///
/// This class provides the Android platform implementation for initializing
/// and managing the Google Cast context using method channels.
class GoogleCastContextAndroidMethodChannel
    extends GoogleCastContextPlatformInterface {
  /// Creates the Android Google Cast context bridge.
  GoogleCastContextAndroidMethodChannel({GoogleCastContextHostApi? hostApi})
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
      appId: castOptions.appId,
      discoveryCriteria: null,
    );
  }
}
