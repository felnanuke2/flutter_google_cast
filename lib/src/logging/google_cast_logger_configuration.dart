// ignore_for_file: public_member_api_docs

import 'package:flutter/foundation.dart';

import 'cast_log_level.dart';

/// Internal logging state shared by the public API and method-channel code.
///
/// A `null` level intentionally means that the application has not opted in to
/// log filtering. Native implementations use that distinction to retain their
/// legacy logging behavior exactly.
class GoogleCastLoggerConfiguration {
  GoogleCastLoggerConfiguration._();

  static const channelArgumentKey = 'logLevel';

  static CastLogLevel? level;

  static void addToChannelArguments(Map<String, dynamic> arguments) {
    final configuredLevel = level;
    if (configuredLevel != null) {
      arguments[channelArgumentKey] = configuredLevel.name;
    }
  }

  @visibleForTesting
  static void reset() {
    level = null;
  }

  static bool allows(CastLogLevel messageLevel) {
    final configuredLevel = level;
    if (configuredLevel == null) {
      return true;
    }

    switch (configuredLevel) {
      case CastLogLevel.none:
        return false;
      case CastLogLevel.error:
        return messageLevel == CastLogLevel.error;
      case CastLogLevel.warning:
        return messageLevel == CastLogLevel.error ||
            messageLevel == CastLogLevel.warning;
      case CastLogLevel.info:
        return messageLevel != CastLogLevel.verbose &&
            messageLevel != CastLogLevel.none;
      case CastLogLevel.verbose:
        return messageLevel != CastLogLevel.none;
    }
  }
}

/// Internal output facade used instead of direct `print`/`debugPrint` calls.
class GoogleCastLog {
  GoogleCastLog._();

  static void error(String Function() message) {
    _write(CastLogLevel.error, message);
  }

  static void warning(String Function() message) {
    _write(CastLogLevel.warning, message);
  }

  static void info(String Function() message) {
    _write(CastLogLevel.info, message);
  }

  static void verbose(String Function() message) {
    _write(CastLogLevel.verbose, message);
  }

  static void _write(CastLogLevel messageLevel, String Function() message) {
    if (GoogleCastLoggerConfiguration.allows(messageLevel)) {
      debugPrint(message());
    }
  }
}
