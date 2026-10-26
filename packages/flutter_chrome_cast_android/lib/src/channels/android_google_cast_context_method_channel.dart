import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

import 'android_cast_session_manager.dart';
import 'android_discovery_manager.dart';
import 'android_remote_media_client_method_channel.dart';

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
    // This is the first call every app makes. Registering every manager's
    // native event handler here guarantees events such as an auto-resumed
    // session are received even though no manager method was called yet.
    // (Constructors cannot do this: plugin registration runs before the
    // Flutter binding is initialized.)
    _registerAllEventHandlers();
    final result = await _hostApi.setSharedInstanceWithOptions(
      CastContextInitRequest(options: _toCastOptionsPigeon(castOptions)),
    );
    return result == true;
  }

  void _registerAllEventHandlers() {
    final session = GoogleCastSessionManagerPlatformInterface.instance;
    if (session is GoogleCastSessionManagerAndroidMethodChannel) {
      session.ensureEventHandlersRegistered();
    }
    final discovery = GoogleCastDiscoveryManagerPlatformInterface.instance;
    if (discovery is GoogleCastDiscoveryManagerMethodChannelAndroid) {
      discovery.ensureEventHandlersRegistered();
    }
    final remoteMediaClient =
        GoogleCastRemoteMediaClientPlatformInterface.instance;
    if (remoteMediaClient is GoogleCastRemoteMediaClientAndroidMethodChannel) {
      remoteMediaClient.ensureEventHandlersRegistered();
    }
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
      logLevel: GoogleCastLoggerConfiguration.wireValue,
    );
  }
}
