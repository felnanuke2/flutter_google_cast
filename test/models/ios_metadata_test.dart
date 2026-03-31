import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Media metadata entities', () {
    test('movie metadata keeps movie specific fields', () {
      final metadata = GoogleCastMovieMediaMetadata(
        title: 'My Movie',
        studio: 'Studio A',
      );

      expect(
        metadata.metadataType,
        GoogleCastMediaMetadataType.movieMediaMetadata,
      );
      expect(metadata.title, 'My Movie');
      expect(metadata.studio, 'Studio A');
    });

    test('music metadata keeps track specific fields', () {
      final metadata = GoogleCastMusicMediaMetadata(
        title: 'Track Name',
        albumName: 'Album Name',
        trackNumber: 3,
      );

      expect(
        metadata.metadataType,
        GoogleCastMediaMetadataType.musicTrackMediaMetadata,
      );
      expect(metadata.title, 'Track Name');
      expect(metadata.albumName, 'Album Name');
      expect(metadata.trackNumber, 3);
    });

    test('tv show metadata keeps episode fields', () {
      final metadata = GoogleCastTvShowMediaMetadata(
        seriesTitle: 'Series Name',
        season: 2,
        episode: 5,
      );

      expect(
        metadata.metadataType,
        GoogleCastMediaMetadataType.tvShowMediaMetadata,
      );
      expect(metadata.seriesTitle, 'Series Name');
      expect(metadata.season, 2);
      expect(metadata.episode, 5);
    });

    test('photo metadata keeps photo fields', () {
      final metadata = GoogleCastPhotoMediaMetadata(
        title: 'Holiday',
        location: 'Lisbon',
        width: 1920,
        height: 1080,
      );

      expect(
        metadata.metadataType,
        GoogleCastMediaMetadataType.photoMediaMetadata,
      );
      expect(metadata.title, 'Holiday');
      expect(metadata.location, 'Lisbon');
      expect(metadata.width, 1920);
      expect(metadata.height, 1080);
    });

    test('generic metadata keeps shared fields', () {
      final metadata = GoogleCastGenericMediaMetadata(
        title: 'Generic Title',
        subtitle: 'Generic Subtitle',
      );

      expect(
        metadata.metadataType,
        GoogleCastMediaMetadataType.genericMediaMetadata,
      );
      expect(metadata.title, 'Generic Title');
      expect(metadata.subtitle, 'Generic Subtitle');
    });
  });
}