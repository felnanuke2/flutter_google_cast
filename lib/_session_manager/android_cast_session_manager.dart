import 'package:google_cast/enums/connection_satate.dart';
import 'package:google_cast/entities/cast_session.dart';
import 'package:google_cast/entities/cast_device.dart';

import 'cast_session_manager_platform.dart';

class GoogleCastSessionManagerAndroidMethodChannel
    implements GoogleCastSessionManagerPlatformInterface {
  @override
  // TODO: implement connectionState
  GoogleCastConnectState get connectionState => throw UnimplementedError();

  @override
  // TODO: implement currentCastSession
  GoogleCastSession? get currentCastSession => throw UnimplementedError();

  @override
  // TODO: implement currentSession
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
  Future<bool> startSessionWithDevice(GoogleCastDevice device) {
    // TODO: implement startSessionWithDevice
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

  @override
  // TODO: implement currentSessionStream
  Stream<GoogleCastSession?> get currentSessionStream =>
      throw UnimplementedError();
}
