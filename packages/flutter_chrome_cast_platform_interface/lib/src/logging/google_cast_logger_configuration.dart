import 'cast_log_level.dart';

/// Holds the log level configured by the application.
///
/// The level is shared across the whole plugin: the app-facing package sets
/// it through `GoogleCastLogger.level`, and the platform packages read it
/// while initializing the native Cast context so native logging is filtered
/// from the very first log statement.
class GoogleCastLoggerConfiguration {
  GoogleCastLoggerConfiguration._();

  /// The configured level, or `null` when the application did not opt in.
  ///
  /// A `null` level intentionally means that the application has not opted in
  /// to log filtering. Native implementations use that distinction to retain
  /// their legacy logging behavior exactly.
  static CastLogLevel? level;

  /// The wire value used to carry the level to the native platforms.
  static String? get wireValue => level?.name;
}
