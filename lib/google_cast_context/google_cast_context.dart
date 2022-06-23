import 'package:google_cast/google_cast_context/google_cast_context_method_channel.dart';
import 'package:google_cast/google_cast_options/cast_options.dart';

class FlutterGoogleCastContext {
  static final _instance = FlutterGoogleCastContext._();

  static FlutterGoogleCastContext get instance => _instance;

  FlutterGoogleCastContext._();

  static Future<bool> setSharedInstanceWithOptions(
      AFlutterGoogleCastOptions option) async {
    return await FlutterIOSGoogleCastContextMethodChannel.instance
        .setSharedInstanceWithOptions(option);
  }
}
