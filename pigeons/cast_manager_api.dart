import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        'packages/flutter_chrome_cast_platform_interface/lib/src/pigeon/cast_manager_pigeon.g.dart',
    kotlinOut:
        'packages/flutter_chrome_cast_android/android/src/main/kotlin/com/felnanuke/google_cast/pigeon/CastManagerPigeon.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.felnanuke.google_cast.pigeon',
    ),
    swiftOut:
        'packages/flutter_chrome_cast_ios/ios/flutter_chrome_cast/Sources/flutter_chrome_cast/CastManagerPigeon.g.swift',
    dartPackageName: 'flutter_chrome_cast_platform_interface',
  ),
)

// ── Shared device model ──────────────────────────────────────────────────────

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

// ── Discovery ────────────────────────────────────────────────────────────────

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

// ── Session ──────────────────────────────────────────────────────────────────

enum ConnectionStatePigeon {
  disconnected,
  connecting,
  connected,
  disconnecting,
}

class CastSessionPigeon {
  CastSessionPigeon({
    this.device,
    this.sessionId,
    required this.connectionState,
    required this.currentDeviceMuted,
    required this.currentDeviceVolume,
    required this.deviceStatusText,
  });

  CastDevicePigeon? device;
  String? sessionId;
  ConnectionStatePigeon connectionState;
  bool currentDeviceMuted;
  double currentDeviceVolume;
  String deviceStatusText;
}

class StartSessionRequest {
  StartSessionRequest({
    this.deviceId,
    this.deviceIndex,
  });

  String? deviceId;
  int? deviceIndex;
}

@HostApi()
abstract class SessionManagerHostApi {
  bool startSessionWithDevice(StartSessionRequest request);

  bool endSession();

  bool endSessionAndStopCasting();

  void setDeviceVolume(double value);
}

@FlutterApi()
abstract class SessionManagerFlutterApi {
  void onSessionChanged(CastSessionPigeon? session);
}
