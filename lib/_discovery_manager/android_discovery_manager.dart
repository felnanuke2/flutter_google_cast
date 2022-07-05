import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/models/android/cast_device.dart';
import 'package:rxdart/subjects.dart';

class GoogleCastDiscoveryManagerMethodChannelAndroid
    implements GoogleCastDiscoveryManagerPlatformInterface {
  GoogleCastDiscoveryManagerMethodChannelAndroid() {
    _channel.setMethodCallHandler(_onMethodCallHandler);
  }

  final _channel =
      const MethodChannel('com.felnanuke.google_cast.discovery_manager');

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>()
    ..add([]);

  @override
  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(String deviceCategory) {
    // TODO: implement isDiscoveryActiveForDeviceCategory
    throw UnimplementedError();
  }

  @override
  Future<void> startDiscovery() {
    // TODO: implement startDiscovery
    throw UnimplementedError();
  }

  @override
  Future<void> stopDiscovery() {
    // TODO: implement stopDiscovery
    throw UnimplementedError();
  }

  Future _onMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onDevicesChanged':
        return _onDevicesChanged(call.arguments);

      default:
    }
  }

  _onDevicesChanged(arguments) {
    arguments as String;
    final list = jsonDecode(arguments);
    final listMap = List.from(list);
    final devices = listMap
        .map(
          (e) => GoogleCastAndroidDevice.fromMap(e),
        )
        .toList();
    _devicesStreamController.add(devices);
  }
}
