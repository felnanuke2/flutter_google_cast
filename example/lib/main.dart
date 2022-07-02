import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_cast/lib.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    GoogleCastOptions? options;
    if (Platform.isIOS) {
      options = IOSGoogleCastOptions(
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
            GoogleCastDiscoveryCriteria.kDefaultApplicationId),
      );
    } else if (Platform.isAndroid) {
      options = GoogleCastOptionsAndroid(
        appId: GoogleCastDiscoveryCriteria.kDefaultApplicationId,
      );
    }
    GoogleCastContext.instance.setSharedInstanceWithOptions(options!);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Platform.isAndroid
          ? Scaffold(
              body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text('Android not supported'),
              ],
            ))
          : Scaffold(
              floatingActionButton: Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: StreamBuilder(
                    stream:
                        GoogleCastSessionManager.instance.currentSessionStream,
                    builder: (context, snapshot) {
                      final isConnected =
                          GoogleCastSessionManager.instance.connectionState ==
                              GoogleCastConnectState.ConnectionStateConnected;
                      return Visibility(
                        visible: isConnected,
                        child: FloatingActionButton(
                          onPressed: _insertQueueItemAndPlay,
                          child: const Icon(Icons.add),
                        ),
                      );
                    }),
              ),
              appBar: AppBar(
                title: const Text('Plugin example app'),
                actions: [
                  StreamBuilder<GoogleCastSession?>(
                      stream: GoogleCastSessionManager
                          .instance.currentSessionStream,
                      builder: (context, snapshot) {
                        final bool isConnected =
                            GoogleCastSessionManager.instance.connectionState ==
                                GoogleCastConnectState.ConnectionStateConnected;
                        return IconButton(
                            onPressed: GoogleCastSessionManager
                                .instance.endSessionAndStopCasting,
                            icon: Icon(isConnected
                                ? Icons.cast_connected
                                : Icons.cast));
                      })
                ],
              ),
              body: StreamBuilder<List<GoogleCastDevice>>(
                stream: GoogleCastDiscoveryManager.instance.devicesStream,
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
                                onTap: () => _loadQueue(device),
                              );
                            })
                          ],
                        ),
                      ),
                      StreamBuilder<GoggleCastMediaStatus?>(
                          stream: GoogleCastRemoteMediaClient
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
                                        stream: GoogleCastRemoteMediaClient
                                            .instance.playerPositionStream,
                                        builder: (context, snapshot) {
                                          final progress =
                                              snapshot.data ?? Duration.zero;
                                          print(progress);
                                          print(mediaDuration);
                                          var percent =
                                              progress.inMilliseconds /
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
                                      GoogleCastRemoteMediaClient.instance
                                                  .mediaStatus?.playerState ==
                                              CastMediaPlayerState.playing
                                          ? Icons.pause
                                          : Icons.play_arrow,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: !GoogleCastRemoteMediaClient
                                            .instance.queueHasPreviousItem
                                        ? null
                                        : _previous,
                                    icon: const Icon(Icons.skip_previous),
                                  ),
                                  IconButton(
                                    onPressed: !GoogleCastRemoteMediaClient
                                            .instance.queueHasNextItem
                                        ? null
                                        : _next,
                                    icon: const Icon(Icons.skip_next),
                                  ),
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
    final seconds = GoogleCastRemoteMediaClient
            .instance.mediaStatus?.mediaInformation?.duration?.inSeconds ??
        0;
    final position = (value * seconds).floor();
    GoogleCastRemoteMediaClient.instance
        .seek(GoogleCastMediaSeekOption(position: Duration(seconds: position)));
  }

  void _togglePLayPause() {
    final isPlaying =
        GoogleCastRemoteMediaClient.instance.mediaStatus?.playerState ==
            CastMediaPlayerState.playing;
    if (isPlaying) {
      GoogleCastRemoteMediaClient.instance.pause();
    } else {
      GoogleCastRemoteMediaClient.instance.play();
    }
  }

  void _loadMedia(GoogleCastDevice device) async {
    await GoogleCastSessionManager.instance.startSessionWithDevice(device);

    GoogleCastRemoteMediaClient.instance.loadMedia(
      GoogleCastMediaInformationIOS(
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
            language: RFC5646_LANGUAGE.PORTUGUESE_BRAZIL,
            subtype: TextTrackType.SUBTITLES,
          ),
        ],
      ),
      autoPlay: true,
      playPosition: const Duration(seconds: 0),
      playbackRate: 2,
      activeTrackIds: [0],
    );
  }

  _loadQueue(GoogleCastDevice device) async {
    await GoogleCastSessionManager.instance.startSessionWithDevice(device);
    await GoogleCastRemoteMediaClient.instance.queueLoadItems(
      [
        GoogleCastQueueItem(
          activeTrackIds: [0],
          mediaInformation: GoogleCastMediaInformationIOS(
            contentId: '0',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(
                    'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4')
                .toString(),
            contentType: 'video/mp4',
            metadata: GoogleCastMovieMediaMetadata(
              title: 'The first Blender Open Movie from 2006',
              studio: 'Blender Inc',
              releaseDate: DateTime(2011),
              subtitle:
                  'Song : Raja Raja Kareja Mein Samaja\nAlbum : Raja Kareja Mein Samaja\nArtist : Radhe Shyam Rasia\nSinger : Radhe Shyam Rasia\nMusic Director : Sohan Lal, Dinesh Kumar\nLyricist : Vinay Bihari, Shailesh Sagar, Parmeshwar Premi\nMusic Label : T-Series',
              images: [
                GoogleCastImage(
                  url: Uri.parse(
                      'https://i.ytimg.com/vi_webp/gWw23EYM9VM/maxresdefault.webp'),
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
                language: RFC5646_LANGUAGE.PORTUGUESE_BRAZIL,
                subtype: TextTrackType.SUBTITLES,
              ),
            ],
          ),
        ),
        GoogleCastQueueItem(
          preLoadTime: const Duration(seconds: 15),
          mediaInformation: GoogleCastMediaInformationIOS(
            contentId: '1',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(
                    'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4')
                .toString(),
            contentType: 'video/mp4',
            metadata: GoogleCastMovieMediaMetadata(
              title: 'Big Buck Bunny',
              releaseDate: DateTime(2011),
              studio: 'Vlc Media Player',
              images: [
                GoogleCastImage(
                  url: Uri.parse(
                      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'),
                  height: 480,
                  width: 854,
                ),
              ],
            ),
          ),
        ),
      ],
      options: GoogleCastQueueLoadOptions(
        startIndex: 0,
        playPosition: const Duration(seconds: 30),
      ),
    );
  }

  void _previous() {
    GoogleCastRemoteMediaClient.instance.queuePrevItem();
  }

  void _next() {
    GoogleCastRemoteMediaClient.instance.queueNextItem();
  }

  void _insertQueueItem() {
    GoogleCastRemoteMediaClient.instance.queueInsertItems(
      [
        GoogleCastQueueItem(
          preLoadTime: const Duration(seconds: 15),
          mediaInformation: GoogleCastMediaInformationIOS(
            contentId: '3',
            streamType: CastMediaStreamType.BUFFERED,
            contentUrl: Uri.parse(
                    'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4')
                .toString(),
            contentType: 'video/mp4',
            metadata: GoogleCastMovieMediaMetadata(
              title: 'For Bigger Blazes',
              subtitle:
                  'Song : Raja Raja Kareja Mein Samaja\nAlbum : Raja Kareja Mein Samaja\nArtist : Radhe Shyam Rasia\nSinger : Radhe Shyam Rasia\nMusic Director : Sohan Lal, Dinesh Kumar\nLyricist : Vinay Bihari, Shailesh Sagar, Parmeshwar Premi\nMusic Label : T-Series',
              releaseDate: DateTime(2011),
              studio: 'T-Series Regional',
              images: [
                GoogleCastImage(
                  url: Uri.parse(
                      'https://i.ytimg.com/vi/Dr9C2oswZfA/maxresdefault.jpg'),
                  height: 480,
                  width: 854,
                ),
              ],
            ),
          ),
        )
      ],
      beforeItemWithId: 2,
    );
  }

  void _insertQueueItemAndPlay() {
    GoogleCastRemoteMediaClient.instance.queueInsertItemAndPlay(
      GoogleCastQueueItem(
        preLoadTime: const Duration(seconds: 15),
        mediaInformation: GoogleCastMediaInformationIOS(
          contentId: '3',
          streamType: CastMediaStreamType.BUFFERED,
          contentUrl: Uri.parse(
                  'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4')
              .toString(),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: 'For Bigger Blazes',
            subtitle:
                'Song : Raja Raja Kareja Mein Samaja\nAlbum : Raja Kareja Mein Samaja\nArtist : Radhe Shyam Rasia\nSinger : Radhe Shyam Rasia\nMusic Director : Sohan Lal, Dinesh Kumar\nLyricist : Vinay Bihari, Shailesh Sagar, Parmeshwar Premi\nMusic Label : T-Series',
            releaseDate: DateTime(2011),
            studio: 'T-Series Regional',
            images: [
              GoogleCastImage(
                url: Uri.parse(
                    'https://i.ytimg.com/vi/Dr9C2oswZfA/maxresdefault.jpg'),
                height: 480,
                width: 854,
              ),
            ],
          ),
        ),
      ),
      beforeItemWithId: 2,
    );
  }
}
