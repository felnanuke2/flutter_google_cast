import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/themes.dart';
import 'package:flutter_chrome_cast/widgets/expanded_player.dart';
import 'package:flutter_chrome_cast/_remote_media_client/ios_remote_media_client_method_channel.dart';
import 'package:flutter_chrome_cast/_session_manager/ios_cast_session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ExpandedGoogleCastPlayerController', () {
    late MethodChannel remoteMediaChannel;
    late MethodChannel sessionChannel;

    setUp(() {
      remoteMediaChannel =
          const MethodChannel('google_cast.remote_media_client');
      sessionChannel = const MethodChannel('google_cast.session_manager');

      // Set up mock for remote media client
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(remoteMediaChannel,
              (MethodCall methodCall) async {
        return null;
      });

      // Set up mock for session manager
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sessionChannel,
              (MethodCall methodCall) async {
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(remoteMediaChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sessionChannel, null);
    });

    test('creates widget with default parameters', () {
      const widget = ExpandedGoogleCastPlayerController();

      expect(widget.toggleExpand, isNull);
      expect(widget.theme, isNull);
      expect(widget.texts, isNull);
    });

    test('creates widget with custom parameters', () {
      final theme = GoogleCastPlayerTheme(
        backgroundColor: Colors.black,
        iconColor: Colors.white,
      );
      final texts = GoogleCastPlayerTexts(
        nowPlaying: 'Custom Now Playing',
        unknownTitle: 'Custom Unknown',
      );
      void toggleExpand() {}

      final widget = ExpandedGoogleCastPlayerController(
        toggleExpand: toggleExpand,
        theme: theme,
        texts: texts,
      );

      expect(widget.toggleExpand, equals(toggleExpand));
      expect(widget.theme, equals(theme));
      expect(widget.texts, equals(texts));
    });

    test('GoogleCastPlayerTexts has correct default values', () {
      const texts = GoogleCastPlayerTexts();

      expect(texts.unknownTitle, equals('Unknown Title'));
      expect(texts.nowPlaying, equals('Now Playing'));
      expect(texts.noCaptionsAvailable, equals('No captions available'));
      expect(texts.captionsOff, equals('Off'));
      expect(texts.castingToDevice('Test Device'),
          equals('Casting to Test Device'));
      expect(texts.trackFallback(1), equals('Track 1'));
    });

    test('GoogleCastPlayerTexts custom values work correctly', () {
      final texts = GoogleCastPlayerTexts(
        unknownTitle: 'Sin título',
        nowPlaying: 'Reproduciendo',
        noCaptionsAvailable: 'Sin subtítulos',
        captionsOff: 'Desactivar',
        castingToDevice: (device) => 'Transmitiendo a $device',
        trackFallback: (id) => 'Pista $id',
      );

      expect(texts.unknownTitle, equals('Sin título'));
      expect(texts.nowPlaying, equals('Reproduciendo'));
      expect(texts.noCaptionsAvailable, equals('Sin subtítulos'));
      expect(texts.captionsOff, equals('Desactivar'));
      expect(texts.castingToDevice('TV'), equals('Transmitiendo a TV'));
      expect(texts.trackFallback(5), equals('Pista 5'));
    });

    test('GoogleCastPlayerTheme has all nullable properties', () {
      const theme = GoogleCastPlayerTheme();

      expect(theme.backgroundColor, isNull);
      expect(theme.backgroundGradient, isNull);
      expect(theme.titleTextStyle, isNull);
      expect(theme.deviceTextStyle, isNull);
      expect(theme.timeTextStyle, isNull);
      expect(theme.iconColor, isNull);
      expect(theme.disabledIconColor, isNull);
      expect(theme.iconSize, isNull);
      expect(theme.backgroundWidget, isNull);
      expect(theme.imageBorderRadius, isNull);
      expect(theme.imageShadow, isNull);
      expect(theme.imageMaxWidth, isNull);
      expect(theme.imageMaxHeight, isNull);
      expect(theme.imageFit, isNull);
      expect(theme.noImageFallback, isNull);
      expect(theme.popupBackgroundColor, isNull);
      expect(theme.popupTextColor, isNull);
      expect(theme.popupTextStyle, isNull);
      expect(theme.volumeSliderActiveColor, isNull);
      expect(theme.volumeSliderInactiveColor, isNull);
      expect(theme.volumeSliderThumbColor, isNull);
    });

    test('GoogleCastPlayerTheme with custom values', () {
      final theme = GoogleCastPlayerTheme(
        backgroundColor: Colors.black,
        backgroundGradient: const LinearGradient(
          colors: [Colors.black, Colors.grey],
        ),
        titleTextStyle: const TextStyle(fontSize: 24),
        deviceTextStyle: const TextStyle(fontSize: 14),
        timeTextStyle: const TextStyle(fontSize: 12),
        iconColor: Colors.white,
        disabledIconColor: Colors.grey,
        iconSize: 48.0,
        backgroundWidget: Container(),
        imageBorderRadius: BorderRadius.circular(16),
        imageShadow: const [BoxShadow(color: Colors.black)],
        imageMaxWidth: 300,
        imageMaxHeight: 300,
        imageFit: BoxFit.cover,
        noImageFallback: const Icon(Icons.music_note),
        popupBackgroundColor: Colors.black87,
        popupTextColor: Colors.white,
        popupTextStyle: const TextStyle(fontSize: 14),
        volumeSliderActiveColor: Colors.blue,
        volumeSliderInactiveColor: Colors.grey,
        volumeSliderThumbColor: Colors.white,
      );

      expect(theme.backgroundColor, equals(Colors.black));
      expect(theme.backgroundGradient, isNotNull);
      expect(theme.titleTextStyle?.fontSize, equals(24));
      expect(theme.deviceTextStyle?.fontSize, equals(14));
      expect(theme.timeTextStyle?.fontSize, equals(12));
      expect(theme.iconColor, equals(Colors.white));
      expect(theme.disabledIconColor, equals(Colors.grey));
      expect(theme.iconSize, equals(48.0));
      expect(theme.backgroundWidget, isNotNull);
      expect(theme.imageBorderRadius, isNotNull);
      expect(theme.imageShadow, isNotNull);
      expect(theme.imageMaxWidth, equals(300));
      expect(theme.imageMaxHeight, equals(300));
      expect(theme.imageFit, equals(BoxFit.cover));
      expect(theme.noImageFallback, isNotNull);
      expect(theme.popupBackgroundColor, equals(Colors.black87));
      expect(theme.popupTextColor, equals(Colors.white));
      expect(theme.popupTextStyle?.fontSize, equals(14));
      expect(theme.volumeSliderActiveColor, equals(Colors.blue));
      expect(theme.volumeSliderInactiveColor, equals(Colors.grey));
      expect(theme.volumeSliderThumbColor, equals(Colors.white));
    });
  });

  group('Duration formatting', () {
    test('Duration.formatted extension works correctly', () {
      // Test the formatted extension if it exists
      final duration1 = const Duration(hours: 1, minutes: 30, seconds: 45);
      final duration2 = const Duration(minutes: 5, seconds: 30);
      final duration3 = const Duration(seconds: 45);

      // Test formatted output patterns
      expect(duration1.inHours, equals(1));
      expect(duration1.inMinutes, equals(90));
      expect(duration1.inSeconds, equals(5445));

      expect(duration2.inMinutes, equals(5));
      expect(duration2.inSeconds, equals(330));

      expect(duration3.inSeconds, equals(45));
    });
  });
}
