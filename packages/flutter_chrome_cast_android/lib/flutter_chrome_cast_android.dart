/// Android implementation of the `flutter_chrome_cast` plugin.
///
/// Exposes the Android platform implementations selected by the facade package
/// when `Platform.isAndroid` is true.
/// implementations at runtime when `Platform.isAndroid` is true.
library;

// ── Android platform options ───────────────────────────────────────────────
export 'src/models/android/android_cast_options.dart';

// ── Android plugin registrant ─────────────────────────────────────────────
export 'src/flutter_chrome_cast_android_registrant.dart';

// ── Android implementations ───────────────────────────────────────────────
export 'src/channels/android_google_cast_context_method_channel.dart';
export 'src/channels/android_discovery_manager.dart';
export 'src/channels/android_cast_session_manager.dart';
export 'src/channels/android_remote_media_client_method_channel.dart';
