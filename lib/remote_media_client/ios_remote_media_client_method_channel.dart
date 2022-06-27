import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/request.dart';
import 'package:google_cast/remote_media_client/remote_media_client.dart';

abstract class GoogleCastIOSRemoteMediaClientMethodChannel
    implements GoogleCastRemoteMediaClientPlatformInterface {
  @override
  Future<GoogleCastRequest> loadMedia(GoogleCastMediaInformation mediaInfo);

  Future<GoogleCastRequest> setPlaybackRate(double rate);

  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs);

  Future<GoogleCastRequest> setTextTrackStyle(TextTrackStyle textTrackStyle);

  Future<GoogleCastRequest> pause();

  Future<GoogleCastRequest> play();

  Future<GoogleCastRequest> stop();
}
