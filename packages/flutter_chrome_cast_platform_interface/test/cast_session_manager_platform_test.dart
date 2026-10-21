import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubSessionManager extends GoogleCastSessionManagerPlatformInterface {
  _StubSessionManager();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GoogleCastSessionManagerPlatformInterface', () {
    test('default dispose is a no-op and does not throw', () {
      final manager = _StubSessionManager();

      expect(manager.dispose, returnsNormally);
    });

    test('resetSession is not implemented by the base interface', () {
      final manager = _StubSessionManager();

      expect(manager.resetSession, throwsA(isA<NoSuchMethodError>()));
    });
  });
}
