import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';
import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/entities/cast_message.dart';
import 'package:flutter_chrome_cast/models/android/cast_device.dart';
import 'package:flutter_chrome_cast/models/android/cast_session.dart';
import 'package:rxdart/subjects.dart';

import 'cast_session_manager_platform.dart';

/// Android-specific implementation of Google Cast session manager functionality.
class GoogleCastSessionManagerAndroidMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  /// Creates a new Android session manager method channel.
  GoogleCastSessionManagerAndroidMethodChannel() {
    _channel.setMethodCallHandler(_onMethodCallHandler);
  }
  final _channel =
      const MethodChannel('com.felnanuke.google_cast.session_manager');

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  final _messageStreamController =
      StreamController<GoogleCastMessage>.broadcast();

  @override
  GoogleCastConnectState get connectionState =>
      _currentSessionStreamController.value?.connectionState ??
      GoogleCastConnectState.disconnected;

  @override
  GoogleCastSession? get currentSession =>
      _currentSessionStreamController.value;

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

  @override
  Stream<GoogleCastMessage> get messageStream =>
      _messageStreamController.stream;

  @override
  Future<bool> addMessageChannel(String namespace) async {
    return await _channel.invokeMethod<bool>(
          'addMessageChannel',
          <String, dynamic>{'namespace': namespace},
        ) ??
        false;
  }

  @override
  Future<bool> removeMessageChannel(String namespace) async {
    return await _channel.invokeMethod<bool>(
          'removeMessageChannel',
          <String, dynamic>{'namespace': namespace},
        ) ??
        false;
  }

  @override
  Future<bool> sendMessage(String namespace, String message) async {
    return await _channel.invokeMethod<bool>(
          'sendMessage',
          <String, dynamic>{
            'namespace': namespace,
            'message': message,
          },
        ) ??
        false;
  }

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
      _currentSessionStreamController.value?.connectionState ==
      GoogleCastConnectState.connected;

  @override
  Future<void> setDefaultSessionOptions() {
    throw UnimplementedError('Only works in IOS');
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

  Future _onMethodCallHandler(MethodCall call) async {
    switch (call.method) {
      case "onSessionChanged":
        _onSessionChanged(call.arguments);
        return;
      case 'onMessageReceived':
        _onMessageReceived(call.arguments);
        return;
      default:
    }
  }

  void _onMessageReceived(dynamic arguments) {
    if (arguments is! Map) return;
    final map = Map<String, dynamic>.from(arguments);
    final namespace = map['namespace'];
    final message = map['message'];
    if (namespace is String && message is String) {
      _messageStreamController.add(
        GoogleCastMessage(namespace: namespace, message: message),
      );
    }
  }

  void _onSessionChanged(dynamic arguments) {
    try {
      if (arguments == null) {
        _currentSessionStreamController.add(null);
        return;
      }
      final map = Map<String, dynamic>.from(arguments);
      final session = GoogleCastSessionAndroid.fromMap(map);
      _currentSessionStreamController.add(session);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void setDeviceVolume(double value) {
    _channel.invokeMethod('setStreamVolume', value);
  }

  @override
  Future<bool> resetSession() async {
    // Stale sessions are not observed on Android;
    // delegate to the standard endSessionAndStopCasting
    return endSessionAndStopCasting();
  }
}
