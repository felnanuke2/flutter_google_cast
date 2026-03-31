import 'package:flutter_chrome_cast/google_cast_context/google_cast_context_platform_interface.dart';

/// Main entry point for Google Cast context functionality.
///
/// This class provides a platform-agnostic interface for initializing and
/// managing the Google Cast context. It delegates to the platform-specific
/// implementation registered via [GoogleCastContextPlatformInterface.instance].
///
/// The correct implementation is registered automatically by Flutter tooling
/// before any application code runs (see `dartPluginClass` in each platform
/// package's pubspec.yaml).
class GoogleCastContext {
  /// Gets the registered platform implementation of the Google Cast context.
  static GoogleCastContextPlatformInterface get instance =>
      GoogleCastContextPlatformInterface.instance;

  /// Private constructor to enforce the static-only API.
  GoogleCastContext._();
}
