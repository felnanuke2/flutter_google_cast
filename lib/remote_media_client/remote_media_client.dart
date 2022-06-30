import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GoogleCastRemoteMediaClientPlatformInterface
    implements PlatformInterface {
  Future<GoogleCastRequest?> loadMedia(
    GoogleCastMediaInformation mediaInfo, {
    bool autoPlay = true,
    Duration playPosition = Duration.zero,
    double playbackRate = 1.0,
    List<int>? activeTrackIds,
    String? credentials,
    String? credentialsType,
  });
}
