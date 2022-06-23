import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_cast/google_cast_method_channel.dart';

void main() {
  MethodChannelGoogleCast platform = MethodChannelGoogleCast();
  const MethodChannel channel = MethodChannel('google_cast');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
