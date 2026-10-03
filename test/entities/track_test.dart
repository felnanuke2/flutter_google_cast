import 'package:flutter_chrome_cast/entities/track.dart';
import 'package:flutter_chrome_cast/enums/track_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCastMediaTrack.fromMap', () {
    test('accepts an in-band audio track without a content type', () {
      final track = GoogleCastMediaTrack.fromMap({
        'trackId': 7,
        'type': 'AUDIO',
        'name': 'Portuguese',
        'language': 'pt',
        'trackContentType': null,
      });

      expect(track.trackId, 7);
      expect(track.type, TrackType.audio);
      expect(track.trackContentType, isEmpty);
      expect(track.name, 'Portuguese');
    });

    test('preserves an explicit content type', () {
      final track = GoogleCastMediaTrack.fromMap({
        'trackId': 8,
        'type': 'AUDIO',
        'trackContentType': 'audio/mp4',
      });

      expect(track.trackContentType, 'audio/mp4');
    });
  });
}
