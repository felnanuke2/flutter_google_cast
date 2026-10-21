/// Working sample media URLs for the example app.
///
/// All URLs have been verified as publicly accessible (HTTP 200) and support
/// range requests for seeking on Chromecast devices.
class MediaUrls {
  MediaUrls._();

  // ── Videos ────────────────────────────────────────────────────────────────

  /// Big Buck Bunny – full short film (~62 MB, MP4/H.264).
  /// Source: Blender Foundation https://peach.blender.org
  static const bigBuckBunnyVideo =
      'https://download.blender.org/peach/bigbuckbunny_movies/BigBuckBunny_320x180.mp4';

  /// Sintel – official trailer (~4 MB, MP4/H.264).
  /// Source: Blender Foundation https://durian.blender.org
  static const sintelTrailerVideo =
      'https://download.blender.org/durian/trailer/sintel_trailer-480p.mp4';

  /// Big Buck Bunny – 10-second 720p clip (~1 MB, MP4/H.264).
  /// Source: https://test-videos.co.uk
  static const bigBuckBunnyShortClip =
      'https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/720/Big_Buck_Bunny_720_10s_1MB.mp4';

  /// Apple HLS advanced adaptive-streaming example (fMP4 + TS).
  /// Source: Apple Developer https://developer.apple.com/streaming/examples
  static const appleHlsSample =
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8';

  // ── Images / Thumbnails ───────────────────────────────────────────────────

  /// Big Buck Bunny official splash art.
  /// Source: https://peach.blender.org
  static const bigBuckBunnySplash =
      'https://peach.blender.org/wp-content/uploads/bbb-splash.png';

  /// Big Buck Bunny opening screen (Wikimedia Commons).
  static const bigBuckBunnyOpeningScreen =
      'https://upload.wikimedia.org/wikipedia/commons/7/70/Big.Buck.Bunny.-.Opening.Screen.png';

  /// Elephants Dream – Proog character (Wikimedia Commons).
  static const elephantsDreamPoster =
      'https://upload.wikimedia.org/wikipedia/commons/9/90/Elephants_Dream_s1_proog.jpg';

  // ── Subtitles ─────────────────────────────────────────────────────────────

  /// VTT subtitles for Elephants Dream (English).
  /// Source: GitHub – felnanuke2/flutter_cast
  static const elephantsDreamSubtitles =
      'https://raw.githubusercontent.com/felnanuke2/flutter_cast/master/example/assets/VEED-subtitles_Blender_Foundation_-_Elephants_Dream_1024.vtt';
}
