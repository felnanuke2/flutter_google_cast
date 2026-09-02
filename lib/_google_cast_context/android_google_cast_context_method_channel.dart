import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/entities/cast_options.dart';
import 'package:flutter_chrome_cast/src/logging/google_cast_logger_configuration.dart';

import 'google_cast_context_platform_interface.dart';

/// Android-specific implementation of Google Cast context functionality.
///
/// This class provides the Android platform implementation for initializing
/// and managing the Google Cast context using method channels.
class GoogleCastContextAndroidMethodChannel
    implements GoogleCastContextPlatformInterface {
  final _channel = const MethodChannel('com.felnanuke.google_cast.context');

  @override
  Future<bool> setSharedInstanceWithOptions(
    GoogleCastOptions castOptions,
  ) async {
    try {
      final arguments = castOptions.toMap();
      GoogleCastLoggerConfiguration.addToChannelArguments(arguments);
      final result = await _channel.invokeMethod(
        'setSharedInstance',
        arguments,
      );
      return result == true;
    } catch (e) {
      rethrow;
    }
  }
}
