import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'google_cast_platform_interface.dart';

/// An implementation of [GoogleCastPlatform] that uses method channels.
class MethodChannelGoogleCast extends GoogleCastPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('google_cast');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
