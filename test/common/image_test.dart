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

    test('fromMap parses valid map', () {
      final img = GoogleCastImage.fromMap({
        'url': 'https://example.com/a.png',
        'width': 640,
        'height': 480,
      });
      expect(img, isNotNull);
      expect(img!.url.toString(), 'https://example.com/a.png');
      expect(img.width, 640);
      expect(img.height, 480);
    });

    test('toJson/fromJson roundtrip', () {
      final img = GoogleCastImage(
        url: Uri.parse('https://ex.com/x.jpg'),
        width: 10,
        height: 20,
      );
      final json = img.toJson();
      final parsed = GoogleCastImage.fromJson(json);
      expect(parsed!.url.toString(), 'https://ex.com/x.jpg');
      expect(parsed.width, 10);
      expect(parsed.height, 20);
    });

    test('fromMap handles null width and height', () {
      final img = GoogleCastImage.fromMap({'url': 'https://example.com/b.png'});
      expect(img, isNotNull);
      expect(img!.url.toString(), 'https://example.com/b.png');
      expect(img.width, isNull);
      expect(img.height, isNull);
    });

    test('fromMap returns null for unparseable url', () {
      // Uri.tryParse may return null for very malformed strings
      // However most strings can be parsed, so we test empty string
      final img = GoogleCastImage.fromMap({'url': ''});
      expect(img, isNull);
    });

    test('toMap includes all fields', () {
      final img = GoogleCastImage(
        url: Uri.parse('https://example.com/full.jpg'),
        width: 1920,
        height: 1080,
      );

      final map = img.toMap();
      expect(map['url'], 'https://example.com/full.jpg');
      expect(map['width'], 1920);
      expect(map['height'], 1080);
    });
  });
}
