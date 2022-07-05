import 'package:flutter/services.dart';
import 'package:google_cast/entities/cast_session.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/enums/connection_satate.dart';
import 'package:google_cast/lib.dart';
import 'package:rxdart/subjects.dart';

import '../models/ios/ios_cast_sessions.dart';
import 'cast_session_manager_platform.dart';

class GoogleCastSessionManagerIOSMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  GoogleCastSessionManagerIOSMethodChannel() {
    _channel.setMethodCallHandler(
      (call) => _methodCallHandler(call),
    );
  }

  final _channel = const MethodChannel('google_cast.session_manager');

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    device as GoogleCastIosDevice;
    return await _channel.invokeMethod(
      'startSessionWithDevice',
      device.index,
    );
  }

  @override
  GoogleCastConnectState get connectionState =>
      currentSession?.connectionState ??
      GoogleCastConnectState.ConnectionStateDisconnected;

  @override
  // TODO: implement currentCastSession
  GoogleCastSession? get currentCastSession => throw UnimplementedError();

  @override
  GoogleCastSession? get currentSession =>
      _currentSessionStreamController.value;

  @override
  Future<bool> endSession() async {
    return await _channel.invokeMethod('endSession');
  }

  @override
  Future<bool> endSessionAndStopCasting() async {
    return await _channel.invokeMethod('endSessionAndStopCasting');
  }

  @override
  bool get hasConnectedSession =>
      connectionState == GoogleCastConnectState.ConnectionStateConnected;

  @override
  Future<void> setDefaultSessionOptions() {
    // TODO: implement setDefaultSessionOptions
    throw UnimplementedError();
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

  Future<dynamic> _methodCallHandler(MethodCall call) async {
    switch (call.method) {
      case 'onCurrentSessionChanged':
        return _onCurrentSessionChanged(call.arguments);
    }
  }

  void _onCurrentSessionChanged(arguments) async {
    try {
      final session = IOSGoogleCastSessions.fromMap(
          arguments == null ? null : Map<String, dynamic>.from(arguments));
      _currentSessionStreamController.add(session);
    } catch (e, s) {
      print(e);
      print(s);
    }
  }
}
