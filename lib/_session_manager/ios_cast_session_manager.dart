import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:rxdart/subjects.dart';

/// iOS-specific implementation of Google Cast session manager functionality.
class GoogleCastSessionManagerIOSMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  /// Creates a new iOS session manager method channel.
  GoogleCastSessionManagerIOSMethodChannel() {
    _channel.setMethodCallHandler((call) => _methodCallHandler(call));
  }

  final _channel = const MethodChannel('google_cast.session_manager');

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

  final _messageStreamController =
      StreamController<GoogleCastMessage>.broadcast();

  /// Whether [dispose] has already been called on this instance.
  ///
  /// Once disposed, getters no longer surface the last cached session
  /// (rxdart's [BehaviorSubject] retains its value after being closed).
  bool _isDisposed = false;

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
    return await _channel.invokeMethod<bool>('sendMessage', <String, dynamic>{
          'namespace': namespace,
          'message': message,
        }) ??
        false;
  }

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    device as GoogleCastIosDevice;
    return await _channel.invokeMethod('startSessionWithDevice', device.index);
  }

  @override
  GoogleCastConnectState get connectionState =>
      currentSession?.connectionState ?? GoogleCastConnectState.disconnected;

  /// Returns the current cast session if available.
  ///
  /// This method is not implemented for iOS and will throw an [UnimplementedError].
  /// Use [currentSession] instead which is properly implemented for iOS.
  GoogleCastSession? get currentCastSession => throw UnimplementedError();

  @override
  GoogleCastSession? get currentSession =>
      _isDisposed ? null : _currentSessionStreamController.value;

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
      connectionState == GoogleCastConnectState.connected;

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
      case 'onMessageReceived':
        return _onMessageReceived(call.arguments);
    }
  }

  void _onMessageReceived(dynamic arguments) {
    if (_messageStreamController.isClosed) return;
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

  void _onCurrentSessionChanged(dynamic arguments) async {
    if (_currentSessionStreamController.isClosed) return;
    try {
      final session = IOSGoogleCastSessions.fromMap(
        arguments == null ? null : Map<String, dynamic>.from(arguments),
      );
      _currentSessionStreamController.add(session);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void setDeviceVolume(double value) {
    _channel.invokeMethod('setDeviceVolume', value);
  }

  @override
  Future<bool> resetSession() async {
    return await _channel.invokeMethod('resetSession');
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _channel.setMethodCallHandler(null);
    _messageStreamController.close();
    _currentSessionStreamController.close();
  }
}
