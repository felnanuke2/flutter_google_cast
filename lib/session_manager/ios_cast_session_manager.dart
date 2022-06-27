import 'package:flutter/services.dart';
import 'package:google_cast/entities/cast_session.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/enums/connection_satate.dart';
import 'package:google_cast/session_manager/cast_session_manager.dart';
import 'package:rxdart/subjects.dart';

import '../models/ios/ios_cast_sessions.dart';

class GoogleCastIOSSessionManagerMethodChannel
    implements AGoogleCastSessionManagerPlatformInterface {
  GoogleCastIOSSessionManagerMethodChannel._() {
    _channel.setMethodCallHandler(
      (call) => _methodCallHandler(call),
    );
  }

  static final GoogleCastIOSSessionManagerMethodChannel _instance =
      GoogleCastIOSSessionManagerMethodChannel._();

  static GoogleCastIOSSessionManagerMethodChannel get instance => _instance;

  final _channel = const MethodChannel('google_cast.session_manager');

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
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
  Future<bool> endSession() {
    // TODO: implement endSession
    throw UnimplementedError();
  }

  @override
  Future<bool> endSessionAndStopCasting(bool stopCasting) {
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
    final session =
        IOSGoogleCastSessions.fromMap(Map<String, dynamic>.from(arguments));
    print(session);
    _currentSessionStreamController.add(session);
  }
}
