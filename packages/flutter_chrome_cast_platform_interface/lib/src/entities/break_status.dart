/// Represents current status of a break, including IDs and timing information.
class GoogleCastBrakeStatus {
  /// ID of the current break clip.
  final String? breakClipId;

  /// ID of the current break.
  final String? breakId;

  /// Time in seconds elapsed after the current break clip starts.
  /// This member is only updated sporadically, so its value is often out of date.
  /// Use the getEstimatedBreakClipTime method to get an estimate of the real playback position.
  final Duration? currentBreakClipTime;

  /// Time in seconds elapsed after the current break starts.
  /// This member is only updated sporadically, so its value is often out of date.
  /// Use the getEstimatedBreakTime method to get an estimate of the real playback position.
  final Duration? currentBreakTime;

  /// The time in seconds when this break clip becomes skippable.
  /// If not defined, the current break clip is not skippable.
  final Duration? whenSkippable;

  /// Creates a new [GoogleCastBrakeStatus] instance.
  GoogleCastBrakeStatus({
    this.breakClipId,
    this.breakId,
    this.currentBreakClipTime,
    this.currentBreakTime,
    this.whenSkippable,
  });
}
