import 'cast_session_manager_platform.dart';

/// Main entry point for Google Cast session management functionality.
///
/// This class provides a platform-agnostic interface for managing Cast sessions,
/// including starting, ending, and monitoring session state. It delegates to the
/// platform-specific implementation registered via
/// [GoogleCastSessionManagerPlatformInterface.instance].
///
/// The correct implementation is registered automatically by Flutter tooling
/// before any application code runs (see `dartPluginClass` in each platform
/// package's pubspec.yaml).
class GoogleCastSessionManager {
  /// Gets the registered platform implementation of the session manager.
  static GoogleCastSessionManagerPlatformInterface get instance =>
      GoogleCastSessionManagerPlatformInterface.instance;

  GoogleCastSessionManager._();
}
