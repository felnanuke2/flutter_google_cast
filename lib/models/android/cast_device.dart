import 'package:google_cast/lib.dart';

extension GoogleCastAndroidDevices on GoogleCastAndroidDevice {
  static List<GoogleCastAndroidDevice> fromMap(List maps) {
    final devices =
        maps.map((e) => GoogleCastAndroidDevice.fromMap(e)).toList();
    return devices;
  }
}

class GoogleCastAndroidDevice extends GoogleCastDevice {
  GoogleCastAndroidDevice({
    required super.deviceID,
    required super.friendlyName,
    required super.modelName,
    required super.statusText,
    required super.deviceVersion,
    required super.isOnLocalNetwork,
    required super.category,
    required super.uniqueID,
  });

  factory GoogleCastAndroidDevice.fromMap(Map<String, dynamic> map) {
    return GoogleCastAndroidDevice(
      deviceID: map['zzb'],
      friendlyName: map['zzd'],
      modelName: map['zze'],
      deviceVersion: map['zzf'],
      category: '',
      isOnLocalNetwork: !map['zzq'],
      statusText: null,
      uniqueID: map['zzb'],
    );
  }
}
