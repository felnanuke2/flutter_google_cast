import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/common/image.dart';

void main() {
  group('GoogleCastImage', () {
    test('fromMap returns null for invalid url', () {
      expect(GoogleCastImage.fromMap({'url': ''}), isNull);
      expect(GoogleCastImage.fromMap({}), isNull);
      expect(GoogleCastImage.fromMap({'url': 123}), isNull);
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
      final img = GoogleCastImage(url: Uri.parse('https://ex.com/x.jpg'), width: 10, height: 20);
      final json = img.toJson();
      final parsed = GoogleCastImage.fromJson(json);
      expect(parsed!.url.toString(), 'https://ex.com/x.jpg');
      expect(parsed.width, 10);
      expect(parsed.height, 20);
    });

    test('fromMap handles null width and height', () {
      final img = GoogleCastImage.fromMap({
        'url': 'https://example.com/b.png',
      });
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

    test('toMap handles null width and height', () {
      final img = GoogleCastImage(
        url: Uri.parse('https://example.com/minimal.jpg'),
      );
      final map = img.toMap();
      expect(map['url'], 'https://example.com/minimal.jpg');
      expect(map['width'], isNull);
      expect(map['height'], isNull);
    });

    test('constructor creates valid instance', () {
      final img = GoogleCastImage(
        url: Uri.parse('https://example.com/test.png'),
        width: 100,
        height: 200,
      );
      expect(img.url.toString(), 'https://example.com/test.png');
      expect(img.width, 100);
      expect(img.height, 200);
    });

    test('constructor creates instance with url only', () {
      final img = GoogleCastImage(
        url: Uri.parse('https://example.com/only-url.png'),
      );
      expect(img.url.toString(), 'https://example.com/only-url.png');
      expect(img.width, isNull);
      expect(img.height, isNull);
    });

    test('fromMap with double values for width and height', () {
      final img = GoogleCastImage.fromMap({
        'url': 'https://example.com/double.png',
        'width': 100.5,
        'height': 200.7,
      });
      expect(img, isNotNull);
      expect(img!.width, 100); // toInt() truncates
      expect(img.height, 200);
    });

    test('fromJson parses JSON string correctly', () {
      const jsonString = '{"url":"https://example.com/json.png","width":300,"height":400}';
      final img = GoogleCastImage.fromJson(jsonString);
      expect(img, isNotNull);
      expect(img!.url.toString(), 'https://example.com/json.png');
      expect(img.width, 300);
      expect(img.height, 400);
    });

    test('toJson produces valid JSON string', () {
      final img = GoogleCastImage(
        url: Uri.parse('https://example.com/output.png'),
        width: 500,
        height: 600,
      );
      final json = img.toJson();
      expect(json, contains('"url":"https://example.com/output.png"'));
      expect(json, contains('"width":500'));
      expect(json, contains('"height":600'));
    });
  });
}
