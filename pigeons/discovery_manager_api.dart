import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        'packages/flutter_chrome_cast_platform_interface/lib/src/pigeon/discovery_manager_pigeon.g.dart',
    kotlinOut:
        'packages/flutter_chrome_cast_android/android/src/main/kotlin/com/felnanuke/google_cast/pigeon/DiscoveryManagerPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.felnanuke.google_cast.pigeon',
    ),
    swiftOut:
        'packages/flutter_chrome_cast_ios/ios/flutter_chrome_cast/Sources/flutter_chrome_cast/DiscoveryManagerPigeon.g.swift',
    dartPackageName: 'flutter_chrome_cast_platform_interface',
  ),
)
class CastDevicePigeon {
  CastDevicePigeon({
    required this.deviceId,
    required this.friendlyName,
    this.modelName,
    this.statusText,
    required this.deviceVersion,
    required this.isOnLocalNetwork,
    required this.category,
    required this.uniqueId,
    this.index,
  });

  String deviceId;
  String friendlyName;
  String? modelName;
  String? statusText;
  String deviceVersion;
  bool isOnLocalNetwork;
  String category;
  String uniqueId;
  int? index;
}

@HostApi()
abstract class DiscoveryManagerHostApi {
  void startDiscovery();

  void stopDiscovery();

  bool isDiscoveryActiveForDeviceCategory(String deviceCategory);
}

@FlutterApi()
abstract class DiscoveryManagerFlutterApi {
  void onDevicesChanged(List<CastDevicePigeon> devices);
}
