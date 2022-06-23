import 'package:flutter/services.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/session_manager/cast_session_manager.dart';

class GoogleCastIOSSessionManager implements AGoogleCastSessionManager {
  GoogleCastIOSSessionManager._();

  static final GoogleCastIOSSessionManager _instance =
      GoogleCastIOSSessionManager._();

  static GoogleCastIOSSessionManager get instance => _instance;

  final channel = const MethodChannel('google_cast.session_manager');

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    return await channel.invokeMethod(
      'startSessionWithDevice',
      device.index,
    );
  }
}
