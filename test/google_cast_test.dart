import 'package:flutter_test/flutter_test.dart';
import 'package:google_cast/google_cast.dart';
import 'package:google_cast/google_cast_platform_interface.dart';
import 'package:google_cast/google_cast_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockGoogleCastPlatform 
    with MockPlatformInterfaceMixin
    implements GoogleCastPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final GoogleCastPlatform initialPlatform = GoogleCastPlatform.instance;

  test('$MethodChannelGoogleCast is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelGoogleCast>());
  });

  test('getPlatformVersion', () async {
    GoogleCast googleCastPlugin = GoogleCast();
    MockGoogleCastPlatform fakePlatform = MockGoogleCastPlatform();
    GoogleCastPlatform.instance = fakePlatform;
  
    expect(await googleCastPlugin.getPlatformVersion(), '42');
  });
}
