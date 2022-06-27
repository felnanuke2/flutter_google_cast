class GoogleCastDevice {
  final int? index;
  final String deviceID;
  final String friendlyName;
  final String? modelName;
  // final List<CastImage> icons;
  // final CastDeviceStatus status;
  final String? statusText;
  final String deviceVersion;
  final bool isOnLocalNetwork;
  // final CastDeviceType type;
  final String category;
  final String uniqueID;

  GoogleCastDevice({
    required this.deviceID,
    required this.friendlyName,
    required this.modelName,
    required this.statusText,
    required this.deviceVersion,
    required this.isOnLocalNetwork,
    required this.category,
    required this.uniqueID,
    required this.index,
  });
}
