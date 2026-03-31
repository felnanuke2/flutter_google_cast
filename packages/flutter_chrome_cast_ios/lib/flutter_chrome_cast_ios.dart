/// iOS implementation of the `flutter_chrome_cast` plugin.
///
/// Exposes the iOS platform implementations selected by the facade package
/// when `Platform.isIOS` is true.
/// implementations at runtime when `Platform.isIOS` is true.
library;

// ── iOS platform options ───────────────────────────────────────────────────
export 'src/models/ios/ios_cast_options.dart';

// ── iOS plugin registrant ─────────────────────────────────────────────────
export 'src/flutter_chrome_cast_ios_registrant.dart';

// ── iOS implementations ────────────────────────────────────────────────────
export 'src/channels/ios_google_cast_context_method_channel.dart';
export 'src/channels/ios_discovery_manager.dart';
export 'src/channels/ios_cast_session_manager.dart';
export 'src/channels/ios_remote_media_client_method_channel.dart';
