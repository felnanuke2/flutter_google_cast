import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_cast/entities/cast_options.dart';

import 'google_cast_context_plataform_interface.dart';

class GoogleCastContextAndroidMethodChannel
    implements GoogleCastContextPlatformInterface {
  final _channel = const MethodChannel('com.felnanuke.google_cast.context');

  @override
  Future<bool> setSharedInstanceWithOptions(
      GoogleCastOptions castOptions) async {
    final result =
        await _channel.invokeMethod('setSharedInstance', castOptions.toMap());
    if (result && kDebugMode) {
      // ignore: avoid_print
      print('setSharedInstanceWithOptions initialized');
    }

    return result;
  }
}
