import 'dart:async';

import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:rxdart/subjects.dart';

class _PlatformCastSession extends GoogleCastSession {
  _PlatformCastSession({
    required super.device,
    required super.sessionID,
    required super.connectionState,
    required super.currentDeviceMuted,
    required super.currentDeviceVolume,
    required super.deviceStatusText,
  });
}

class _SessionFlutterApiHandler extends SessionManagerFlutterApi {
  _SessionFlutterApiHandler(this._onSessionChanged, this._onMessageReceived);

  final void Function(CastSessionPigeon? session) _onSessionChanged;
  final void Function(String namespace, String message) _onMessageReceived;

  @override
  void onSessionChanged(CastSessionPigeon? session) {
    _onSessionChanged(session);
  }

  @override
  void onMessageReceived(String namespace, String message) {
    _onMessageReceived(namespace, message);
  }
}

/// iOS-specific implementation of Google Cast session manager functionality.
class GoogleCastSessionManagerIOSMethodChannel
    extends GoogleCastSessionManagerPlatformInterface {
  /// Creates a new iOS session manager method channel.
  GoogleCastSessionManagerIOSMethodChannel();

  final SessionManagerHostApi _hostApi = SessionManagerHostApi();
  bool _flutterApiSetUp = false;

  void _ensureFlutterApiSetUp() {
    if (_flutterApiSetUp) return;
    _flutterApiSetUp = true;
    SessionManagerFlutterApi.setUp(
      _SessionFlutterApiHandler(_onCurrentSessionChanged, _onMessageReceived),
    );
  }

  SessionManagerHostApi get _api {
    _ensureFlutterApiSetUp();
    return _hostApi;
  }

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
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    return _api.startSessionWithDevice(
      StartSessionRequest(deviceId: device.deviceID),
    );
  }

  @override
  GoogleCastConnectState get connectionState =>
      currentSession?.connectionState ?? GoogleCastConnectState.disconnected;

  @override
  GoogleCastSession? get currentSession =>
      _isDisposed ? null : _currentSessionStreamController.value;

  @override
  Stream<GoogleCastMessage> get messageStream =>
      _messageStreamController.stream;

  @override
  Future<bool> addMessageChannel(String namespace) {
    return _api.addMessageChannel(namespace);
  }

  @override
  Future<bool> removeMessageChannel(String namespace) {
    return _api.removeMessageChannel(namespace);
  }

  @override
  Future<bool> sendMessage(String namespace, String message) {
    return _api.sendMessage(namespace, message);
  }

  @override
  Future<bool> endSession() async {
    return _api.endSession();
  }

  @override
  Future<bool> endSessionAndStopCasting() async {
    return _api.endSessionAndStopCasting();
  }

  @override
  bool get hasConnectedSession =>
      connectionState == GoogleCastConnectState.connected;

  @override
  @Deprecated('This method is not currently implemented.')
  Future<void> setDefaultSessionOptions() {
    throw UnimplementedError(
      'setDefaultSessionOptions is not currently implemented. '
      'This feature requires additional native implementation.',
    );
  }

  @override
  @Deprecated('This method is not currently implemented.')
  Future<bool> startSessionWithOpenURLOptions() {
    throw UnimplementedError(
      'startSessionWithOpenURLOptions is not currently implemented. '
      'This feature requires additional native implementation.',
    );
  }

  @override
  @Deprecated('This method is not currently implemented.')
  Future<bool> suspendSessionWithReason() {
    throw UnimplementedError(
      'suspendSessionWithReason is not currently implemented. '
      'This feature requires additional native implementation.',
    );
  }

  void _onCurrentSessionChanged(CastSessionPigeon? arguments) async {
    if (_isDisposed) return;
    try {
      final session = arguments == null
          ? null
          : _PlatformCastSession(
              device: arguments.device == null
                  ? null
                  : GoogleCastDevice(
                      deviceID: arguments.device!.deviceId,
                      friendlyName: arguments.device!.friendlyName,
                      modelName: arguments.device!.modelName,
                      statusText: arguments.device!.statusText,
                      deviceVersion: arguments.device!.deviceVersion,
                      isOnLocalNetwork: arguments.device!.isOnLocalNetwork,
                      category: arguments.device!.category,
                      uniqueID: arguments.device!.uniqueId,
                    ),
              sessionID: arguments.sessionId,
              connectionState: GoogleCastConnectState
                  .values[arguments.connectionState.index],
              currentDeviceMuted: arguments.currentDeviceMuted,
              currentDeviceVolume: arguments.currentDeviceVolume,
              deviceStatusText: arguments.deviceStatusText,
            );
      _currentSessionStreamController.add(session);
    } catch (e) {
      rethrow;
    }
  }

  void _onMessageReceived(String namespace, String message) {
    if (_isDisposed) return;
    if (_messageStreamController.isClosed) return;
    _messageStreamController.add(
      GoogleCastMessage(namespace: namespace, message: message),
    );
  }

  @override
  void setDeviceVolumeLevel(CastDeviceVolume volume) {
    _api.setDeviceVolume(volume.value, volume.muted);
  }

  @override
  void setDeviceVolume(double value) {
    setDeviceVolumeLevel(CastDeviceVolume(value));
  }

  @override
  Future<bool> resetSession() async {
    return _api.resetSession();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _messageStreamController.close();
    _currentSessionStreamController.close();
  }
}
