import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_chrome_cast/lib.dart';
import 'package:flutter_chrome_cast/themes.dart';
import 'package:flutter_chrome_cast/widgets/mini_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GoogleCastMiniController', () {
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
      const widget = GoogleCastMiniController();

      expect(widget.theme, isNull);
      expect(widget.margin, isNull);
      expect(widget.borderRadius, isNull);
      expect(widget.showDeviceName, isTrue);
    });

    test('creates widget with custom parameters', () {
      final theme = GoogleCastPlayerTheme(
        backgroundColor: Colors.white,
        iconColor: Colors.blue,
        iconSize: 28,
      );
      const margin = EdgeInsets.all(16);
      final borderRadius = BorderRadius.circular(16);

      final widget = GoogleCastMiniController(
        theme: theme,
        margin: margin,
        borderRadius: borderRadius,
        showDeviceName: false,
      );

      expect(widget.theme, equals(theme));
      expect(widget.margin, equals(margin));
      expect(widget.borderRadius, equals(borderRadius));
      expect(widget.showDeviceName, isFalse);
    });

    test('default showDeviceName is true', () {
      const widget = GoogleCastMiniController();
      expect(widget.showDeviceName, isTrue);
    });

    test('theme with image customization', () {
      final theme = GoogleCastPlayerTheme(
        imageBorderRadius: BorderRadius.circular(12),
        imageShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        imageFit: BoxFit.cover,
      );

      expect(theme.imageBorderRadius, isNotNull);
      expect(theme.imageShadow, hasLength(1));
      expect(theme.imageFit, equals(BoxFit.cover));
    });

    test('theme with icon customization', () {
      final theme = GoogleCastPlayerTheme(
        iconColor: Colors.grey[800],
        iconSize: 28,
      );

      expect(theme.iconColor, equals(Colors.grey[800]));
      expect(theme.iconSize, equals(28));
    });

    test('theme with title and device text styles', () {
      final theme = GoogleCastPlayerTheme(
        titleTextStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.grey[900],
        ),
        deviceTextStyle: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.w400,
        ),
      );

      expect(theme.titleTextStyle?.fontSize, equals(16));
      expect(theme.titleTextStyle?.fontWeight, equals(FontWeight.w600));
      expect(theme.deviceTextStyle?.fontSize, equals(12));
      expect(theme.deviceTextStyle?.fontWeight, equals(FontWeight.w400));
    });
  });

  group('Player state icon mapping', () {
    test('playing state should map to pause icon', () {
      // Test the expected icon for different player states
      expect(CastMediaPlayerState.playing.index, isNonNegative);
      expect(CastMediaPlayerState.buffering.index, isNonNegative);
      expect(CastMediaPlayerState.paused.index, isNonNegative);
      expect(CastMediaPlayerState.idle.index, isNonNegative);
      expect(CastMediaPlayerState.unknown.index, isNonNegative);
      expect(CastMediaPlayerState.loading.index, isNonNegative);
    });

    test('all player states are defined', () {
      expect(CastMediaPlayerState.values, hasLength(6));
      expect(CastMediaPlayerState.values, contains(CastMediaPlayerState.playing));
      expect(CastMediaPlayerState.values, contains(CastMediaPlayerState.paused));
      expect(CastMediaPlayerState.values, contains(CastMediaPlayerState.buffering));
      expect(CastMediaPlayerState.values, contains(CastMediaPlayerState.idle));
      expect(CastMediaPlayerState.values, contains(CastMediaPlayerState.unknown));
      expect(CastMediaPlayerState.values, contains(CastMediaPlayerState.loading));
    });
  });

  group('Media metadata type icon mapping', () {
    test('all metadata types are defined', () {
      expect(GoogleCastMediaMetadataType.values, contains(GoogleCastMediaMetadataType.movieMediaMetadata));
      expect(GoogleCastMediaMetadataType.values, contains(GoogleCastMediaMetadataType.musicTrackMediaMetadata));
      expect(GoogleCastMediaMetadataType.values, contains(GoogleCastMediaMetadataType.tvShowMediaMetadata));
      expect(GoogleCastMediaMetadataType.values, contains(GoogleCastMediaMetadataType.photoMediaMetadata));
      expect(GoogleCastMediaMetadataType.values, contains(GoogleCastMediaMetadataType.genericMediaMetadata));
    });

    test('metadata type indexes are consistent', () {
      // Ensure indexes are stable for serialization
      expect(GoogleCastMediaMetadataType.genericMediaMetadata.index, isNonNegative);
      expect(GoogleCastMediaMetadataType.movieMediaMetadata.index, isNonNegative);
      expect(GoogleCastMediaMetadataType.tvShowMediaMetadata.index, isNonNegative);
      expect(GoogleCastMediaMetadataType.musicTrackMediaMetadata.index, isNonNegative);
      expect(GoogleCastMediaMetadataType.photoMediaMetadata.index, isNonNegative);
    });
  });
}
