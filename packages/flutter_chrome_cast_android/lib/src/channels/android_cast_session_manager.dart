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

/// Android-specific implementation of Google Cast session manager functionality.
class GoogleCastSessionManagerAndroidMethodChannel
    extends GoogleCastSessionManagerPlatformInterface {
  /// Creates a new Android session manager method channel.
  ///
  /// The native event handler is registered eagerly: the Cast SDK can
  /// auto-resume a saved session during app startup, BEFORE any session
  /// manager method is called, and a lazily-registered handler would drop
  /// that first `onSessionChanged` event.
  GoogleCastSessionManagerAndroidMethodChannel();

  final SessionManagerHostApi _hostApi = SessionManagerHostApi();
  bool _flutterApiSetUp = false;

  void ensureEventHandlersRegistered() {
    if (_flutterApiSetUp) return;
    _flutterApiSetUp = true;
    SessionManagerFlutterApi.setUp(
      _SessionFlutterApiHandler(_onSessionChanged, _onMessageReceived),
    );
  }

  SessionManagerHostApi get _api {
    ensureEventHandlersRegistered();
    return _hostApi;
  }

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
  GoogleCastConnectState get connectionState =>
      currentSession?.connectionState ?? GoogleCastConnectState.disconnected;

  @override
  GoogleCastSession? get currentSession =>
      _isDisposed ? null : _currentSessionStreamController.value;

  @override
  Stream<GoogleCastSession?> get currentSessionStream =>
      _currentSessionStreamController.stream;

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
    final ok = await _api.endSession();
    await _waitForDisconnect();
    return ok;
  }

  @override
  Future<bool> endSessionAndStopCasting() async {
    final ok = await _api.endSessionAndStopCasting();
    await _waitForDisconnect();
    return ok;
  }

  /// Blocks until the Cast SDK has actually torn the session down.
  ///
  /// The native `endCurrentSession` call returns immediately while the
  /// teardown continues asynchronously; resolving [endSession] before the
  /// session is really gone makes an immediately following
  /// [startSessionWithDevice] race the teardown. The native side additionally
  /// delays reconnects that arrive inside the teardown grace window.
  Future<void> _waitForDisconnect({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (connectionState == GoogleCastConnectState.disconnected) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    // Do not fail endSession because of a slow receiver; the SDK finishes the
    // teardown on its own.
  }

  @override
  bool get hasConnectedSession =>
      connectionState == GoogleCastConnectState.connected;

  @override
  Future<void> setDefaultSessionOptions() {
    throw UnimplementedError(
      'setDefaultSessionOptions is not currently implemented. '
      'This iOS-specific feature is not available on Android.',
    );
  }

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    return _api.startSessionWithDevice(
      StartSessionRequest(deviceId: device.deviceID),
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

  void _onSessionChanged(CastSessionPigeon? arguments) {
    if (_isDisposed) return;
    try {
      if (arguments == null) {
        _currentSessionStreamController.add(null);
        return;
      }
      final session = _PlatformCastSession(
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
        connectionState:
            GoogleCastConnectState.values[arguments.connectionState.index],
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
    // Stale sessions are not observed on Android;
    // delegate to the standard endSessionAndStopCasting
    return endSessionAndStopCasting();
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _messageStreamController.close();
    _currentSessionStreamController.close();
  }
}
