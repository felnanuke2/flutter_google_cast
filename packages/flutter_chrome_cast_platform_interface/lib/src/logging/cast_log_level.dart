/// Log levels supported by `GoogleCastLogger`.
enum CastLogLevel {
  /// Disables all logs emitted by the plugin and, where supported, the Cast SDK.
  none,

  /// Emits error messages only.
  error,

  /// Emits warning and error messages.
  warning,

  /// Emits informational, warning, and error messages.
  info,

  /// Emits every available log message.
  verbose,
}
