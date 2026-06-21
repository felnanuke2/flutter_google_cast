import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:rxdart/subjects.dart';

class _DiscoveryFlutterApiHandler extends DiscoveryManagerFlutterApi {
  _DiscoveryFlutterApiHandler(this._onDevicesChanged);

  final void Function(List<CastDevicePigeon> devices) _onDevicesChanged;

  @override
  void onDevicesChanged(List<CastDevicePigeon> devices) {
    _onDevicesChanged(devices);
  }
}

/// iOS-specific implementation of the Google Cast discovery manager.
///
/// This class handles the discovery of Google Cast devices on iOS platform
/// using method channels to communicate with the native iOS implementation.
class GoogleCastDiscoveryManagerMethodChannelIOS
    extends GoogleCastDiscoveryManagerPlatformInterface {
  GoogleCastDiscoveryManagerMethodChannelIOS();

  final DiscoveryManagerHostApi _hostApi = DiscoveryManagerHostApi();
  bool _flutterApiSetUp = false;

  void _ensureFlutterApiSetUp() {
    if (_flutterApiSetUp) return;
    _flutterApiSetUp = true;
    DiscoveryManagerFlutterApi.setUp(
      _DiscoveryFlutterApiHandler(_onDevicesChanged),
    );
  }

  DiscoveryManagerHostApi get _api {
    _ensureFlutterApiSetUp();
    return _hostApi;
  }

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) async {
    return _api.isDiscoveryActiveForDeviceCategory(deviceCategory);
  }

  @override
  Future<void> startDiscovery() {
    return _api.startDiscovery();
  }

  @override
  Future<void> stopDiscovery() {
    return _api.stopDiscovery();
  }

  /// Handles device changes for testing purposes.
  /// This method is visible for testing and allows simulating device changes
  /// in unit tests by calling the internal [_onDevicesChanged] method.
  @visibleForTesting
  void onDevicesChanged(List<CastDevicePigeon> arguments) {
    _onDevicesChanged(arguments);
  }

  void _onDevicesChanged(List<CastDevicePigeon> arguments) {
    final devices = arguments
        .map(
          (device) => GoogleCastDevice(
            deviceID: device.deviceId,
            friendlyName: device.friendlyName,
            modelName: device.modelName,
            statusText: device.statusText,
            deviceVersion: device.deviceVersion,
            isOnLocalNetwork: device.isOnLocalNetwork,
            category: device.category,
            uniqueID: device.uniqueId,
          ),
        )
        .toList();

    _devicesStreamController.add(devices);
  }
}
