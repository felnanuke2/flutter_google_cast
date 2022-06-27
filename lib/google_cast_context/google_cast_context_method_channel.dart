import 'package:flutter/services.dart';
import 'package:google_cast/discovery_session/ios_discovery_manager.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/entities/request.dart';
import 'package:google_cast/entities/media_information.dart';
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
  final GoogleCastIOSSessionManagerMethodChannel sessionManager =
      GoogleCastIOSSessionManagerMethodChannel.instance;

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
        .map((device) => GoogleCastIosDevice.fromMap(Map.from(device)))
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

  @override
  Future<GoogleCastRequest> loadMedia(GoogleCastMediaInformation mediaInfo,
      {bool autoPlay = true}) {
    // TODO: implement loadMedia
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> play() {
    // TODO: implement play
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs) {
    // TODO: implement setActiveTrackIDs
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setPlaybackRate(double rate) {
    // TODO: implement setPlaybackRate
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setTextTrackStyle(TextTrackStyle textTrackStyle) {
    // TODO: implement setTextTrackStyle
    throw UnimplementedError();
  }

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) {
    // TODO: implement startSessionWithDevice
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }
}
