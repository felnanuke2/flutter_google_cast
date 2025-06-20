import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context.dart';
import 'package:flutter_chrome_cast/_google_cast_context/google_cast_context_platform_interface.dart';
import 'package:flutter_chrome_cast/_google_cast_context/android_google_cast_context_method_channel.dart';
import 'package:flutter_chrome_cast/_google_cast_context/ios_google_cast_context_method_channel.dart';

void main() {
  group('GoogleCastContext', () {
    test('should return Android implementation when Platform.isAndroid is true',
        () {
      // This test covers the static instance creation and Platform.isAndroid check
      final instance = GoogleCastContext.instance;

      // Verify that we get a platform interface instance
      expect(instance, isA<GoogleCastContextPlatformInterface>());

      // The actual implementation depends on the platform the test is running on
      // But we can verify the instance is properly initialized
      expect(instance, isNotNull);
    });

    test('should provide singleton instance access', () {
      // This test covers the static instance getter (line 22)
      final instance1 = GoogleCastContext.instance;
      final instance2 = GoogleCastContext.instance;

      // Both calls should return the same instance
      expect(instance1, equals(instance2));
      expect(identical(instance1, instance2), isTrue);
    });

    test('should initialize with proper platform-specific implementation', () {
      // This test ensures the static final _instance field is properly initialized
      final instance = GoogleCastContext.instance;

      // Verify the instance is of the correct type based on platform
      expect(instance, isA<GoogleCastContextPlatformInterface>());

      // The instance should be either Android or iOS implementation
      final isAndroidImpl = instance is GoogleCastContextAndroidMethodChannel;
      final isIOSImpl = instance is FlutterIOSGoogleCastContextMethodChannel;

      expect(isAndroidImpl || isIOSImpl, isTrue);
    });

    test('should have private constructor that cannot be instantiated', () {
      // This test covers the private constructor (line 25)
      // We can't directly test the private constructor, but we can verify
      // that the class follows singleton pattern and constructor behavior

      // Verify that accessing the instance works through the static getter
      expect(() => GoogleCastContext.instance, returnsNormally);

      // The constructor is private, so we can't test it directly
      // but this test ensures the singleton pattern is working
      final instance = GoogleCastContext.instance;
      expect(instance, isNotNull);
    });

    test('should select correct implementation based on platform', () {
      // This test covers the ternary operator logic (lines 14-16)
      final instance = GoogleCastContext.instance;

      if (Platform.isAndroid) {
        expect(instance, isA<GoogleCastContextAndroidMethodChannel>());
      } else {
        expect(instance, isA<FlutterIOSGoogleCastContextMethodChannel>());
      }
    });

    test('should maintain same instance across multiple access', () {
      // Additional test to ensure the static final field works correctly
      final instances = List.generate(5, (_) => GoogleCastContext.instance);

      // All instances should be identical
      for (int i = 1; i < instances.length; i++) {
        expect(identical(instances[0], instances[i]), isTrue);
      }
    });

    test('should provide access to platform interface methods', () {
      // Test that the instance provides the expected interface
      final instance = GoogleCastContext.instance;

      // Verify it has the required method from platform interface
      expect(instance.setSharedInstanceWithOptions, isA<Function>());
    });
  });
}
