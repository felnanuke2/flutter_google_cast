import 'package:flutter/foundation.dart';
import 'package:flutter_chrome_cast/logging.dart';
import 'package:flutter_chrome_cast/src/logging/google_cast_logger_configuration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCastLogger', () {
    late DebugPrintCallback originalDebugPrint;
    late List<String?> messages;

    setUp(() {
      originalDebugPrint = debugPrint;
      messages = <String?>[];
      debugPrint = (String? message, {int? wrapWidth}) {
        messages.add(message);
      };
      GoogleCastLoggerConfiguration.reset();
    });

    tearDown(() {
      debugPrint = originalDebugPrint;
      GoogleCastLoggerConfiguration.reset();
    });

    test('does not opt in when the effective default level is read', () {
      expect(GoogleCastLogger.level, CastLogLevel.verbose);
      expect(GoogleCastLoggerConfiguration.level, isNull);

      GoogleCastLog.verbose(() => 'legacy verbose');

      expect(messages, <String?>['legacy verbose']);
    });

    test('none suppresses every plugin log level', () {
      GoogleCastLogger.level = CastLogLevel.none;

      GoogleCastLog.error(() => 'error');
      GoogleCastLog.warning(() => 'warning');
      GoogleCastLog.info(() => 'info');
      GoogleCastLog.verbose(() => 'verbose');

      expect(messages, isEmpty);
    });

    test('error emits errors only', () {
      GoogleCastLogger.level = CastLogLevel.error;

      GoogleCastLog.error(() => 'error');
      GoogleCastLog.warning(() => 'warning');
      GoogleCastLog.info(() => 'info');
      GoogleCastLog.verbose(() => 'verbose');

      expect(messages, <String?>['error']);
    });

    test('warning emits warnings and errors', () {
      GoogleCastLogger.level = CastLogLevel.warning;

      GoogleCastLog.error(() => 'error');
      GoogleCastLog.warning(() => 'warning');
      GoogleCastLog.info(() => 'info');
      GoogleCastLog.verbose(() => 'verbose');

      expect(messages, <String?>['error', 'warning']);
    });

    test('info suppresses verbose messages only', () {
      GoogleCastLogger.level = CastLogLevel.info;

      GoogleCastLog.error(() => 'error');
      GoogleCastLog.warning(() => 'warning');
      GoogleCastLog.info(() => 'info');
      GoogleCastLog.verbose(() => 'verbose');

      expect(messages, <String?>['error', 'warning', 'info']);
    });

    test('verbose emits every plugin log level', () {
      GoogleCastLogger.level = CastLogLevel.verbose;

      GoogleCastLog.error(() => 'error');
      GoogleCastLog.warning(() => 'warning');
      GoogleCastLog.info(() => 'info');
      GoogleCastLog.verbose(() => 'verbose');

      expect(messages, <String?>['error', 'warning', 'info', 'verbose']);
    });

    test('does not evaluate a suppressed message', () {
      var evaluated = false;
      GoogleCastLogger.level = CastLogLevel.none;

      GoogleCastLog.verbose(() {
        evaluated = true;
        return 'verbose';
      });

      expect(evaluated, isFalse);
    });
  });
}
