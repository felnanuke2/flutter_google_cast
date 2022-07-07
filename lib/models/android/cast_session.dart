import 'dart:convert';

import 'package:google_cast/lib.dart';
import 'package:google_cast/models/android/cast_device.dart';

class GoogleCastSessionAndroid extends GoogleCastSession {
  GoogleCastSessionAndroid({
    required super.device,
    required super.sessionID,
    required super.connectionState,
    required super.currentDeviceMuted,
    required super.currentDeviceVolume,
    required super.deviceStatusText,
  });

  factory GoogleCastSessionAndroid.fromMap(Map<String, dynamic> map) {
    final device = map['device'];
    return GoogleCastSessionAndroid(
      device: device != null
          ? GoogleCastAndroidDevice.fromMap(jsonDecode(map['device']))
          : null,
      sessionID: map['sessionID'],
      connectionState: GoogleCastConnectState.values[map['connectionState']],
      currentDeviceMuted: map['isMute'],
      currentDeviceVolume: map['volume'],
      deviceStatusText: map['statusMessage']?? '',
    );
  }
}
