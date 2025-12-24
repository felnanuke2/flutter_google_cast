import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/common/break_clips.dart';
import 'package:flutter_chrome_cast/common/hls_segment_format.dart';

void main() {
  group('CastBreakClips', () {
    test('fromMap parses minimal fields', () {
      final map = {
        'id': 'clip-1',
        'duration': 7,
        'whenSkippable': 5,
        'hlsSegmentFormat': 'AAC',
      };
      final clip = CastBreakClips.fromMap(map);
      expect(clip.id, 'clip-1');
      expect(clip.duration!.inSeconds, 7);
      expect(clip.whenSkippable!.inSeconds, 5);
      expect(clip.hlsSegmentFormat, CastHlsSegmentFormat.aac);
    });

    test('toMap contains expected keys', () {
      final clip = CastBreakClips(
        id: 'x',
        contentId: 'cid',
        contentType: 'video/mp2t',
        duration: const Duration(seconds: 11),
      );
      final map = clip.toMap();
      expect(map['id'], 'x');
      expect(map['contentId'], 'cid');
      expect(map['duration'], 11);
      expect(map.containsKey('hlsSegmentFormat'), true);
    });

    test('fromMap parses all fields', () {
      final map = {
        'id': 'clip-2',
        'clickThroughUrl': 'https://example.com/click',
        'contentId': 'content-123',
        'contentType': 'video/mp4',
        'contentUrl': 'https://example.com/video.mp4',
        'customData': {'key': 'value'},
        'duration': 30,
        'hlsSegmentFormat': 'TS',
        'posterUrl': 'https://example.com/poster.jpg',
        'title': 'Ad Title',
        'whenSkippable': 10,
      };

      final clip = CastBreakClips.fromMap(map);
      expect(clip.id, 'clip-2');
      expect(clip.clickThroughUrl, 'https://example.com/click');
      expect(clip.contentId, 'content-123');
      expect(clip.contentType, 'video/mp4');
      expect(clip.contentUrl, 'https://example.com/video.mp4');
      expect(clip.customData, {'key': 'value'});
      expect(clip.duration!.inSeconds, 30);
      expect(clip.hlsSegmentFormat, CastHlsSegmentFormat.ts);
      expect(clip.posterUrl, 'https://example.com/poster.jpg');
      expect(clip.title, 'Ad Title');
      expect(clip.whenSkippable!.inSeconds, 10);
    });

    test('fromMap handles null values gracefully', () {
      final map = {
        'id': 'clip-3',
        'duration': null,
        'whenSkippable': null,
        'hlsSegmentFormat': null,
        'customData': null,
        'vastAdsRequest': null,
      };

      final clip = CastBreakClips.fromMap(map);
      expect(clip.id, 'clip-3');
      expect(clip.duration, isNull);
      expect(clip.whenSkippable, isNull);
      expect(clip.hlsSegmentFormat, isNull);
      expect(clip.customData, isNull);
      expect(clip.vastAdsRequest, isNull);
    });

    test('fromMap handles missing id with empty string', () {
      final map = <String, dynamic>{};
      final clip = CastBreakClips.fromMap(map);
      expect(clip.id, '');
    });

    test('toMap serializes all fields correctly', () {
      final clip = CastBreakClips(
        id: 'clip-full',
        clickThroughUrl: 'https://click.example.com',
        contentId: 'content-full',
        contentType: 'application/vnd.apple.mpegurl',
        contentUrl: 'https://example.com/stream.m3u8',
        customData: {'custom': 'data'},
        duration: const Duration(seconds: 60),
        hlsSegmentFormat: CastHlsSegmentFormat.aac,
        posterUrl: 'https://example.com/poster.png',
        title: 'Full Ad',
        vastAdsRequest: null,
        whenSkippable: const Duration(seconds: 15),
      );

      final map = clip.toMap();
      expect(map['id'], 'clip-full');
      expect(map['clickThroughUrl'], 'https://click.example.com');
      expect(map['contentId'], 'content-full');
      expect(map['contentType'], 'application/vnd.apple.mpegurl');
      expect(map['contentUrl'], 'https://example.com/stream.m3u8');
      expect(map['customData'], {'custom': 'data'});
      expect(map['duration'], 60);
      expect(map['hlsSegmentFormat'], 'aac');
      expect(map['posterUrl'], 'https://example.com/poster.png');
      expect(map['title'], 'Full Ad');
      expect(map['whenSkippable'], 15);
    });

    test('toJson and fromJson roundtrip', () {
      final originalClip = CastBreakClips(
        id: 'roundtrip-clip',
        contentId: 'rt-content',
        contentType: 'video/mp4',
        duration: const Duration(seconds: 45),
        title: 'Roundtrip Test',
      );

      final json = originalClip.toJson();
      final parsedClip = CastBreakClips.fromJson(json);

      expect(parsedClip.id, originalClip.id);
      expect(parsedClip.contentId, originalClip.contentId);
      expect(parsedClip.contentType, originalClip.contentType);
      expect(parsedClip.duration?.inSeconds, originalClip.duration?.inSeconds);
      expect(parsedClip.title, originalClip.title);
    });

    test('constructor creates instance with required id only', () {
      final clip = CastBreakClips(id: 'minimal');
      expect(clip.id, 'minimal');
      expect(clip.clickThroughUrl, isNull);
      expect(clip.contentId, isNull);
      expect(clip.contentType, isNull);
      expect(clip.contentUrl, isNull);
      expect(clip.customData, isNull);
      expect(clip.duration, isNull);
      expect(clip.hlsSegmentFormat, isNull);
      expect(clip.posterUrl, isNull);
      expect(clip.title, isNull);
      expect(clip.vastAdsRequest, isNull);
      expect(clip.whenSkippable, isNull);
    });

    test('fromMap with vastAdsRequest', () {
      final map = {
        'id': 'clip-vast',
        'vastAdsRequest': {
          'adTagUrl': 'https://ads.example.com/vast',
        },
      };

      final clip = CastBreakClips.fromMap(map);
      expect(clip.id, 'clip-vast');
      expect(clip.vastAdsRequest, isNotNull);
    });
  });
}
