import 'package:flutter_chrome_cast/discovery_manager/discovery_manager_platform_interface.dart';

/// Main entry point for Google Cast device discovery functionality.
///
/// This class provides a platform-agnostic interface for discovering Google Cast
/// devices on the network. It delegates to the platform-specific implementation
/// registered via [GoogleCastDiscoveryManagerPlatformInterface.instance].
///
/// The correct implementation is registered automatically by Flutter tooling
/// before any application code runs (see `dartPluginClass` in each platform
/// package's pubspec.yaml).
class GoogleCastDiscoveryManager {
  /// Gets the registered platform implementation of the discovery manager.
  static GoogleCastDiscoveryManagerPlatformInterface get instance =>
      GoogleCastDiscoveryManagerPlatformInterface.instance;

  /// Private constructor to enforce the static-only API.
  GoogleCastDiscoveryManager._();
}
