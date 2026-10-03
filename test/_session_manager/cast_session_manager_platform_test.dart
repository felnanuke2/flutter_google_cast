import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_session_manager/cast_session_manager_platform.dart';

class _StubSessionManager extends GoogleCastSessionManagerPlatformInterface {
  _StubSessionManager() : super(token: Object());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GoogleCastSessionManagerPlatformInterface', () {
    test('default dispose is a no-op and does not throw', () {
      final manager = _StubSessionManager();

      expect(manager.dispose, returnsNormally);
    });
  });
}
