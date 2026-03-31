import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCastMediaInformation', () {
    test('supports minimal required constructor values', () {
      final info = GoogleCastMediaInformation(
        contentId: 'https://cdn.example.com/video.m3u8',
        streamType: CastMediaStreamType.buffered,
        contentType: 'application/x-mpegURL',
      );

      expect(info.contentId, 'https://cdn.example.com/video.m3u8');
      expect(info.streamType, CastMediaStreamType.buffered);
      expect(info.contentType, 'application/x-mpegURL');
      expect(info.metadata, isNull);
      expect(info.tracks, isNull);
    });

    test('supports metadata and optional transport fields', () {
      final metadata = GoogleCastGenericMediaMetadata(
        title: 'Demo Video',
        subtitle: 'Episode 1',
      );

      final info = GoogleCastMediaInformation(
        contentId: 'media-1',
        streamType: CastMediaStreamType.live,
        contentType: 'video/mp4',
        metadata: metadata,
        contentUrl: Uri.parse('https://cdn.example.com/video.mp4'),
        customData: {'tenant': 'qa'},
      );

      expect(info.metadata, same(metadata));
      expect(info.contentUrl.toString(), 'https://cdn.example.com/video.mp4');
      expect(info.customData?['tenant'], 'qa');
    });
  });
}
