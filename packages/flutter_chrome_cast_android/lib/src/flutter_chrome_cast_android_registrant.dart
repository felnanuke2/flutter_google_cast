import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

import 'channels/android_cast_session_manager.dart';
import 'channels/android_discovery_manager.dart';
import 'channels/android_google_cast_context_method_channel.dart';
import 'channels/android_remote_media_client_method_channel.dart';

/// Entry point for the Android platform implementation of `flutter_chrome_cast`.
///
/// Flutter tooling calls [registerWith] automatically when building for Android
/// because this class is declared as `dartPluginClass` in the package's pubspec.yaml.
///
/// Each platform interface instance is registered here so that the app-facing
/// package can delegate to the correct implementation without knowing about
/// platform-specific classes directly.
class FlutterChromeCastAndroid {
  FlutterChromeCastAndroid._();

  /// Registers all Android platform implementations with their respective
  /// platform interfaces.
  ///
  /// Called automatically by Flutter's generated plugin registrant before
  /// any application code runs.
  static void registerWith() {
    GoogleCastContextPlatformInterface.instance =
        GoogleCastContextAndroidMethodChannel();
    GoogleCastDiscoveryManagerPlatformInterface.instance =
        GoogleCastDiscoveryManagerMethodChannelAndroid();
    GoogleCastSessionManagerPlatformInterface.instance =
        GoogleCastSessionManagerAndroidMethodChannel();
    GoogleCastRemoteMediaClientPlatformInterface.instance =
        GoogleCastRemoteMediaClientAndroidMethodChannel();
  }
}
