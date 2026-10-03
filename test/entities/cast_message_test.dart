import 'package:flutter_chrome_cast/entities/cast_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GoogleCastMessage', () {
    const message = GoogleCastMessage(
      namespace: 'urn:x-cast:example.channel',
      message: '{"status":"ready"}',
    );

    test('value equality covers namespace and message', () {
      expect(
        message,
        equals(const GoogleCastMessage(
          namespace: 'urn:x-cast:example.channel',
          message: '{"status":"ready"}',
        )),
      );
      expect(
        message,
        isNot(equals(const GoogleCastMessage(
          namespace: 'urn:x-cast:other.channel',
          message: '{"status":"ready"}',
        ))),
      );
      expect(
        message,
        isNot(equals(const GoogleCastMessage(
          namespace: 'urn:x-cast:example.channel',
          message: '{"status":"other"}',
        ))),
      );
    });

    test('hashCode matches equal instances', () {
      expect(
        message.hashCode,
        equals(const GoogleCastMessage(
          namespace: 'urn:x-cast:example.channel',
          message: '{"status":"ready"}',
        ).hashCode),
      );
    });

    test('toString includes namespace and message', () {
      expect(
        message.toString(),
        contains('urn:x-cast:example.channel'),
      );
      expect(message.toString(), contains('{"status":"ready"}'));
    });
  });
}
