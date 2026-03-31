/// Platform interface for the `flutter_chrome_cast` plugin.
///
/// Contains all shared entity types, enumerations, common data classes,
/// and the four abstract platform interfaces that every platform
/// implementation must satisfy.
///
/// Platform package authors implement:
/// - [GoogleCastContextPlatformInterface]
/// - [GoogleCastDiscoveryManagerPlatformInterface]
/// - [GoogleCastSessionManagerPlatformInterface]
/// - [GoogleCastRemoteMediaClientPlatformInterface]
library flutter_chrome_cast_platform_interface;

// ── Enums ───────────────────────────────────────────────────────────────────
export 'src/enums/connection_state.dart';
export 'src/enums/idle_reason.dart';
export 'src/enums/media_metadata_type.dart';
export 'src/enums/media_resume_state.dart';
export 'src/enums/player_state.dart';
export 'src/enums/repeat_mode.dart';
export 'src/enums/stream_type.dart';
export 'src/enums/text_track_type.dart';
export 'src/enums/track_type.dart';

// ── Common types ────────────────────────────────────────────────────────────
export 'src/common/break.dart';
export 'src/common/break_clips.dart';
export 'src/common/cast_status_event.dart';
export 'src/common/font_generic_family.dart';
export 'src/common/hls_segment_format.dart';
export 'src/common/hls_video_segment_format.dart';
export 'src/common/image.dart';
export 'src/common/live_seekable_range.dart';
export 'src/common/queue_data.dart';
export 'src/common/rfc5646_language.dart';
export 'src/common/text_track_edge_type.dart';
export 'src/common/text_track_font_style.dart';
export 'src/common/text_track_style.dart';
export 'src/common/text_track_window_type.dart';
export 'src/common/user_action.dart';
export 'src/common/user_action_state.dart';
export 'src/common/vast_ads_request.dart';
export 'src/common/volume.dart';

// ── Entities ────────────────────────────────────────────────────────────────
export 'src/entities/break_status.dart';
export 'src/entities/cast_device.dart';
export 'src/entities/cast_media_status.dart';
export 'src/entities/cast_options.dart';
export 'src/entities/cast_session.dart';
export 'src/entities/device_volume.dart';
export 'src/entities/discovery_criteria.dart';
export 'src/entities/load_options.dart';
export 'src/entities/media_information.dart';
export 'src/entities/media_seek_option.dart';
export 'src/entities/queue_item.dart';
export 'src/entities/remote_media_requests.dart';
export 'src/entities/request.dart';
export 'src/entities/track.dart';
export 'src/entities/media_metadata/cast_media_metadata.dart';
export 'src/entities/media_metadata/generic_media_metadata.dart';
export 'src/entities/media_metadata/media_metadata.dart';
export 'src/entities/media_metadata/movie_media_metadata.dart';
export 'src/entities/media_metadata/music_track_media_metadata.dart';
export 'src/entities/media_metadata/photo_media_metadata.dart';
export 'src/entities/media_metadata/tv_show_media_metadata.dart';

// ── Platform interfaces ──────────────────────────────────────────────────────
export 'src/platforms/google_cast_context_platform.dart';
export 'src/platforms/discovery_manager_platform.dart';
export 'src/platforms/cast_session_manager_platform.dart';
export 'src/platforms/remote_media_client_platform.dart';

// ── Pigeon APIs ──────────────────────────────────────────────────────────────
export 'src/pigeon/google_cast_context_pigeon.g.dart';
export 'src/pigeon/cast_manager_pigeon.g.dart' hide wrapResponse;
export 'src/pigeon/remote_media_client_pigeon.g.dart' hide wrapResponse;

