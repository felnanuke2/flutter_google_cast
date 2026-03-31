import 'package:flutter_chrome_cast_android/flutter_chrome_cast_android.dart';
import 'package:flutter_chrome_cast_ios/flutter_chrome_cast_ios.dart';
import 'package:flutter_chrome_cast_platform_interface/flutter_chrome_cast_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Federated registrants', () {
    test('android registrant wires all Android implementations', () {
      FlutterChromeCastAndroid.registerWith();

      expect(
        GoogleCastContextPlatformInterface.instance,
        isA<GoogleCastContextAndroidMethodChannel>(),
      );
      expect(
        GoogleCastDiscoveryManagerPlatformInterface.instance,
        isA<GoogleCastDiscoveryManagerMethodChannelAndroid>(),
      );
      expect(
        GoogleCastSessionManagerPlatformInterface.instance,
        isA<GoogleCastSessionManagerAndroidMethodChannel>(),
      );
      expect(
        GoogleCastRemoteMediaClientPlatformInterface.instance,
        isA<GoogleCastRemoteMediaClientAndroidMethodChannel>(),
      );
    });

    test('ios registrant wires all iOS implementations', () {
      FlutterChromeCastIos.registerWith();

      expect(
        GoogleCastContextPlatformInterface.instance,
        isA<FlutterIOSGoogleCastContextMethodChannel>(),
      );
      expect(
        GoogleCastDiscoveryManagerPlatformInterface.instance,
        isA<GoogleCastDiscoveryManagerMethodChannelIOS>(),
      );
      expect(
        GoogleCastSessionManagerPlatformInterface.instance,
        isA<GoogleCastSessionManagerIOSMethodChannel>(),
      );
      expect(
        GoogleCastRemoteMediaClientPlatformInterface.instance,
        isA<GoogleCastRemoteMediaClientIOSMethodChannel>(),
      );
    });
  });
}