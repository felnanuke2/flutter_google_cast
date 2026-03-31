import 'package:flutter_chrome_cast/common/break_clips.dart';
import 'package:flutter_chrome_cast/common/hls_segment_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CastBreakClips', () {
    test('keeps required and optional values', () {
      final clip = CastBreakClips(
        id: 'clip-1',
        contentId: 'content-id',
        contentType: 'video/mp4',
        duration: const Duration(seconds: 30),
        whenSkippable: const Duration(seconds: 5),
        hlsSegmentFormat: CastHlsSegmentFormat.aac,
      );

      expect(clip.id, 'clip-1');
      expect(clip.contentId, 'content-id');
      expect(clip.contentType, 'video/mp4');
      expect(clip.duration, const Duration(seconds: 30));
      expect(clip.whenSkippable, const Duration(seconds: 5));
      expect(clip.hlsSegmentFormat, CastHlsSegmentFormat.aac);
    });

    test('supports fully nullable optional fields', () {
      final clip = CastBreakClips(id: 'clip-min');

      expect(clip.id, 'clip-min');
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
  });
}
