// Mock implementations of platform interfaces for use in federated plugin tests.
//
// In the federated plugin architecture, each platform interface has a static
// `instance` that the app-facing facade delegates to. Tests inject these mock
// implementations to verify that the facade correctly delegates to the platform
// interface without relying on real method channels or platform detection.

import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context_platform_interface.dart';
import 'package:flutter_chrome_cast/_discovery_manager/discovery_manager_platform_interface.dart';
import 'package:flutter_chrome_cast/_remote_media_client/remote_media_client_platform.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';
import 'package:flutter_chrome_cast/entities/cast_device.dart';
import 'package:flutter_chrome_cast/entities/cast_media_status.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'package:flutter_chrome_cast/entities/cast_session.dart';
import 'package:flutter_chrome_cast/entities/load_options.dart';
import 'package:flutter_chrome_cast/entities/media_information.dart';
import 'package:flutter_chrome_cast/entities/media_seek_option.dart';
import 'package:flutter_chrome_cast/entities/queue_item.dart';
import 'package:flutter_chrome_cast/enums/connection_state.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:rxdart/subjects.dart';

// ---------------------------------------------------------------------------
// MockGoogleCastContextPlatformInterface
// ---------------------------------------------------------------------------

/// A test-only mock for [GoogleCastContextPlatformInterface].
///
/// Records every call made to [setSharedInstanceWithOptions] so that tests can
/// verify the correct arguments are passed through the facade.
class MockGoogleCastContextPlatformInterface
    extends PlatformInterface
    implements GoogleCastContextPlatformInterface {
  static final Object _token = Object();

  MockGoogleCastContextPlatformInterface() : super(token: _token);

  bool returnValue = true;

  GoogleCastOptions? lastOptions;
  int callCount = 0;

  @override
  Future<bool> setSharedInstanceWithOptions(
      GoogleCastOptions castOptions) async {
    callCount++;
    lastOptions = castOptions;
    return returnValue;
  }
}

// ---------------------------------------------------------------------------
// MockGoogleCastDiscoveryManagerPlatformInterface
// ---------------------------------------------------------------------------

/// A test-only mock for [GoogleCastDiscoveryManagerPlatformInterface].
///
/// Allows tests to inject devices and verify method calls without a real
/// native platform or method channel.
class MockGoogleCastDiscoveryManagerPlatformInterface
    implements GoogleCastDiscoveryManagerPlatformInterface {
  final _devicesSubject = BehaviorSubject<List<GoogleCastDevice>>()..add([]);

  bool startDiscoveryCalled = false;
  bool stopDiscoveryCalled = false;
  String? lastDeviceCategory;

  bool isDiscoveryActiveReturnValue = false;

  /// Pushes a new device list into the devices stream.
  void emitDevices(List<GoogleCastDevice> devices) {
    _devicesSubject.add(devices);
  }

  @override
  List<GoogleCastDevice> get devices => _devicesSubject.value;

  @override
  Stream<List<GoogleCastDevice>> get devicesStream => _devicesSubject.stream;

  @override
  Future<void> startDiscovery() async {
    startDiscoveryCalled = true;
  }

  @override
  Future<void> stopDiscovery() async {
    stopDiscoveryCalled = true;
  }

  @override
  Future<bool> isDiscoveryActiveForDeviceCategory(
      String deviceCategory) async {
    lastDeviceCategory = deviceCategory;
    return isDiscoveryActiveReturnValue;
  }
}

// ---------------------------------------------------------------------------
// MockGoogleCastRemoteMediaClientPlatformInterface
// ---------------------------------------------------------------------------

/// A test-only mock for [GoogleCastRemoteMediaClientPlatformInterface].
///
/// Records method calls and allows tests to control the values exposed through
/// the streams without requiring a real method channel.
class MockGoogleCastRemoteMediaClientPlatformInterface
    implements GoogleCastRemoteMediaClientPlatformInterface {
  final _mediaStatusSubject = BehaviorSubject<GoggleCastMediaStatus?>()
    ..add(null);
  final _playerPositionSubject = BehaviorSubject<Duration>()
    ..add(Duration.zero);
  final _queueItemsSubject = BehaviorSubject<List<GoogleCastQueueItem>>()
    ..add([]);

  // Recorded calls
  GoogleCastMediaInformation? lastLoadedMedia;
  GoogleCastMediaSeekOption? lastSeekOption;
  double? lastPlaybackRate;
  List<int>? lastActiveTrackIds;
  int loadCallCount = 0;
  int pauseCallCount = 0;
  int playCallCount = 0;
  int stopCallCount = 0;

  @override
  GoggleCastMediaStatus? get mediaStatus => _mediaStatusSubject.value;

  @override
  Stream<GoggleCastMediaStatus?> get mediaStatusStream =>
      _mediaStatusSubject.stream;

  @override
  Duration get playerPosition => _playerPositionSubject.value;

  @override
  Stream<Duration> get playerPositionStream => _playerPositionSubject.stream;

  @override
  List<GoogleCastQueueItem> get queueItems => _queueItemsSubject.value;

  @override
  Stream<List<GoogleCastQueueItem>> get queueItemsStream =>
      _queueItemsSubject.stream;

  @override
  bool get queueHasNextItem => false;

  @override
  bool get queueHasPreviousItem => false;

  @override
  Future<void> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
    Map<String, dynamic>? customData,
  }) async {
    loadCallCount++;
    lastLoadedMedia = mediaInfo;
    lastPlaybackRate = playbackRate;
    lastActiveTrackIds = activeTrackIds;
  }

  @override
  Future<void> pause() async => pauseCallCount++;

  @override
  Future<void> play() async => playCallCount++;

  @override
  Future<void> stop() async => stopCallCount++;

  @override
  Future<void> seek(GoogleCastMediaSeekOption option) async {
    lastSeekOption = option;
  }

  @override
  Future<void> queueLoadItems(
    List<GoogleCastQueueItem> queueItems, {
    GoogleCastQueueLoadOptions? options,
  }) async {}

  @override
  Future<void> setPlaybackRate(double rate) async => lastPlaybackRate = rate;

  @override
  Future<void> setActiveTrackIDs(List<int> activeTrackIDs) async =>
      lastActiveTrackIds = activeTrackIDs;

  @override
  Future<void> setTextTrackStyle(TextTrackStyle textTrackStyle) async {}

  @override
  Future<void> queueNextItem() async {}

  @override
  Future<void> queuePrevItem() async {}

  @override
  Future<void> queueInsertItems(
    List<GoogleCastQueueItem> items, {
    int? beforeItemWithId,
  }) async {}

  @override
  Future<void> queueInsertItemAndPlay(
    GoogleCastQueueItem item, {
    required int beforeItemWithId,
  }) async {}

  @override
  Future<void> queueRemoveItemsWithIds(List<int> itemIds) async {}

  @override
  Future<void> queueJumpToItemWithId(int itemId) async {}

  @override
  Future<void> queueReorderItems({
    required List<int> itemsIds,
    required int? beforeItemWithId,
  }) async {}
}

// ---------------------------------------------------------------------------
// MockGoogleCastSessionManagerPlatformInterface
// ---------------------------------------------------------------------------

/// A test-only mock for [GoogleCastSessionManagerPlatformInterface].
///
/// Allows tests to simulate session lifecycle events without native code.
class MockGoogleCastSessionManagerPlatformInterface
    extends PlatformInterface
    implements GoogleCastSessionManagerPlatformInterface {
  static final Object _token = Object();

  MockGoogleCastSessionManagerPlatformInterface() : super(token: _token);

  final _sessionSubject = BehaviorSubject<GoogleCastSession?>()..add(null);

  GoogleCastDevice? lastStartedDevice;
  bool endSessionCalled = false;
  bool hasConnectedSessionValue = false;
  GoogleCastConnectState connectionStateValue =
      GoogleCastConnectState.disconnected;

  @override
  bool get hasConnectedSession => hasConnectedSessionValue;

  @override
  GoogleCastSession? get currentSession => _sessionSubject.value;

  @override
  Stream<GoogleCastSession?> get currentSessionStream => _sessionSubject.stream;

  @override
  GoogleCastConnectState get connectionState => connectionStateValue;

  @override
  Future<bool> startSessionWithDevice(GoogleCastDevice device) async {
    lastStartedDevice = device;
    return true;
  }

  @override
  Future<bool> startSessionWithOpenURLOptions() async => false;

  @override
  Future<bool> suspendSessionWithReason() async => false;

  @override
  Future<bool> endSession() async {
    endSessionCalled = true;
    _sessionSubject.add(null);
    return true;
  }

  @override
  Future<bool> endSessionAndStopCasting() async => true;

  @override
  Future<void> setDefaultSessionOptions() async {}

  @override
  void setDeviceVolume(double value) {}
}
