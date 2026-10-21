import 'package:flutter_chrome_cast_platform_interface/src/entities/media_information.dart';
import 'package:flutter_chrome_cast_platform_interface/src/entities/media_metadata/media_metadata.dart';
import 'package:flutter_chrome_cast_platform_interface/src/pigeon/remote_media_client_pigeon.g.dart';

/// Converts the app facing [GoogleCastMediaInformation] into the pigeon
/// representation shared with the native platforms.
///
/// The HLS segment format hints travel in dedicated fields (and not inside
/// the `customData` blob) so the native side can apply them to the `MediaInfo`
/// builder without forwarding them to the receiver as custom metadata.
MediaInfo toPigeonMediaInfo(GoogleCastMediaInformation mediaInfo) {
  return MediaInfo(
    contentId: mediaInfo.contentId,
    contentType: mediaInfo.contentType,
    streamType: mediaInfo.streamType.value,
    contentUrl: mediaInfo.contentUrl?.toString() ?? '',
    duration: mediaInfo.duration?.inSeconds ?? 0,
    customData: mediaInfo.customData,
    tracks: mediaInfo.tracks
        ?.map(
          (track) => MediaTrack(
            trackId: track.trackId,
            type: track.type.index,
            trackContentId: track.trackContentId ?? '',
            trackContentType: track.trackContentType,
            subtype: track.subtype?.index ?? 0,
            name: track.name ?? '',
            language: track.language?.toString() ?? '',
          ),
        )
        .toList(),
    metadata: toPigeonMediaMetadata(mediaInfo.metadata),
    hlsSegmentFormat: mediaInfo.hlsSegmentFormat?.name,
    hlsVideoSegmentFormat: mediaInfo.hlsVideoSegmentFormat?.name,
  );
}

/// Converts the app facing [GoogleCastMediaMetadata] into the pigeon
/// representation shared with the native platforms.
///
/// [GoogleCastMediaMetadata] is the base class of the metadata flavors
/// (generic, movie, tv show, music track and photo). Each flavor exposes a
/// different set of fields, so the concrete type is inspected to pick the
/// fields that apply to it.
MediaMetadataPigeon? toPigeonMediaMetadata(GoogleCastMediaMetadata? metadata) {
  if (metadata == null) return null;

  String? title;
  String? subtitle;
  String? studio;
  String? artist;
  String? albumName;
  String? albumArtist;
  String? composer;
  int? trackNumber;
  int? discNumber;
  String? seriesTitle;
  int? season;
  int? episode;
  String? location;
  double? latitude;
  double? longitude;
  int? width;
  int? height;
  String? releaseDate;
  String? originalAirDate;
  String? creationDateTime;

  if (metadata is GoogleCastGenericMediaMetadata) {
    title = metadata.title;
    subtitle = metadata.subtitle;
    releaseDate = _toIso8601(metadata.releaseDate);
  } else if (metadata is GoogleCastMovieMediaMetadata) {
    title = metadata.title;
    subtitle = metadata.subtitle;
    studio = metadata.studio;
    releaseDate = _toIso8601(metadata.releaseDate);
  } else if (metadata is GoogleCastTvShowMediaMetadata) {
    seriesTitle = metadata.seriesTitle;
    season = metadata.season;
    episode = metadata.episode;
    originalAirDate = _toIso8601(metadata.originalAirDate);
  } else if (metadata is GoogleCastMusicMediaMetadata) {
    albumName = metadata.albumName;
    title = metadata.title;
    albumArtist = metadata.albumArtist;
    artist = metadata.artist;
    composer = metadata.composer;
    trackNumber = metadata.trackNumber;
    discNumber = metadata.discNumber;
    releaseDate = _toIso8601(metadata.releaseDate);
  } else if (metadata is GoogleCastPhotoMediaMetadata) {
    title = metadata.title;
    artist = metadata.artist;
    location = metadata.location;
    latitude = metadata.latitude;
    longitude = metadata.longitude;
    width = metadata.width;
    height = metadata.height;
    creationDateTime = _toIso8601(metadata.creationDateTime);
  }

  return MediaMetadataPigeon(
    metadataType: metadata.metadataType.value,
    title: title,
    subtitle: subtitle,
    studio: studio,
    artist: artist,
    albumName: albumName,
    albumArtist: albumArtist,
    composer: composer,
    trackNumber: trackNumber,
    discNumber: discNumber,
    seriesTitle: seriesTitle,
    season: season,
    episode: episode,
    location: location,
    latitude: latitude,
    longitude: longitude,
    width: width,
    height: height,
    releaseDate: releaseDate,
    originalAirDate: originalAirDate,
    creationDateTime: creationDateTime,
    images: metadata.images
        ?.map(
          (image) => MediaImagePigeon(
            url: image.url.toString(),
            width: image.width,
            height: image.height,
          ),
        )
        .toList(),
  );
}

/// Formats a [DateTime] as an ISO-8601 string (in UTC), the representation
/// expected by the native side.
String? _toIso8601(DateTime? date) => date?.toUtc().toIso8601String();
