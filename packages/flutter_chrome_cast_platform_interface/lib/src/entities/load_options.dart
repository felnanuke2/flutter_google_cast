import 'package:flutter_chrome_cast_platform_interface/src/enums/repeat_mode.dart';

/// Configuration options for loading queue items in Google Cast.
class GoogleCastQueueLoadOptions {
  /// Starting index in the queue.
  final int startIndex;

  /// Position to start playback.
  final Duration playPosition;

  /// Repeat mode for the queue.
  final GoogleCastMediaRepeatMode repeatMode;

  /// Custom data to send with the request.
  final Map<String, dynamic>? customData;

  /// Creates a new [GoogleCastQueueLoadOptions].
  GoogleCastQueueLoadOptions({
    this.startIndex = 0,
    this.playPosition = Duration.zero,
    this.repeatMode = GoogleCastMediaRepeatMode.off,
    this.customData,
  });
}
