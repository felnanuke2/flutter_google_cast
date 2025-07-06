import 'package:flutter_chrome_cast/lib.dart';

/// Android-specific extension for repeat mode.
extension GoogleCastRepeatModeAndroid on GoogleCastMediaRepeatMode {
  /// Creates a repeat mode from a map value.
  static GoogleCastMediaRepeatMode fromMap(String value) {
    return GoogleCastMediaRepeatMode.values.firstWhere(
      (element) => element.name.toUpperCase() == value.toUpperCase(),
      orElse: () => GoogleCastMediaRepeatMode.unchanged,
    );
  }

  int get androidValue {
    /// Reference:
    /// https://developers.google.com/android/reference/com/google/android/gms/cast/MediaStatus#public-static-final-int-repeat_mode_repeat_all
    switch (this) {
      case GoogleCastMediaRepeatMode.unchanged:
        return -1;
      case GoogleCastMediaRepeatMode.off:
        return 0;
      case GoogleCastMediaRepeatMode.single:
        return 2;
      case GoogleCastMediaRepeatMode.all:
        return 1;
      case GoogleCastMediaRepeatMode.allAndShuffle:
        return 3;
    }
  }
}
