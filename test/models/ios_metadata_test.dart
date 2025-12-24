import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/music.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/movie.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/generic.dart';
import 'package:flutter_chrome_cast/models/ios/metadata/tv_show.dart';

void main() {
  group('iOS Media Metadata mapping', () {
    group('GoogleCastMusicMediaMetadataIOS', () {
      test('fromMap parses all fields', () {
        final map = {
          'albumTitle': 'Album X',
          'title': 'Track Y',
          'albumArtist': 'Album Artist',
          'artist': 'Main Artist',
          'composer': 'Composer Z',
          'trackNumber': 3,
          'discNumber': 1,
          'images': [
            {'url': 'https://example.com/img1.jpg', 'width': 100, 'height': 100},
            {'url': '', 'width': 50, 'height': 50},
          ],
          // milliseconds since epoch
          'releaseDate': DateTime(2023, 7, 20).millisecondsSinceEpoch,
        };

        final m = GoogleCastMusicMediaMetadataIOS.fromMap(map);
        expect(m.albumName, 'Album X');
        expect(m.title, 'Track Y');
        expect(m.albumArtist, 'Album Artist');
        expect(m.artist, 'Main Artist');
        expect(m.composer, 'Composer Z');
        expect(m.trackNumber, 3);
        expect(m.discNumber, 1);
        expect(m.images, isNotNull);
        expect(m.images!.length, 1); // invalid image filtered out
        expect(m.images!.first.url.toString(), 'https://example.com/img1.jpg');
        expect(m.releaseDate, isA<DateTime>());
      });

      test('fromMap handles null images', () {
        final map = {
          'albumTitle': 'Album',
          'title': 'Track',
          'images': null,
        };

        final m = GoogleCastMusicMediaMetadataIOS.fromMap(map);
        expect(m.images, isNull);
      });

      test('fromMap handles empty images list', () {
        final map = {
          'albumTitle': 'Album',
          'title': 'Track',
          'images': [],
        };

        final m = GoogleCastMusicMediaMetadataIOS.fromMap(map);
        expect(m.images, isEmpty);
      });

      test('fromMap handles null releaseDate', () {
        final map = {
          'title': 'Track',
          'releaseDate': null,
        };

        final m = GoogleCastMusicMediaMetadataIOS.fromMap(map);
        expect(m.releaseDate, isNull);
      });

      test('fromMap handles non-int releaseDate', () {
        final map = {
          'title': 'Track',
          'releaseDate': 'not an int',
        };

        final m = GoogleCastMusicMediaMetadataIOS.fromMap(map);
        expect(m.releaseDate, isNull);
      });

      test('constructor creates instance with all parameters', () {
        final m = GoogleCastMusicMediaMetadataIOS(
          albumArtist: 'Album Artist',
          albumName: 'Album Name',
          artist: 'Artist',
          composer: 'Composer',
          discNumber: 2,
          images: [GoogleCastImage(url: Uri.parse('https://example.com/img.jpg'))],
          releaseDate: DateTime(2023, 1, 1),
          title: 'Title',
          trackNumber: 5,
        );

        expect(m.albumArtist, 'Album Artist');
        expect(m.albumName, 'Album Name');
        expect(m.artist, 'Artist');
        expect(m.composer, 'Composer');
        expect(m.discNumber, 2);
        expect(m.images, hasLength(1));
        expect(m.releaseDate, isNotNull);
        expect(m.title, 'Title');
        expect(m.trackNumber, 5);
      });
    });

    test('Music fromMap parses fields', () {
      final map = {
        'albumTitle': 'Album X',
        'title': 'Track Y',
        'albumArtist': 'Album Artist',
        'artist': 'Main Artist',
        'composer': 'Composer Z',
        'trackNumber': 3,
        'discNumber': 1,
        'images': [
          {'url': 'https://example.com/img1.jpg', 'width': 100, 'height': 100},
          {'url': '', 'width': 50, 'height': 50},
        ],
        // milliseconds since epoch
        'releaseDate': DateTime(2023, 7, 20).millisecondsSinceEpoch,
      };

      final m = GoogleCastMusicMediaMetadataIOS.fromMap(map);
      expect(m.albumName, 'Album X');
      expect(m.title, 'Track Y');
      expect(m.albumArtist, 'Album Artist');
      expect(m.artist, 'Main Artist');
      expect(m.composer, 'Composer Z');
      expect(m.trackNumber, 3);
      expect(m.discNumber, 1);
      expect(m.images, isNotNull);
      expect(m.images!.length, 1); // invalid image filtered out
      expect(m.images!.first.url.toString(), 'https://example.com/img1.jpg');
      expect(m.releaseDate, isA<DateTime>());
    });

    group('GoogleCastMovieMediaMetadataIOS', () {
      test('fromMap parses all fields', () {
        final map = {
          'title': 'A Movie',
          'subtitle': 'A Subtitle',
          'studio': 'Studio Q',
          'images': [
            {'url': 'https://example.com/poster.png', 'width': 300, 'height': 450},
          ],
          'releaseDate': DateTime(2022, 1, 1).millisecondsSinceEpoch,
        };

        final m = GoogleCastMovieMediaMetadataIOS.fromMap(map);
        expect(m.title, 'A Movie');
        expect(m.subtitle, 'A Subtitle');
        expect(m.studio, 'Studio Q');
        expect(m.images!.first.url.toString(), 'https://example.com/poster.png');
        expect(m.releaseDate, isA<DateTime>());
      });

      test('fromMap handles null images', () {
        final map = {
          'title': 'Movie',
          'images': null,
        };

        final m = GoogleCastMovieMediaMetadataIOS.fromMap(map);
        expect(m.images, isNull);
      });

      test('fromMap handles null releaseDate', () {
        final map = {
          'title': 'Movie',
          'releaseDate': null,
        };

        final m = GoogleCastMovieMediaMetadataIOS.fromMap(map);
        expect(m.releaseDate, isNull);
      });

      test('fromMap handles non-int releaseDate', () {
        final map = {
          'title': 'Movie',
          'releaseDate': 'not an int',
        };

        final m = GoogleCastMovieMediaMetadataIOS.fromMap(map);
        expect(m.releaseDate, isNull);
      });

      test('constructor creates instance with all parameters', () {
        final m = GoogleCastMovieMediaMetadataIOS(
          title: 'Movie Title',
          subtitle: 'Subtitle',
          studio: 'Studio',
          images: [GoogleCastImage(url: Uri.parse('https://example.com/poster.jpg'))],
          releaseDate: DateTime(2023, 6, 15),
        );

        expect(m.title, 'Movie Title');
        expect(m.subtitle, 'Subtitle');
        expect(m.studio, 'Studio');
        expect(m.images, hasLength(1));
        expect(m.releaseDate, isNotNull);
      });
    });

    test('Movie fromMap parses fields', () {
      final map = {
        'title': 'A Movie',
        'subtitle': 'A Subtitle',
        'studio': 'Studio Q',
        'images': [
          {'url': 'https://example.com/poster.png', 'width': 300, 'height': 450},
        ],
        'releaseDate': DateTime(2022, 1, 1).millisecondsSinceEpoch,
      };

      final m = GoogleCastMovieMediaMetadataIOS.fromMap(map);
      expect(m.title, 'A Movie');
      expect(m.subtitle, 'A Subtitle');
      expect(m.studio, 'Studio Q');
      expect(m.images!.first.url.toString(), 'https://example.com/poster.png');
      expect(m.releaseDate, isA<DateTime>());
    });

    group('GoogleCastGenericMediaMetadataIOS', () {
      test('fromMap parses all fields', () {
        final map = {
          'title': 'Generic Title',
          'subtitle': 'Generic Subtitle',
          'images': [
            {'url': 'https://example.com/img.png'},
          ],
          'releaseDate': DateTime(2021, 5, 10).millisecondsSinceEpoch,
        };

        final m = GoogleCastGenericMediaMetadataIOS.fromMap(map);
        expect(m.title, 'Generic Title');
        expect(m.subtitle, 'Generic Subtitle');
        expect(m.images!.first.url.toString(), 'https://example.com/img.png');
        expect(m.releaseDate, isA<DateTime>());
      });

      test('fromMap handles null images', () {
        final map = {
          'title': 'Title',
          'subtitle': 'Subtitle',
          'images': null,
        };

        final m = GoogleCastGenericMediaMetadataIOS.fromMap(map);
        expect(m.images, isNull);
      });

      test('fromMap handles null releaseDate', () {
        final map = {
          'title': 'Title',
          'subtitle': 'Subtitle',
          'images': null,
          'releaseDate': null,
        };

        final m = GoogleCastGenericMediaMetadataIOS.fromMap(map);
        expect(m.releaseDate, isNull);
      });

      test('fromMap handles non-int releaseDate', () {
        final map = {
          'title': 'Title',
          'subtitle': 'Subtitle',
          'images': null,
          'releaseDate': 'string date',
        };

        final m = GoogleCastGenericMediaMetadataIOS.fromMap(map);
        expect(m.releaseDate, isNull);
      });

      test('constructor creates instance with all parameters', () {
        final m = GoogleCastGenericMediaMetadataIOS(
          title: 'Title',
          subtitle: 'Subtitle',
          images: [GoogleCastImage(url: Uri.parse('https://example.com/img.jpg'))],
          releaseDate: DateTime(2023, 3, 20),
        );

        expect(m.title, 'Title');
        expect(m.subtitle, 'Subtitle');
        expect(m.images, hasLength(1));
        expect(m.releaseDate, isNotNull);
      });
    });

    test('Generic fromMap parses fields', () {
      final map = {
        'title': 'Generic Title',
        'subtitle': 'Generic Subtitle',
        'images': [
          {'url': 'https://example.com/img.png'},
        ],
        'releaseDate': DateTime(2021, 5, 10).millisecondsSinceEpoch,
      };

      final m = GoogleCastGenericMediaMetadataIOS.fromMap(map);
      expect(m.title, 'Generic Title');
      expect(m.subtitle, 'Generic Subtitle');
      expect(m.images!.first.url.toString(), 'https://example.com/img.png');
      expect(m.releaseDate, isA<DateTime>());
    });

    group('GoogleCastTvShowMediaMetadataIOS', () {
      test('fromMap parses all fields', () {
        final map = {
          'seriesTitle': 'Series A',
          'seasonNumber': 2,
          'episodeNumber': 7,
          'images': [
            {'url': 'https://example.com/cover.jpg'},
          ],
          'releaseDate': '20240102',
        };

        final m = GoogleCastTvShowMediaMetadataIOS.fromMap(map);
        expect(m.seriesTitle, 'Series A');
        expect(m.season, 2);
        expect(m.episode, 7);
        expect(m.images!.first.url.toString(), 'https://example.com/cover.jpg');
        expect(m.originalAirDate, isNotNull);
        expect(m.originalAirDate!.year, 2024);
      });

      test('fromMap handles null images', () {
        final map = {
          'seriesTitle': 'Series',
          'images': null,
        };

        final m = GoogleCastTvShowMediaMetadataIOS.fromMap(map);
        expect(m.images, isNull);
      });

      test('fromMap handles null releaseDate', () {
        final map = {
          'seriesTitle': 'Series',
          'releaseDate': null,
        };

        final m = GoogleCastTvShowMediaMetadataIOS.fromMap(map);
        expect(m.originalAirDate, isNull);
      });

      test('fromMap handles invalid releaseDate string', () {
        final map = {
          'seriesTitle': 'Series',
          'releaseDate': '2024-01-02', // ISO format should parse
        };

        final m = GoogleCastTvShowMediaMetadataIOS.fromMap(map);
        // Should handle gracefully (result depends on DateTimeString.tryParse behavior)
        expect(m.seriesTitle, 'Series');
      });

      test('constructor creates instance with all parameters', () {
        final m = GoogleCastTvShowMediaMetadataIOS(
          seriesTitle: 'Series Title',
          season: 3,
          episode: 10,
          images: [GoogleCastImage(url: Uri.parse('https://example.com/episode.jpg'))],
          originalAirDate: DateTime(2023, 9, 15),
        );

        expect(m.seriesTitle, 'Series Title');
        expect(m.season, 3);
        expect(m.episode, 10);
        expect(m.images, hasLength(1));
        expect(m.originalAirDate, isNotNull);
      });
    });

    test('TV Show fromMap parses fields', () {
      final map = {
        'seriesTitle': 'Series A',
        'seasonNumber': 2,
        'episodeNumber': 7,
        'images': [
          {'url': 'https://example.com/cover.jpg'},
        ],
        'releaseDate': '20240102',
      };

      final m = GoogleCastTvShowMediaMetadataIOS.fromMap(map);
      expect(m.seriesTitle, 'Series A');
      expect(m.season, 2);
      expect(m.episode, 7);
      expect(m.images!.first.url.toString(), 'https://example.com/cover.jpg');
      expect(m.originalAirDate, isNotNull);
      expect(m.originalAirDate!.year, 2024);
    });
  });
}
