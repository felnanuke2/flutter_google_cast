///Represents a break (e.g. ad break)
///included in the main video.
class CastBreak {
  ///List of break clip IDs included in this break.

  final List<String> breakClipIds;

  ///Duration of break in seconds.
  final Duration? duration;

  ///Unique ID of a break.
  final String id;

  /// Indicates whether the break is embedded in the main stream.

  final bool isEmbedded;

  /// Whether a break was watched. This is marked as
  ///  true when the break begins to play.
  /// A sender can change color of a progress
  ///  bar marker corresponding to this break
  /// once this field changes from false to
  /// true denoting that the end-user
  /// already watched this break.

  final bool isWatched;

  ///Location of the break inside the main video. -1 represents the end of the main video in seconds.

  final int position;

  /// Creates a new [CastBreak] instance.
  CastBreak({
    required this.breakClipIds,
    this.duration,
    required this.id,
    required this.isEmbedded,
    required this.isWatched,
    required this.position,
  });
}
