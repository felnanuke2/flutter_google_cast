import 'package:flutter_chrome_cast/common/image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCastImage', () {
    test('stores url only image', () {
      final image = GoogleCastImage(
        url: Uri.parse('https://example.com/poster.png'),
      );

      expect(image.url.toString(), 'https://example.com/poster.png');
      expect(image.width, isNull);
      expect(image.height, isNull);
    });

    test('stores optional dimensions', () {
      final image = GoogleCastImage(
        url: Uri.parse('https://example.com/poster@2x.png'),
        width: 1920,
        height: 1080,
      );

      expect(image.url.toString(), 'https://example.com/poster@2x.png');
      expect(image.width, 1920);
      expect(image.height, 1080);
    });
  });
}
