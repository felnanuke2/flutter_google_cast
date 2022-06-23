import 'package:flutter/services.dart';
import 'package:google_cast/discovery_session/ios_discovery_manager.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/google_cast_context/google_cast_context_plataform_interface.dart';
import 'package:google_cast/google_cast_options/cast_options.dart';
import 'package:google_cast/session_manager/ios_cast_session_manager.dart';
import 'package:rxdart/rxdart.dart';

import '../models/ios/ios_cast_device.dart';

class FlutterIOSGoogleCastContextMethodChannel
    extends AGoogleCastContextPlatformInterface {
  static final _instance = FlutterIOSGoogleCastContextMethodChannel._();

  static const _methodChannel = MethodChannel('google_cast.context');

  @override
  final GoogleCastIOSDiscoveryManager discoveryManager =
      GoogleCastIOSDiscoveryManager();

  @override
  GoogleCastIOSSessionManager get sessionManager =>
      GoogleCastIOSSessionManager.instance;

  FlutterIOSGoogleCastContextMethodChannel._() {
    _methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  static FlutterIOSGoogleCastContextMethodChannel get instance => _instance;

  final _devicesStreamController = BehaviorSubject<List<GoogleCastDevice>>();

  Stream<List<GoogleCastDevice>> get devicesStream =>
      _devicesStreamController.stream;

  List<GoogleCastDevice> get devices => _devicesStreamController.value;

  int get devicesCount => _devicesStreamController.value.length;

  @override
  Future<bool> setSharedInstanceWithOptions(
      AFlutterGoogleCastOptions castOptions) async {
    return await _methodChannel.invokeMethod(
      'setSharedInstanceWithOptions',
      castOptions.toMap(),
    );
  }

  void _onDevicesChanged(List arguments) {
    final devices = List.from(arguments)
        .map((device) => IosCastDevice.fromMap(Map.from(device)))
        .toList();

    _devicesStreamController.add(devices);
    print(devicesCount);
  }

  Future _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDevicesChanged':
        _onDevicesChanged(call.arguments);
        break;
      default:
        print('No Handler for method ${call.method}');
    }
  }
}
