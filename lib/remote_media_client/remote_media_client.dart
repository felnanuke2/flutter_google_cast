import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class GoogleCastRemoteMediaClientPlatformInterface
    implements PlatformInterface {
  Future<GoogleCastRequest> loadMedia(GoogleCastMediaInformation mediaInfo);
}
