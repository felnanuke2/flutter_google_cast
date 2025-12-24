import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/models/ios/ios_media_information.dart';
import 'package:flutter_chrome_cast/models/ios/ios_media_track.dart';

void main() {
  group('GoogleCastMediaInformationIOS.fromMap', () {
    test('parses core fields and HLS formats', () {
      final map = {
        'contentID': 'abc123',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'application/vnd.apple.mpegurl',
        'metadata': {
          'type': GoogleCastMediaMetadataType.genericMediaMetadata.index,
          'title': 'Some Title',
          'subtitle': 'Some Subtitle',
          'images': [
            {'url': 'https://example.com/art.jpg', 'width': 512, 'height': 512}
          ],
        },
        'duration': 120.5, // seconds
        'customData': {'foo': 'bar'},
        'breaks': [
          {
            'id': 'b1',
            'startTime': 30,
            'duration': 10,
          }
        ],
        'breakClips': [
          {
            'id': 'c1',
            'contentId': 'ad-1',
            'duration': 5,
          }
        ],
        'contentURL': 'https://cdn.example.com/stream.m3u8',
        'entity': 'urn:foo:bar',
        'hlsSegmentFormat': 'AAC', // legacy upper snake
        'hlsVideoSegmentFormat': 'MPEG2_TS',
        'startAbsoluteTime': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'textTrackStyle': {
          'foreground_color_rgba_components': {
            'red': 255,
            'green': 255,
            'blue': 255,
            'alpha': 255,
          },
        },
        'tracks': [
          {
            'content_type': 'text/vtt',
            'id': 1,
            'type': TrackType.text.index,
            'language_code': 'en-US',
            'name': 'English',
            'subtype': TextTrackType.subtitles.index,
            'content_id': 'sub-en',
          }
        ],
        'userActionStates': [
          {'userAction': 'LIKE'},
          {'userAction': 'FOLLOW'},
        ],
        'vmapAdsRequest': {
          'adTagUrl': 'https://ads.example.com/tag',
        },
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.contentId, 'abc123');
      expect(info.streamType, CastMediaStreamType.buffered);
      expect(info.contentType, 'application/vnd.apple.mpegurl');
      expect(
          info.contentUrl?.toString(), 'https://cdn.example.com/stream.m3u8');
      expect(info.duration, isA<Duration>());
      expect(info.duration?.inMilliseconds, greaterThan(120000));
      expect(info.metadata?.extractedTitle, 'Some Title');
      expect(info.hlsSegmentFormat, CastHlsSegmentFormat.aac);
      expect(info.hlsVideoSegmentFormat, HlsVideoSegmentFormat.mpeg2Ts);
      expect(info.textTrackStyle, isNotNull);
      expect(info.tracks, isNotNull);
      expect(info.tracks!.first, isA<GoogleCastMediaTrack>());
      expect(
          (info.tracks!.first as IosMediaTrack).trackContentType, 'text/vtt');
      expect(info.userActionStates, isNotNull);
    });

    test('parses minimal required fields', () {
      final map = {
        'contentID': 'minimal-content',
        'streamType': CastMediaStreamType.live.index,
        'contentType': 'video/mp4',
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.contentId, 'minimal-content');
      expect(info.streamType, CastMediaStreamType.live);
      expect(info.contentType, 'video/mp4');
      expect(info.metadata, isNull);
      expect(info.duration, isNull);
      expect(info.customData, isNull);
      expect(info.breaks, isNull);
      expect(info.breakClips, isNull);
      expect(info.tracks, isNull);
    });

    test('handles empty contentID', () {
      final map = {
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'video/mp4',
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.contentId, '');
    });

    test('handles empty contentType', () {
      final map = {
        'contentID': 'test',
        'streamType': CastMediaStreamType.buffered.index,
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.contentType, '');
    });

    test('parses movie metadata type', () {
      final map = {
        'contentID': 'movie-1',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'video/mp4',
        'metadata': {
          'type': GoogleCastMediaMetadataType.movieMediaMetadata.index,
          'title': 'Movie Title',
          'subtitle': 'Movie Subtitle',
          'studio': 'Movie Studio',
        },
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.metadata, isNotNull);
      expect(info.metadata?.extractedTitle, 'Movie Title');
    });

    test('parses TV show metadata type', () {
      final map = {
        'contentID': 'tvshow-1',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'video/mp4',
        'metadata': {
          'type': GoogleCastMediaMetadataType.tvShowMediaMetadata.index,
          'seriesTitle': 'Series Name',
          'seasonNumber': 2,
          'episodeNumber': 5,
        },
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.metadata, isNotNull);
    });

    test('parses music track metadata type', () {
      final map = {
        'contentID': 'music-1',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'audio/mp3',
        'metadata': {
          'type': GoogleCastMediaMetadataType.musicTrackMediaMetadata.index,
          'title': 'Song Title',
          'artist': 'Artist Name',
          'albumTitle': 'Album Name',
        },
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.metadata, isNotNull);
    });

    test('parses photo metadata type', () {
      final map = {
        'contentID': 'photo-1',
        'streamType': CastMediaStreamType.none.index,
        'contentType': 'image/jpeg',
        'metadata': {
          'type': GoogleCastMediaMetadataType.photoMediaMetadata.index,
          'title': 'Photo Title',
        },
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.metadata, isNotNull);
    });

    test('handles null metadata type', () {
      final map = {
        'contentID': 'no-meta',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'video/mp4',
        'metadata': {
          'title': 'Title Without Type',
        },
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      // Metadata should be null when type is missing
      expect(info.metadata, isNull);
    });

    test('handles invalid contentURL', () {
      final map = {
        'contentID': 'test',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'video/mp4',
        'contentURL': '',
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      // Empty string parses to empty URI
      expect(info.contentUrl?.toString(), '');
    });

    test('parses atvEntity field', () {
      final map = {
        'contentID': 'test',
        'streamType': CastMediaStreamType.buffered.index,
        'contentType': 'video/mp4',
        'atvEntity': 'apple-tv-entity-123',
      };

      final info = GoogleCastMediaInformationIOS.fromMap(map);
      expect(info.atvEntity, 'apple-tv-entity-123');
    });

    test('constructor creates instance with all parameters', () {
      final info = GoogleCastMediaInformationIOS(
        contentId: 'test-content',
        streamType: CastMediaStreamType.buffered,
        contentType: 'video/mp4',
        duration: const Duration(minutes: 10),
        customData: {'key': 'value'},
        entity: 'urn:test:entity',
        atvEntity: 'atv-entity',
      );

      expect(info.contentId, 'test-content');
      expect(info.streamType, CastMediaStreamType.buffered);
      expect(info.contentType, 'video/mp4');
      expect(info.duration?.inMinutes, 10);
      expect(info.customData, {'key': 'value'});
      expect(info.entity, 'urn:test:entity');
      expect(info.atvEntity, 'atv-entity');
    });
  });
}
