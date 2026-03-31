import 'package:flutter_chrome_cast/remote_media_client/remote_media_client_platform.dart';

/// Main entry point for Google Cast remote media client functionality.
///
/// This class provides a platform-agnostic interface for controlling media
/// playback on Google Cast devices. It delegates to the platform-specific
/// implementation registered via
/// [GoogleCastRemoteMediaClientPlatformInterface.instance].
///
/// The correct implementation is registered automatically by Flutter tooling
/// before any application code runs (see `dartPluginClass` in each platform
/// package's pubspec.yaml).
class GoogleCastRemoteMediaClient {
  /// Private constructor to enforce the static-only API.
  GoogleCastRemoteMediaClient._();

  /// Gets the registered platform implementation of the remote media client.
  static GoogleCastRemoteMediaClientPlatformInterface get instance =>
      GoogleCastRemoteMediaClientPlatformInterface.instance;
}
