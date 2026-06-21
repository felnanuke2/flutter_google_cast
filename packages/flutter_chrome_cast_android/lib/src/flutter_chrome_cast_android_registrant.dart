import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

import 'channels/android_cast_session_manager.dart';
import 'channels/android_discovery_manager.dart';
import 'channels/android_google_cast_context_method_channel.dart';
import 'channels/android_remote_media_client_method_channel.dart';

class FlutterChromeCastAndroid {
  FlutterChromeCastAndroid._();

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
