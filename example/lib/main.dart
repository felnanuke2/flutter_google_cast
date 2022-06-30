import 'package:flutter/material.dart';
import 'package:google_cast/common/image.dart';
import 'package:google_cast/common/rfc5646_language.dart';
import 'package:google_cast/common/text_track_type.dart';
import 'package:google_cast/common/track_type.dart';
import 'package:google_cast/discovery_criteria.dart/discovery_criteria.dart';
import 'package:google_cast/entities/cast_device.dart';
import 'package:google_cast/entities/cast_media_status.dart';
import 'package:google_cast/entities/cast_session.dart';
import 'package:google_cast/entities/media_information.dart';
import 'package:google_cast/entities/media_metadata/tv_show_media_metadata.dart';
import 'package:google_cast/entities/media_seek_option.dart';
import 'package:google_cast/enums/connection_satate.dart';
import 'package:google_cast/enums/player_state.dart';
import 'dart:async';
import 'package:google_cast/google_cast.dart';
import 'package:google_cast/google_cast_context/google_cast_context.dart';
import 'package:google_cast/google_cast_context/google_cast_context_method_channel.dart';
import 'package:google_cast/google_cast_options/ios_cast_options.dart';
import 'package:google_cast/models/ios/ios_media_information.dart';
import 'package:google_cast/remote_media_client/ios_remote_media_client.dart';
import 'package:google_cast/remote_media_client/remote_media_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  final _googleCastPlugin = GoogleCast();

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    FlutterGoogleCastContext.setSharedInstanceWithOptions(IOSGoogleCastOptions(
      GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
        AGoogleCastDiscoveryCriteria.kDefaultApplicationId,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
            actions: [
              StreamBuilder<GoogleCastSession?>(
                  stream: FlutterIOSGoogleCastContextMethodChannel
                      .instance.sessionManager.currentSessionStream,
                  builder: (context, snapshot) {
                    final bool isConnected =
                        FlutterIOSGoogleCastContextMethodChannel
                                .instance.sessionManager.connectionState ==
                            GoogleCastConnectState.ConnectionStateConnected;
                    return IconButton(
                        onPressed: FlutterIOSGoogleCastContextMethodChannel
                            .instance.sessionManager.endSessionAndStopCasting,
                        icon: Icon(
                            isConnected ? Icons.cast_connected : Icons.cast));
                  })
            ],
          ),
          body: StreamBuilder<List<GoogleCastDevice>>(
            stream:
                FlutterIOSGoogleCastContextMethodChannel.instance.devicesStream,
            builder: (context, snapshot) {
              final devices = snapshot.data ?? [];
              return Column(
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        ...devices.map((device) {
                          return ListTile(
                            title: Text(device.friendlyName),
                            subtitle: Text(device.modelName ?? ''),
                            onTap: () async {
                              await FlutterIOSGoogleCastContextMethodChannel
                                  .instance.sessionManager
                                  .startSessionWithDevice(device);

                              FlutterIOSGoogleCastContextMethodChannel
                                  .instance
                                  .sessionManager
                                  .currentSession
                                  ?.remoteMediaClient
                                  .loadMedia(
                                GoogleCastIOSMediaInformation(
                                  contentId: '',
                                  streamType: CastMediaStreamType.BUFFERED,
                                  contentUrl: Uri.parse(
                                          'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4')
                                      .toString(),
                                  contentType: 'video/mp4',
                                  metadata: GoogleCastTvShowMediaMetadata(
                                    episode: 1,
                                    season: 2,
                                    seriesTitle: 'Big Buck Bunny',
                                    originalAirDate: DateTime.now(),
                                    images: [
                                      GoogleCastImage(
                                        url: Uri.parse(
                                            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'),
                                        height: 480,
                                        width: 854,
                                      ),
                                    ],
                                  ),
                                  tracks: [
                                    GoogleCastMediaTrack(
                                      trackId: 0,
                                      type: TrackType.TEXT,
                                      trackContentId: Uri.parse(
                                              'https://raw.githubusercontent.com/felnanuke2/flutter_cast/master/example/assets/VEED-subtitles_Blender_Foundation_-_Elephants_Dream_1024.vtt')
                                          .toString(),
                                      trackContentType: 'text/vtt',
                                      name: 'English',
                                      language:
                                          RFC5646_LANGUAGE.PORTUGUESE_BRAZIL,
                                      subtype: TextTrackType.SUBTITLES,
                                    ),
                                  ],
                                ),
                                autoPlay: true,
                                playPosition: const Duration(seconds: 0),
                                playbackRate: 2,
                                activeTrackIds: [0],
                              );
                            },
                          );
                        })
                      ],
                    ),
                  ),
                  StreamBuilder<GoggleCastMediaStatus?>(
                      stream: GoogleCastIOSRemoteMediaClient
                          .instance.mediaStatusStream,
                      builder: (context, snapshot) {
                        if (snapshot.data == null) return Container();
                        final mediaDuration =
                            snapshot.data?.mediaInformation?.duration ??
                                Duration.zero;

                        return Card(
                          child: Row(
                            children: [
                              Expanded(
                                child: StreamBuilder<Duration>(
                                    stream: GoogleCastIOSRemoteMediaClient
                                        .instance.playerPositionStream,
                                    builder: (context, snapshot) {
                                      final progress =
                                          snapshot.data ?? Duration.zero;
                                      print(progress);
                                      print(mediaDuration);
                                      var percent = progress.inMilliseconds /
                                          mediaDuration.inMilliseconds;
                                      if (percent.toString() == 'NaN') {
                                        percent = 0;
                                      }
                                      if (percent > 1 || percent < 0) {
                                        percent = 0;
                                      }
                                      return Slider(
                                        value: percent,
                                        onChanged: _changeCurrentTime,
                                      );
                                    }),
                              ),
                              IconButton(
                                  onPressed: _togglePLayPause,
                                  icon: Icon(
                                    GoogleCastIOSRemoteMediaClient.instance
                                                .mediaStatus?.playerState ==
                                            CastMediaPlayerState.playing
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                  ))
                            ],
                          ),
                        );
                      })
                ],
              );
            },
          )),
    );
  }

  void _changeCurrentTime(double value) {
    final seconds = GoogleCastIOSRemoteMediaClient
            .instance.mediaStatus?.mediaInformation?.duration?.inSeconds ??
        0;
    final position = (value * seconds).floor();

    (FlutterIOSGoogleCastContextMethodChannel
            .instance
            .sessionManager
            .currentSession
            ?.remoteMediaClient as GoogleCastIOSRemoteMediaClient)
        .seek(GoogleCastMediaSeekOption(position: Duration(seconds: position)));
  }

  void _togglePLayPause() {
    final isPlaying =
        GoogleCastIOSRemoteMediaClient.instance.mediaStatus?.playerState ==
            CastMediaPlayerState.playing;
    if (isPlaying) {
      GoogleCastIOSRemoteMediaClient.instance.pause();
    } else {
      GoogleCastIOSRemoteMediaClient.instance.play();
    }
  }
}
