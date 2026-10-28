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

/// Android-specific implementation of the Google Cast discovery manager.
///
/// This class handles the discovery of Google Cast devices on Android platform
/// using method channels to communicate with the native Android implementation.
class GoogleCastDiscoveryManagerMethodChannelAndroid
    extends GoogleCastDiscoveryManagerPlatformInterface {
  /// Creates a new Android discovery manager method channel.
  ///
  /// The native event handler is registered eagerly so device-list updates
  /// pushed by the receiver during startup are never dropped.
  GoogleCastDiscoveryManagerMethodChannelAndroid();

  final DiscoveryManagerHostApi _hostApi = DiscoveryManagerHostApi();

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);
  bool _flutterApiSetUp = false;

  void ensureEventHandlersRegistered() {
    if (_flutterApiSetUp) return;
    _flutterApiSetUp = true;
    DiscoveryManagerFlutterApi.setUp(
      _DiscoveryFlutterApiHandler(_onDevicesChangedFromPigeon),
    );
  }

  DiscoveryManagerHostApi get _api {
    ensureEventHandlersRegistered();
    return _hostApi;
  }

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) {
    return _api.isDiscoveryActiveForDeviceCategory(deviceCategory);
  }

  @override
  Future<void> startDiscovery({bool activeScan = false}) async {
    await _api.startDiscovery(activeScan);
  }

  @override
  Future<void> stopDiscovery() async {
    await _api.stopDiscovery();
  }

  void _onDevicesChangedFromPigeon(List<CastDevicePigeon> arguments) {
    try {
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

      if (kDebugMode) {
        print('Received ${devices.length} devices from native');
        for (final device in devices) {
          print(
            'Device: ${device.deviceID} - ${device.friendlyName} (${device.modelName})',
          );
        }
      }

      // Deduplicate by device id only. Keying on name+model would collapse two
      // physically different receivers that share a friendly name.
      final Map<String, GoogleCastDevice> uniqueDevices = {};
      for (final device in devices) {
        final key = device.deviceID;
        if (key.isEmpty) continue;
        if (!uniqueDevices.containsKey(key)) {
          uniqueDevices[key] = device;
          if (kDebugMode) {
            print('Added unique device with key: $key');
          }
        } else {
          if (kDebugMode) {
            print('Skipped duplicate device with key: $key');
          }
        }
      }

      if (kDebugMode) {
        print(
          'Final device count after deduplication: ${uniqueDevices.length}',
        );
      }
      _devicesStreamController.add(uniqueDevices.values.toList());
    } catch (e) {
      rethrow;
    }
  }
}
