import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';

/// Android-specific cast options configuration.
class GoogleCastOptionsAndroid extends GoogleCastOptions {
  /// Creates a new [GoogleCastOptionsAndroid].
  ///
  /// [appId] is required and specifies the Cast application ID.
  ///
  /// [stopCastingOnAppTerminated] when set to true, will automatically stop
  /// casting and end the session when the app is killed/terminated. Defaults to false.
  GoogleCastOptionsAndroid({
    required String appId,
    super.stopCastingOnAppTerminated,
  }) : super(appId: appId);
}
