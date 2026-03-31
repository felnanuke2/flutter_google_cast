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
  _SessionFlutterApiHandler(this._onSessionChanged);

  final void Function(CastSessionPigeon? session) _onSessionChanged;

  @override
  void onSessionChanged(CastSessionPigeon? session) {
    _onSessionChanged(session);
  }
}

/// Android-specific implementation of Google Cast session manager functionality.
class GoogleCastSessionManagerAndroidMethodChannel
    extends GoogleCastSessionManagerPlatformInterface {
  /// Creates a new Android session manager method channel.
  GoogleCastSessionManagerAndroidMethodChannel() {
    SessionManagerFlutterApi.setUp(
      _SessionFlutterApiHandler(_onSessionChanged),
    );
  }
  final _hostApi = SessionManagerHostApi();

  final _currentSessionStreamController = BehaviorSubject<GoogleCastSession?>()
    ..add(null);

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
  Future<bool> endSession() async {
    return _hostApi.endSession();
  }

  @override
  Future<bool> endSessionAndStopCasting() async {
    return _hostApi.endSessionAndStopCasting();
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
    return _hostApi.startSessionWithDevice(
      StartSessionRequest(deviceId: device.deviceID),
    );
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

  void _onSessionChanged(CastSessionPigeon? arguments) {
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

  @override
  void setDeviceVolumeLevel(CastDeviceVolume volume) {
    _hostApi.setDeviceVolume(volume.value);
  }

  @override
  void setDeviceVolume(double value) {
    setDeviceVolumeLevel(CastDeviceVolume(value));
  }
}
