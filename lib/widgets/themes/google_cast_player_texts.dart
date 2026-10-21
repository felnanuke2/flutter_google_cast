/// Text configuration for customizing text labels in the ExpandedGoogleCastPlayerController widget.
///
/// This class allows you to customize all text content displayed in the expanded player,
/// making it easy to support internationalization or custom branding.
///
/// Example usage:
/// ```dart
/// ExpandedGoogleCastPlayerController(
///   texts: ExpandedGoogleCastPlayerTexts(
///     nowPlaying: 'Reproduciendo ahora',
///     unknownTitle: 'Título desconocido',
///     castingToDevice: (deviceName) => 'Transmitiendo a $deviceName',
///     noCaptionsAvailable: 'Sin subtítulos disponibles',
///     captionsOff: 'Desactivar',
///     trackFallback: (trackId) => 'Pista $trackId',
///   ),
/// )
/// ```
class GoogleCastPlayerTexts {
  /// Text displayed when media title is unknown or empty
  final String unknownTitle;

  /// Text displayed in the app bar header
  final String nowPlaying;

  /// Function that returns text showing which device is being cast to.
  /// The [deviceName] parameter contains the friendly name of the cast device.
  final String Function(String deviceName) castingToDevice;

  /// Text displayed when no caption tracks are available
  final String noCaptionsAvailable;

  /// Text displayed for the option to turn off captions
  final String captionsOff;

  /// Function that returns fallback text for caption track names.
  /// The [trackId] parameter contains the numeric ID of the track.
  final String Function(int trackId) trackFallback;

  /// Accessibility label for the collapse/dismiss button
  final String collapsePlayer;

  /// Accessibility label for the cast/disconnect button
  final String disconnectCast;

  /// Accessibility label for the play button
  final String play;

  /// Accessibility label for the pause button
  final String pause;

  /// Accessibility label for the previous track button
  final String previousTrack;

  /// Accessibility label for the next track button
  final String nextTrack;

  /// Accessibility label for the seek backward button
  final String seekBackward30;

  /// Accessibility label for the seek forward button
  final String seekForward30;

  /// Accessibility label for the captions button
  final String captions;

  /// Accessibility label for the drag-to-dismiss handle
  final String dragToDismiss;

  /// Accessibility label for the playback slider
  final String playbackPosition;

  /// Accessibility label for the media artwork image
  final String mediaArtwork;

  /// Creates a new [GoogleCastPlayerTexts].
  const GoogleCastPlayerTexts({
    this.unknownTitle = 'Unknown Title',
    this.nowPlaying = 'Now Playing',
    this.castingToDevice = _defaultCastingToDevice,
    this.noCaptionsAvailable = 'No captions available',
    this.captionsOff = 'Off',
    this.trackFallback = _defaultTrackFallback,
    this.collapsePlayer = 'Collapse player',
    this.disconnectCast = 'Disconnect',
    this.play = 'Play',
    this.pause = 'Pause',
    this.previousTrack = 'Previous track',
    this.nextTrack = 'Next track',
    this.seekBackward30 = 'Seek backward 30 seconds',
    this.seekForward30 = 'Seek forward 30 seconds',
    this.captions = 'Captions',
    this.dragToDismiss = 'Drag down to dismiss',
    this.playbackPosition = 'Playback position',
    this.mediaArtwork = 'Media artwork',
  });

  static String _defaultCastingToDevice(String deviceName) =>
      'Casting to $deviceName';
  static String _defaultTrackFallback(int trackId) => 'Track $trackId';
}
