import 'package:flutter/services.dart';
import 'package:google_cast/entities/request.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/models/ios/ios_media_information.dart';
import 'package:google_cast/models/ios/ios_request.dart';
import 'package:google_cast/remote_media_client/ios_remote_media_client_method_channel.dart';

class GoogleCastIOSRemoteMediaClient
    extends GoogleCastIOSRemoteMediaClientMethodChannel {
  final _channel = const MethodChannel('google_cast.remote_media_client');

  @override
  Future<GoogleCastRequest> loadMedia(
      GoogleCastMediaInformation mediaInfo) async {
    mediaInfo as GoogleCastIOSMediaInformation;
    final result = await _channel.invokeMethod('loadMedia', mediaInfo.toMap());
    return GoogleCastIosRequest.fromMap(Map<String, dynamic>.from(result));
  }

  @override
  Future<GoogleCastRequest> pause() {
    // TODO: implement pause
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> play() {
    // TODO: implement play
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setActiveTrackIDs(List<int> activeTrackIDs) {
    // TODO: implement setActiveTrackIDs
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setPlaybackRate(double rate) {
    // TODO: implement setPlaybackRate
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> setTextTrackStyle(TextTrackStyle textTrackStyle) {
    // TODO: implement setTextTrackStyle
    throw UnimplementedError();
  }

  @override
  Future<GoogleCastRequest> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }
}
