import 'dart:io';

import 'package:google_cast/_remote_media_client/remote_media_client_platform.dart';

import 'android_remote_media_client_method_channel.dart';
import 'ios_remote_media_client_method_channel.dart';

class RemoteMediaClient {
  RemoteMediaClient._();

  static final GoogleCastRemoteMediaClientPlatformInterface _instance =
      Platform.isAndroid
          ? GoogleCastRemoteMediaClientAndroidMethodChannel()
          : GoogleCastRemoteMediaClientIOSMethodChannel();

  static get instance => _instance;
}
