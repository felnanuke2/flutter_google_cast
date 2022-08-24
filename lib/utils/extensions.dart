import 'package:google_cast/lib.dart';

extension GoogleCastMediaMetadataExtensions on GoogleCastMediaMetadata {
  String? get extractedTitle {
    final type = metadataType;
    String? title;
    final metadata = this;

    switch (type) {
      case GoogleCastMediaMetadataType.tvShowMediaMetadata:
        metadata as GoogleCastTvShowMediaMetadata;
        title = metadata.seriesTitle;
        break;
      case GoogleCastMediaMetadataType.genericMediaMetadata:
        metadata as GoogleCastGenericMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.movieMediaMetadata:
        metadata as GoogleCastMovieMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.musicTrackMediaMetadata:
        metadata as GoogleCastMusicMediaMetadata;
        title = metadata.title;
        break;
      case GoogleCastMediaMetadataType.photoMediaMetadata:
        metadata as GoogleCastPhotoMediaMetadata;
        title = metadata.title;
        break;
      default:
    }
    return title;
  }
}
