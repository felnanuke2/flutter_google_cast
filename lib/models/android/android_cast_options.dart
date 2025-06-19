import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific cast options configuration.
class GoogleCastOptionsAndroid extends GoogleCastOptions {
  /// The Cast application ID.
  final String appId;

  /// Creates a new [GoogleCastOptionsAndroid].
  GoogleCastOptionsAndroid({
    required this.appId,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
    };
  }
}
