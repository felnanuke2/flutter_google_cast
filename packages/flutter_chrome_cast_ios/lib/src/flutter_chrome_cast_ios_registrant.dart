import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

import 'channels/ios_cast_session_manager.dart';
import 'channels/ios_discovery_manager.dart';
import 'channels/ios_google_cast_context_method_channel.dart';
import 'channels/ios_remote_media_client_method_channel.dart';

/// Entry point for the iOS platform implementation of `flutter_chrome_cast`.
///
/// Flutter tooling calls [registerWith] automatically when building for iOS
/// because this class is declared as `dartPluginClass` in the package's pubspec.yaml.
///
/// Each platform interface instance is registered here so that the app-facing
/// package can delegate to the correct implementation without knowing about
/// platform-specific classes directly.
class FlutterChromeCastIos {
  FlutterChromeCastIos._();

  /// Registers all iOS platform implementations with their respective
  /// platform interfaces.
  ///
  /// Called automatically by Flutter's generated plugin registrant before
  /// any application code runs.
  static void registerWith() {
    GoogleCastContextPlatformInterface.instance =
        FlutterIOSGoogleCastContextMethodChannel();
    GoogleCastDiscoveryManagerPlatformInterface.instance =
        GoogleCastDiscoveryManagerMethodChannelIOS();
    GoogleCastSessionManagerPlatformInterface.instance =
        GoogleCastSessionManagerIOSMethodChannel();
    GoogleCastRemoteMediaClientPlatformInterface.instance =
        GoogleCastRemoteMediaClientIOSMethodChannel();
  }
}
