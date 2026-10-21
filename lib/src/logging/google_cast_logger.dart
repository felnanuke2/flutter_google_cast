import 'cast_log_level.dart';
import 'google_cast_logger_configuration.dart';

/// Controls log output produced by this plugin and the native Cast SDK.
///
/// Logging remains unchanged until [level] is explicitly assigned. Set the
/// level before calling
/// `GoogleCastContext.instance.setSharedInstanceWithOptions(...)` so the
/// native logger is configured before the Cast context is initialized.
///
/// On iOS, the selected level also configures `GCKLogger`. The Android Cast
/// Application Framework does not expose a public SDK logger API, so Android
/// filtering applies to Dart and native logs owned by this plugin.
class GoogleCastLogger {
  GoogleCastLogger._();

  /// The effective log level.
  ///
  /// This returns [CastLogLevel.verbose] before an application opts in, which
  /// reflects the plugin's legacy behavior. Reading this property does not
  /// activate filtering.
  static CastLogLevel get level =>
      GoogleCastLoggerConfiguration.level ?? CastLogLevel.verbose;

  /// Opts in to plugin log filtering at [value].
  ///
  /// Assign this before initializing `GoogleCastContext`. Native filtering is
  /// applied as part of context initialization, while Dart filtering takes
  /// effect immediately.
  static set level(CastLogLevel value) {
    GoogleCastLoggerConfiguration.level = value;
  }
}
