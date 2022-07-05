import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_cast/enums/connection_satate.dart';
import 'package:google_cast/entities/cast_session.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/models/android/cast_device.dart';
import 'package:rxdart/subjects.dart';

import 'cast_session_manager_platform.dart';

class GoogleCastSessionManagerAndroidMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  final _channel =
      const MethodChannel('com.felnanuke.google_cast.session_manager');

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  @override
  GoogleCastConnectState get connectionState =>
      _currentSessionStreamController.value?.connectionState ??
      GoogleCastConnectState.ConnectionStateDisconnected;

  @override
  GoogleCastSession? get currentCastSession => throw UnimplementedError();

  @override
  GoogleCastSession? get currentSession => throw UnimplementedError();

  @override
  Future<bool> endSession() {
    // TODO: implement endSession
    throw UnimplementedError();
  }

  @override
  Future<bool> endSessionAndStopCasting() {
    // TODO: implement endSessionAndStopCasting
    throw UnimplementedError();
  }

  @override
  // TODO: implement hasConnectedSession
  bool get hasConnectedSession => throw UnimplementedError();

  @override
  Future<void> setDefaultSessionOptions() {
    // TODO: implement setDefaultSessionOptions
    throw UnimplementedError();
  }

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    device as GoogleCastAndroidDevice;
    return (await _channel.invokeMethod(
          'startSessionWithDeviceId',
          device.deviceID,
        )) ==
        true;
  }

  @override
  Future<bool> startSessionWithOpenURLOptions() {
    // TODO: implement startSessionWithOpenURLOptions
    throw UnimplementedError();
  }

  @override
  Future<bool> suspendSessionWithReason() {
    // TODO: implement suspendSessionWithReason
    throw UnimplementedError();
  }

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;
}
