import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/models/ios/ios_cast_device.dart';
import 'package:rxdart/subjects.dart';
import 'discovery_manager_platform_interface.dart';

/// iOS-specific implementation of the Google Cast discovery manager.
/// 
/// This class handles the discovery of Google Cast devices on iOS platform
/// using method channels to communicate with the native iOS implementation.
class GoogleCastDiscoveryManagerMethodChannelIOS
    implements GoogleCastDiscoveryManagerPlatformInterface {
  /// Creates a new instance of the iOS discovery manager.
  /// 
  /// Sets up the method call handler to receive updates from the native side.
  GoogleCastDiscoveryManagerMethodChannelIOS() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  final _channel = const MethodChannel('google_cast.discovery_manager');

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) async {
    return await _channel.invokeMethod('isDiscoveryActiveForDeviceCategory', {
      'deviceCategory': deviceCategory,
    });
  }

  @override
  Future<void> startDiscovery() {
    return _channel.invokeMethod('startDiscovery');
  }

  @override
  Future<void> stopDiscovery() {
    return _channel.invokeMethod('stopDiscovery');
  }

  void _onDevicesChanged(List arguments) {
    final devices = List.from(arguments)
        .map((device) => GoogleCastIosDevice.fromMap(Map.from(device)))
        .toList();

    _devicesStreamController.add(devices);
  }

  Future _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDevicesChanged':
        _onDevicesChanged(call.arguments);
        break;
      default:
        if (kDebugMode) {
          print('No Handler for method ${call.method}');
        }
    }
  }
}
