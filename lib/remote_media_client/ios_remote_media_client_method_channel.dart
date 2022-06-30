import 'package:google_cast/entities/cast_media_status.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/media_seek_option.dart';
import 'package:google_cast/entities/request.dart';
import 'package:google_cast/remote_media_client/remote_media_client.dart';

abstract class GoogleCastIOSRemoteMediaClientMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  GoggleCastMediaStatus? get mediaStatus;

  Stream<GoggleCastMediaStatus?> get mediaStatusStream;

  Duration get playerPosition;

  Stream<Duration> get playerPositionStream;

  @override
  Future<GoogleCastRequest?> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  });

  Future<GoogleCastRequest> setPlaybackRate(double rate);

  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs);

  Future<GoogleCastRequest> setTextTrackStyle(TextTrackStyle textTrackStyle);

  Future<GoogleCastRequest> pause();

  Future<GoogleCastRequest> play();

  Future<GoogleCastRequest> stop();

  Future<GoogleCastRequest> queueNextItem();

  Future<GoogleCastRequest> queuePrevItem();

  Future<GoogleCastRequest> seek(GoogleCastMediaSeekOption option);
}
