import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

import 'channels/ios_cast_session_manager.dart';
import 'channels/ios_discovery_manager.dart';
import 'channels/ios_google_cast_context_method_channel.dart';
import 'channels/ios_remote_media_client_method_channel.dart';

class FlutterChromeCastIos {
  FlutterChromeCastIos._();

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
