import 'package:flutter_chrome_cast_platform_interface/src/common/rfc5646_language.dart';
import 'package:flutter_chrome_cast_platform_interface/src/enums/text_track_type.dart';
import 'package:flutter_chrome_cast_platform_interface/src/enums/track_type.dart';

/// Represents a media track, including content type, ID, type, and serialization helpers.
class GoogleCastMediaTrack {
  /// Custom data for the track.
  final Map<String, dynamic>? customData;

  /// Language of the track.
  final Rfc5646Language? language;

  /// Name of the track.
  final String? name;

  /// Subtype of the track.
  final TextTrackType? subtype;

  /// Content ID of the track.
  final String? trackContentId;

  /// Content type of the track.
  final String trackContentType;

  /// Unique identifier of the track within the context of a MediaInfo object.
  final int trackId;

  /// The type of track.
  final TrackType type;

  /// Creates a new [GoogleCastMediaTrack] instance.
  GoogleCastMediaTrack({
    this.customData,
    this.language,
    this.name,
    this.subtype,
    this.trackContentId,
    required this.trackContentType,
    required this.trackId,
    required this.type,
  });
}
