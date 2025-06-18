import 'dart:io';
import 'package:flutter/material.dart';
// New modular import structure - import only what you need
import 'package:flutter_chrome_cast/cast_context.dart';
import 'package:flutter_chrome_cast/discovery.dart';
import 'package:flutter_chrome_cast/session.dart';
import 'package:flutter_chrome_cast/media.dart';
import 'package:flutter_chrome_cast/themes.dart';
import 'package:flutter_chrome_cast/widgets.dart';
import 'package:flutter_chrome_cast/entities.dart';
import 'package:flutter_chrome_cast/enums.dart';
import 'package:flutter_chrome_cast/models.dart';
import 'package:flutter_chrome_cast/common.dart';
// For ExpandedGoogleCastPlayerController and customizable texts
// Alternative: import everything at once
// import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDiscoveryActive = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
    GoogleCastOptions? options;
    if (Platform.isIOS) {
      options = IOSGoogleCastOptions(
        GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId),
      );
    } else if (Platform.isAndroid) {
      options = GoogleCastOptionsAndroid(
        appId: appId,
      );
    }
    GoogleCastContext.instance.setSharedInstanceWithOptions(options!);

    // Check initial discovery state for iOS
    if (Platform.isIOS) {
      try {
        final isActive = await GoogleCastDiscoveryManager.instance
            .isDiscoveryActiveForDeviceCategory(appId);
        setState(() {
          _isDiscoveryActive = isActive;
        });
      } catch (e) {
        // Handle error silently or log it
        debugPrint('Error checking discovery state: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Stack(
        children: [
          Scaffold(
              key: _scaffoldKey,
              floatingActionButton: Container(
                margin: const EdgeInsets.only(bottom: 40),
                child: StreamBuilder(
                    stream:
                        GoogleCastSessionManager.instance.currentSessionStream,
                    builder: (context, snapshot) {
                      final isConnected =
                          GoogleCastSessionManager.instance.connectionState ==
                              GoogleCastConnectState.connected;
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
                                GoogleCastConnectState.connected;
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
                      // Discovery Control Section
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Discovery Status Indicator
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: _isDiscoveryActive
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: _isDiscoveryActive
                                      ? Colors.green
                                      : Colors.grey,
                                  width: 2.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 12.0,
                                    height: 12.0,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isDiscoveryActive
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      _isDiscoveryActive
                                          ? devices.isEmpty
                                              ? 'Discovery Active - Searching for devices...'
                                              : 'Discovery Active - Found ${devices.length} device${devices.length == 1 ? '' : 's'}'
                                          : 'Discovery Stopped',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isDiscoveryActive
                                            ? Colors.green.shade700
                                            : Colors.grey.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  if (_isDiscoveryActive) ...[
                                    const SizedBox(width: 8.0),
                                    SizedBox(
                                      width: 16.0,
                                      height: 16.0,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16.0),
                            // Discovery Control Buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  onPressed: _isDiscoveryActive
                                      ? null
                                      : _startDiscovery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isDiscoveryActive
                                        ? Colors.grey
                                        : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Start Discovery'),
                                ),
                                ElevatedButton(
                                  onPressed: !_isDiscoveryActive
                                      ? null
                                      : _stopDiscovery,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_isDiscoveryActive
                                        ? Colors.grey
                                        : Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Stop Discovery'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Examples Section
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Player Examples',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                // Customizable Texts Examples
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTexts(
                                      context, _englishTexts, 'English'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue),
                                  child: const Text('English Player',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTexts(
                                      context, _spanishTexts, 'Spanish'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange),
                                  child: const Text('Spanish Player',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTexts(
                                      context, _frenchTexts, 'French'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple),
                                  child: const Text('French Player',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTexts(context,
                                      _customBrandingTexts, 'Custom Branding'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  child: const Text('Custom Player',
                                      style: TextStyle(color: Colors.white)),
                                ),

                                // Theme Examples
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTheme(
                                      context, _darkTheme, 'Dark Theme'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black87),
                                  child: const Text('Dark Theme',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTheme(context,
                                      _colorfulTheme, 'Colorful Theme'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.pink),
                                  child: const Text('Colorful Theme',
                                      style: TextStyle(color: Colors.white)),
                                ),
                                ElevatedButton(
                                  onPressed: () => _showPlayerWithTheme(context,
                                      _minimalistTheme, 'Minimal Theme'),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[300]),
                                  child: const Text('Minimal Theme',
                                      style: TextStyle(color: Colors.black)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(),

                      // Device List Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'Available Cast Devices (${devices.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          children: [
                            ...devices.map((device) {
                              return StreamBuilder<GoogleCastSession?>(
                                stream: GoogleCastSessionManager
                                    .instance.currentSessionStream,
                                builder: (context, sessionSnapshot) {
                                  final currentSession = sessionSnapshot.data;
                                  final isConnectedToThisDevice =
                                      currentSession?.device?.deviceID ==
                                          device.deviceID;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    elevation: isConnectedToThisDevice ? 4 : 1,
                                    color: isConnectedToThisDevice
                                        ? Colors.blue.shade50
                                        : null,
                                    child: ListTile(
                                      title: Text(
                                        device.friendlyName,
                                        style: TextStyle(
                                          fontWeight: isConnectedToThisDevice
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(device.modelName ?? ''),
                                          if (isConnectedToThisDevice)
                                            Text(
                                              'Connected',
                                              style: TextStyle(
                                                color: Colors.green.shade600,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      ),
                                      leading: Icon(
                                        isConnectedToThisDevice
                                            ? Icons.cast_connected
                                            : Icons.cast,
                                        color: isConnectedToThisDevice
                                            ? Colors.blue
                                            : null,
                                      ),
                                      trailing: isConnectedToThisDevice
                                          ? Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                      Icons.play_arrow),
                                                  onPressed: () =>
                                                      _loadAndPlayMedia(),
                                                  tooltip: 'Play Media',
                                                  color: Colors.green,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.stop),
                                                  onPressed: () =>
                                                      _disconnectFromDevice(),
                                                  tooltip: 'Disconnect',
                                                  color: Colors.red,
                                                ),
                                              ],
                                            )
                                          : const Icon(Icons.chevron_right),
                                      onTap: isConnectedToThisDevice
                                          ? null
                                          : () => _connectToDevice(device),
                                    ),
                                  );
                                },
                              );
                            })
                          ],
                        ),
                      ),
                    ],
                  );
                },
              )),
          GoogleCastMiniController(
            theme: GoogleCastPlayerTheme(
              backgroundColor: Colors.white,
              titleTextStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              deviceTextStyle: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
              iconColor: Colors.blue,
              iconSize: 28,
              imageBorderRadius: BorderRadius.circular(12),
              imageShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            showDeviceName: true,
          ),
        ],
      ),
    );
  }

  void _connectToDevice(GoogleCastDevice device) async {
    try {
      await GoogleCastSessionManager.instance.startSessionWithDevice(device);
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.friendlyName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Failed to connect to ${device.friendlyName}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnectFromDevice() async {
    try {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Disconnected from Cast device'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Failed to disconnect'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _loadAndPlayMedia() async {
    try {
      await GoogleCastRemoteMediaClient.instance.queueLoadItems(
        [
          GoogleCastQueueItem(
            activeTrackIds: [0],
            mediaInformation: GoogleCastMediaInformation(
              contentId: '0',
              streamType: CastMediaStreamType.buffered,
              contentUrl: Uri.parse(
                  'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4'),
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
                        'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'),
                    height: 480,
                    width: 854,
                  ),
                ],
              ),
              tracks: [
                GoogleCastMediaTrack(
                  trackId: 0,
                  type: TrackType.text,
                  trackContentId: Uri.parse(
                          'https://raw.githubusercontent.com/felnanuke2/flutter_cast/master/example/assets/VEED-subtitles_Blender_Foundation_-_Elephants_Dream_1024.vtt')
                      .toString(),
                  trackContentType: 'text/vtt',
                  name: 'English',
                  language: Rfc5646Language.portugueseBrazil,
                  subtype: TextTrackType.subtitles,
                ),
              ],
            ),
          ),
          GoogleCastQueueItem(
            preLoadTime: const Duration(seconds: 15),
            mediaInformation: GoogleCastMediaInformation(
              contentId: '1',
              streamType: CastMediaStreamType.buffered,
              contentUrl: Uri.parse(
                  'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
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
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Media loaded and playing'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Failed to load media'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _insertQueueItemAndPlay() {
    GoogleCastRemoteMediaClient.instance.queueInsertItemAndPlay(
      GoogleCastQueueItem(
        preLoadTime: const Duration(seconds: 15),
        mediaInformation: GoogleCastMediaInformation(
          contentId: '3',
          streamType: CastMediaStreamType.buffered,
          contentUrl: Uri.parse(
              'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'),
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

  void _startDiscovery() {
    setState(() {
      _isDiscoveryActive = true;
    });
    GoogleCastDiscoveryManager.instance.startDiscovery();
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Discovery started - searching for Cast devices...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _stopDiscovery() {
    setState(() {
      _isDiscoveryActive = false;
    });
    GoogleCastDiscoveryManager.instance.stopDiscovery();
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Discovery stopped'),
        backgroundColor: Colors.red,
      ),
    );
  }

  // === CUSTOMIZABLE TEXTS EXAMPLES ===

  // Default English texts
  static const _englishTexts = GoogleCastPlayerTexts();

  // Spanish localization
  static const _spanishTexts = GoogleCastPlayerTexts(
    unknownTitle: 'Título desconocido',
    castingToDevice: _spanishCastingToDevice,
    noCaptionsAvailable: 'Sin subtítulos disponibles',
    captionsOff: 'Desactivar',
    trackFallback: _spanishTrackFallback,
  );

  static String _spanishCastingToDevice(String deviceName) =>
      'Transmitiendo a $deviceName';
  static String _spanishTrackFallback(int trackId) => 'Pista $trackId';

  // French localization
  static const _frenchTexts = GoogleCastPlayerTexts(
    unknownTitle: 'Titre inconnu',
    castingToDevice: _frenchCastingToDevice,
    noCaptionsAvailable: 'Aucun sous-titre disponible',
    captionsOff: 'Désactivé',
    trackFallback: _frenchTrackFallback,
  );

  static String _frenchCastingToDevice(String deviceName) =>
      'Diffusion vers $deviceName';
  static String _frenchTrackFallback(int trackId) => 'Piste $trackId';

  // Custom branding example
  static const _customBrandingTexts = GoogleCastPlayerTexts(
    unknownTitle: 'No media selected',
    castingToDevice: _customCastingToDevice,
    noCaptionsAvailable: 'No subtitles found',
    captionsOff: 'Hide subtitles',
    trackFallback: _customTrackFallback,
  );

  static String _customCastingToDevice(String deviceName) =>
      'Streaming to your $deviceName';
  static String _customTrackFallback(int trackId) => 'Subtitle option $trackId';

  // === THEME EXAMPLES ===

  // Dark theme
  static final _darkTheme = GoogleCastPlayerTheme(
    backgroundColor: Colors.black,
    titleTextStyle: const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    deviceTextStyle: TextStyle(
      fontSize: 14,
      color: Colors.grey[400],
      fontWeight: FontWeight.w400,
    ),
    iconColor: Colors.white,
    iconSize: 32,
    imageBorderRadius: BorderRadius.circular(8),
    imageShadow: [
      BoxShadow(
        color: Colors.white.withValues(alpha: 0.2),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // Colorful theme
  static final _colorfulTheme = GoogleCastPlayerTheme(
    backgroundColor: Colors.pink[50],
    titleTextStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: Colors.purple,
    ),
    deviceTextStyle: const TextStyle(
      fontSize: 12,
      color: Colors.orange,
      fontWeight: FontWeight.w600,
    ),
    iconColor: Colors.pink,
    iconSize: 36,
    imageBorderRadius: BorderRadius.circular(20),
    imageShadow: [
      BoxShadow(
        color: Colors.pink.withValues(alpha: 0.3),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Minimalist theme
  static final _minimalistTheme = GoogleCastPlayerTheme(
    backgroundColor: Colors.grey[100],
    titleTextStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: Colors.black54,
    ),
    deviceTextStyle: const TextStyle(
      fontSize: 12,
      color: Colors.black38,
      fontWeight: FontWeight.w300,
    ),
    iconColor: Colors.black45,
    iconSize: 24,
    imageBorderRadius: BorderRadius.circular(4),
    imageShadow: [],
  );

  // === EXAMPLE HELPER METHODS ===

  void _showPlayerWithTexts(
      BuildContext context, GoogleCastPlayerTexts texts, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: ExpandedGoogleCastPlayerController(
            texts: texts,
            toggleExpand: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showPlayerWithTheme(
      BuildContext context, GoogleCastPlayerTheme theme, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          body: ExpandedGoogleCastPlayerController(
            theme: theme,
            toggleExpand: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}
