import 'dart:io';
import 'package:flutter/material.dart';
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
import 'dart:async';
import 'media_urls.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDiscoveryActive = false;
  StreamSubscription<List<GoogleCastQueueItem>>? _queueItemsSubscription;

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _queueItemsSubscription?.cancel();
    super.dispose();
  }

  Future<void> initPlatformState() async {
    const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
    final options = GoogleCastOptions(
      appId: Platform.isAndroid ? appId : null,
      discoveryCriteria: Platform.isIOS
          ? GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(appId)
          : null,
      stopCastingOnAppTerminated: false,
    );
    GoogleCastContext.instance.setSharedInstanceWithOptions(options);

    _queueItemsSubscription = GoogleCastRemoteMediaClient
        .instance
        .queueItemsStream
        .listen((items) {
          final ids = items.map((e) => e.itemId).toList();
          debugPrint(
            '[Example][Queue] stream update - count=${items.length}, ids=$ids',
          );
        });

    if (Platform.isIOS) {
      try {
        final isActive = await GoogleCastDiscoveryManager.instance
            .isDiscoveryActiveForDeviceCategory(appId);
        setState(() {
          _isDiscoveryActive = isActive;
        });
      } catch (e) {
        debugPrint('Error checking discovery state: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: colorScheme.primary,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: Stack(
        children: [
          Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: const Text('Google Cast'),
              centerTitle: false,
              actions: [
                StreamBuilder<GoogleCastSession?>(
                  stream:
                      GoogleCastSessionManager.instance.currentSessionStream,
                  builder: (context, snapshot) {
                    final isConnected =
                        GoogleCastSessionManager.instance.connectionState ==
                        GoogleCastConnectState.connected;
                    return IconButton(
                      onPressed: isConnected
                          ? GoogleCastSessionManager
                                .instance
                                .endSessionAndStopCasting
                          : null,
                      icon: Icon(
                        isConnected ? Icons.cast_connected : Icons.cast,
                      ),
                      tooltip: isConnected ? 'Disconnect' : 'Not connected',
                    );
                  },
                ),
              ],
            ),
            body: StreamBuilder<List<GoogleCastDevice>>(
              stream: GoogleCastDiscoveryManager.instance.devicesStream,
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];
                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _DiscoverySection(
                        isActive: _isDiscoveryActive,
                        deviceCount: devices.length,
                        onStart: _startDiscovery,
                        onStop: _stopDiscovery,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ActionsSection(
                        isConnected:
                            GoogleCastSessionManager.instance.connectionState ==
                            GoogleCastConnectState.connected,
                        onLoadQueue: _loadAndPlayMedia,
                        onLoadSingle: _loadSingleMedia,
                        onLoadHls: _loadHlsMedia,
                        onLoadHlsCustom: _loadHlsMediaWithCustomData,
                        onLoadRepro: _loadQueueRemoveReproItems,
                        onRunRepro: _runQueueRemoveRepro,
                        onInsertItem: _insertQueueItemAndPlay,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _ThemeShowcaseSection(
                        onShowPlayer: _showPlayerWithTexts,
                        onShowTheme: _showPlayerWithTheme,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Devices',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                    if (devices.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyDevicesState(),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _DeviceCard(
                            device: devices[index],
                            onConnect: () => _connectToDevice(devices[index]),
                            onDisconnect: _disconnectFromDevice,
                            onLoadSingle: _loadSingleMedia,
                            onLoadHls: _loadHlsMedia,
                            onLoadHlsCustom: _loadHlsMediaWithCustomData,
                            onPlay: _loadAndPlayMedia,
                          ),
                          childCount: devices.length,
                        ),
                      ),
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 100),
                    ),
                  ],
                );
              },
            ),
          ),
          GoogleCastMiniController(
            theme: GoogleCastPlayerTheme(
              backgroundColor: colorScheme.surface,
              titleTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              deviceTextStyle: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w400,
              ),
              iconColor: colorScheme.primary,
              iconSize: 24,
              imageBorderRadius: BorderRadius.circular(8),
              imageShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.all(12),
            borderRadius: BorderRadius.circular(12),
            showDeviceName: true,
          ),
        ],
      ),
    );
  }

  void _connectToDevice(GoogleCastDevice device) async {
    try {
      await GoogleCastSessionManager.instance.startSessionWithDevice(device);
      if (!mounted) return;
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.friendlyName}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _disconnectFromDevice() async {
    try {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
      if (!mounted) return;
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text('Disconnected'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text('Failed to disconnect: $e'),
          behavior: SnackBarBehavior.floating,
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
              contentUrl: Uri.parse(MediaUrls.sintelTrailerVideo),
              contentType: 'video/mp4',
              metadata: GoogleCastMovieMediaMetadata(
                title: 'Sintel Trailer',
                studio: 'Blender Foundation',
                releaseDate: DateTime(2010),
                images: [
                  GoogleCastImage(
                    url: Uri.parse(MediaUrls.elephantsDreamPoster),
                    height: 480,
                    width: 854,
                  ),
                ],
              ),
              tracks: [
                GoogleCastMediaTrack(
                  trackId: 0,
                  type: TrackType.text,
                  trackContentId: Uri.parse(MediaUrls.elephantsDreamSubtitles).toString(),
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
              contentUrl: Uri.parse(MediaUrls.bigBuckBunnyVideo),
              contentType: 'video/mp4',
              metadata: GoogleCastMovieMediaMetadata(
                title: 'Big Buck Bunny',
                releaseDate: DateTime(2008),
                studio: 'Blender Foundation',
                images: [
                  GoogleCastImage(
                    url: Uri.parse(MediaUrls.bigBuckBunnySplash),
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
      _showSuccess('Queue loaded');
    } catch (e) {
      _showError('Failed to load queue: $e');
    }
  }

  void _insertQueueItemAndPlay() {
    GoogleCastRemoteMediaClient.instance.queueInsertItemAndPlay(
      GoogleCastQueueItem(
        preLoadTime: const Duration(seconds: 15),
        mediaInformation: GoogleCastMediaInformation(
          contentId: '3',
          streamType: CastMediaStreamType.buffered,
          contentUrl: Uri.parse(MediaUrls.bigBuckBunnyShortClip),
          contentType: 'video/mp4',
          metadata: GoogleCastMovieMediaMetadata(
            title: 'Big Buck Bunny (Short Clip)',
            releaseDate: DateTime(2008),
            studio: 'Blender Foundation',
            images: [
              GoogleCastImage(
                url: Uri.parse(MediaUrls.bigBuckBunnyOpeningScreen),
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

  void _loadSingleMedia() async {
    try {
      final mediaInfo = GoogleCastMediaInformation(
        contentId: 'single_0',
        streamType: CastMediaStreamType.buffered,
        contentUrl: Uri.parse(MediaUrls.bigBuckBunnyVideo),
        contentType: 'video/mp4',
        metadata: GoogleCastMovieMediaMetadata(
          title: 'Big Buck Bunny',
          releaseDate: DateTime(2008),
          images: [
            GoogleCastImage(
              url: Uri.parse(MediaUrls.bigBuckBunnySplash),
              height: 480,
              width: 854,
            ),
          ],
        ),
      );
      await GoogleCastRemoteMediaClient.instance.loadMedia(mediaInfo);
      _showSuccess('Media loaded');
    } catch (e) {
      _showError('Failed to load media: $e');
    }
  }

  void _loadHlsMedia() async {
    try {
      final mediaInfo = GoogleCastMediaInformation(
        contentId: 'hls_sample',
        streamType: CastMediaStreamType.buffered,
        contentUrl: Uri.parse(
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8',
        ),
        contentType: 'application/x-mpegURL',
        metadata: GoogleCastMovieMediaMetadata(
          title: 'Apple HLS Sample',
          images: [
            GoogleCastImage(
              url: Uri.parse(MediaUrls.bigBuckBunnySplash),
              height: 480,
              width: 854,
            ),
          ],
        ),
      );
      await GoogleCastRemoteMediaClient.instance.loadMedia(mediaInfo);
      _showSuccess('HLS media loaded');
    } catch (e) {
      _showError('Failed to load HLS: $e');
    }
  }

  void _loadHlsMediaWithCustomData() async {
    try {
      final mediaInfo = GoogleCastMediaInformation(
        contentId: 'hls_custom_data_sample',
        streamType: CastMediaStreamType.buffered,
        contentUrl: Uri.parse(
          'https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8',
        ),
        contentType: 'application/x-mpegURL',
        metadata: GoogleCastMovieMediaMetadata(
          title: 'Apple HLS (customData)',
          images: [
            GoogleCastImage(
              url: Uri.parse(MediaUrls.bigBuckBunnySplash),
              height: 480,
              width: 854,
            ),
          ],
        ),
      );

      const customData = {
        'headers': {
          'Authorization': 'Bearer demo-token-123',
          'X-Client': 'flutter_google_cast_example',
        },
        'options': {'retry': true, 'timeoutSeconds': 20},
      };

      await GoogleCastRemoteMediaClient.instance.loadMedia(
        mediaInfo,
        customData: customData,
      );
      _showSuccess('HLS with customData loaded');
    } catch (e) {
      _showError('Failed to load HLS with customData: $e');
    }
  }

  Future<void> _loadQueueRemoveReproItems() async {
    try {
      final queueItems = List.generate(
        5,
        (index) => GoogleCastQueueItem(
          mediaInformation: GoogleCastMediaInformation(
            contentId: 'repro_$index',
            streamType: CastMediaStreamType.buffered,
            contentUrl: Uri.parse(MediaUrls.bigBuckBunnyVideo),
            contentType: 'video/mp4',
            metadata: GoogleCastMovieMediaMetadata(
              title: 'Queue Item ${index + 1}',
            ),
          ),
        ),
      );

      await GoogleCastRemoteMediaClient.instance.queueLoadItems(
        queueItems,
        options: GoogleCastQueueLoadOptions(startIndex: 0),
      );

      if (!mounted) return;
      _showSuccess('Repro queue loaded. Tap "Remove Items" to test.');
    } catch (e) {
      _showError('Failed to load repro queue: $e');
    }
  }

  Future<void> _runQueueRemoveRepro() async {
    try {
      final queueItems = GoogleCastRemoteMediaClient.instance.queueItems;
      final currentItemId =
          GoogleCastRemoteMediaClient.instance.mediaStatus?.currentItemId;

      final removableIds = queueItems
          .map((item) => item.itemId)
          .whereType<int>()
          .where((id) => id != currentItemId)
          .take(2)
          .toList();

      if (removableIds.length < 2) {
        if (!mounted) return;
        _showError('Load repro queue first.');
        return;
      }

      await GoogleCastRemoteMediaClient.instance.queueRemoveItemsWithIds(
        removableIds,
      );

      if (!mounted) return;
      _showSuccess('Removed items: $removableIds');
    } catch (e) {
      _showError('Remove failed: $e');
    }
  }

  void _startDiscovery() {
    setState(() {
      _isDiscoveryActive = true;
    });
    GoogleCastDiscoveryManager.instance.startDiscovery();
  }

  void _stopDiscovery() {
    setState(() {
      _isDiscoveryActive = false;
    });
    GoogleCastDiscoveryManager.instance.stopDiscovery();
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(_scaffoldKey.currentContext!).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Theme examples

  static const _englishTexts = GoogleCastPlayerTexts();

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

  static const _customBrandingTexts = GoogleCastPlayerTexts(
    unknownTitle: 'No media selected',
    castingToDevice: _customCastingToDevice,
    noCaptionsAvailable: 'No subtitles found',
    captionsOff: 'Hide subtitles',
    trackFallback: _customTrackFallback,
  );

  static String _customCastingToDevice(String deviceName) =>
      'Streaming to your $deviceName';
  static String _customTrackFallback(int trackId) =>
      'Subtitle option $trackId';

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
  );

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
  );

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

  void _showPlayerWithTexts(
    BuildContext context,
    GoogleCastPlayerTexts texts,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ExpandedGoogleCastPlayerController(
            texts: texts,
            toggleExpand: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  void _showPlayerWithTheme(
    BuildContext context,
    GoogleCastPlayerTheme theme,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(title)),
          body: ExpandedGoogleCastPlayerController(
            theme: theme,
            toggleExpand: () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Discovery Section
// ---------------------------------------------------------------------------

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({
    required this.isActive,
    required this.deviceCount,
    required this.onStart,
    required this.onStop,
  });

  final bool isActive;
  final int deviceCount;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isActive ? Icons.radar : Icons.radar_outlined,
                    color: isActive
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Discovery',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (isActive) ...[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    isActive
                        ? deviceCount > 0
                              ? '$deviceCount found'
                              : 'Searching…'
                        : 'Stopped',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      onPressed: isActive ? null : onStart,
                      icon: const Icon(Icons.play_arrow_rounded, size: 18),
                      label: const Text('Start'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !isActive ? null : onStop,
                      icon: const Icon(Icons.stop_rounded, size: 18),
                      label: const Text('Stop'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Actions Section
// ---------------------------------------------------------------------------

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({
    required this.isConnected,
    required this.onLoadQueue,
    required this.onLoadSingle,
    required this.onLoadHls,
    required this.onLoadHlsCustom,
    required this.onLoadRepro,
    required this.onRunRepro,
    required this.onInsertItem,
  });

  final bool isConnected;
  final VoidCallback onLoadQueue;
  final VoidCallback onLoadSingle;
  final VoidCallback onLoadHls;
  final VoidCallback onLoadHlsCustom;
  final VoidCallback onLoadRepro;
  final VoidCallback onRunRepro;
  final VoidCallback onInsertItem;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Media Actions',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Connect to a device first, then load media.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _ActionTile(
                icon: Icons.playlist_play,
                title: 'Load Queue',
                subtitle: '2 items with subtitles',
                onTap: isConnected ? onLoadQueue : null,
              ),
              _ActionTile(
                icon: Icons.play_circle_outline,
                title: 'Load Single Media',
                subtitle: 'Big Buck Bunny',
                onTap: isConnected ? onLoadSingle : null,
              ),
              _ActionTile(
                icon: Icons.live_tv_outlined,
                title: 'Load HLS Stream',
                subtitle: 'Apple HLS sample',
                onTap: isConnected ? onLoadHls : null,
              ),
              _ActionTile(
                icon: Icons.data_object,
                title: 'HLS + Custom Data',
                subtitle: 'With authorization headers',
                onTap: isConnected ? onLoadHlsCustom : null,
              ),
              const Divider(height: 24),
              _ActionTile(
                icon: Icons.playlist_add,
                title: 'Load Repro Queue',
                subtitle: '5 items for removal test',
                onTap: isConnected ? onLoadRepro : null,
              ),
              _ActionTile(
                icon: Icons.playlist_remove,
                title: 'Remove Items',
                subtitle: 'Remove 2 non-current items',
                onTap: isConnected ? onRunRepro : null,
              ),
              _ActionTile(
                icon: Icons.add_circle_outline,
                title: 'Insert & Play',
                subtitle: 'Insert item before current',
                onTap: isConnected ? onInsertItem : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? colorScheme.primary
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: enabled
                          ? null
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: enabled
                          ? colorScheme.onSurfaceVariant
                          : colorScheme.onSurface.withValues(alpha: 0.38),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: enabled
                  ? colorScheme.onSurfaceVariant
                  : colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Theme Showcase Section
// ---------------------------------------------------------------------------

class _ThemeShowcaseSection extends StatelessWidget {
  const _ThemeShowcaseSection({
    required this.onShowPlayer,
    required this.onShowTheme,
  });

  final void Function(
    BuildContext context,
    GoogleCastPlayerTexts texts,
    String title,
  )
  onShowPlayer;

  final void Function(
    BuildContext context,
    GoogleCastPlayerTheme theme,
    String title,
  )
  onShowTheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Player Themes',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ThemeChip(
                    label: 'English',
                    color: Colors.blue,
                    onTap: () => onShowPlayer(
                      context,
                      const GoogleCastPlayerTexts(),
                      'English',
                    ),
                  ),
                  _ThemeChip(
                    label: 'Spanish',
                    color: Colors.orange,
                    onTap: () => onShowPlayer(
                      context,
                      _MyAppState._spanishTexts,
                      'Spanish',
                    ),
                  ),
                  _ThemeChip(
                    label: 'French',
                    color: Colors.purple,
                    onTap: () => onShowPlayer(
                      context,
                      _MyAppState._frenchTexts,
                      'French',
                    ),
                  ),
                  _ThemeChip(
                    label: 'Custom',
                    color: Colors.teal,
                    onTap: () => onShowPlayer(
                      context,
                      _MyAppState._customBrandingTexts,
                      'Custom Branding',
                    ),
                  ),
                  _ThemeChip(
                    label: 'Dark',
                    color: Colors.grey.shade800,
                    onTap: () => onShowTheme(
                      context,
                      _MyAppState._darkTheme,
                      'Dark Theme',
                    ),
                  ),
                  _ThemeChip(
                    label: 'Colorful',
                    color: Colors.pink,
                    onTap: () => onShowTheme(
                      context,
                      _MyAppState._colorfulTheme,
                      'Colorful Theme',
                    ),
                  ),
                  _ThemeChip(
                    label: 'Minimal',
                    color: Colors.grey,
                    onTap: () => onShowTheme(
                      context,
                      _MyAppState._minimalistTheme,
                      'Minimal Theme',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 6,
      ),
      label: Text(label),
      onPressed: onTap,
      side: BorderSide.none,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

// ---------------------------------------------------------------------------
// Device Card
// ---------------------------------------------------------------------------

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.onConnect,
    required this.onDisconnect,
    required this.onLoadSingle,
    required this.onLoadHls,
    required this.onLoadHlsCustom,
    required this.onPlay,
  });

  final GoogleCastDevice device;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;
  final VoidCallback onLoadSingle;
  final VoidCallback onLoadHls;
  final VoidCallback onLoadHlsCustom;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<GoogleCastSession?>(
      stream: GoogleCastSessionManager.instance.currentSessionStream,
      builder: (context, sessionSnapshot) {
        final currentSession = sessionSnapshot.data;
        final isConnected =
            currentSession?.device?.deviceID == device.deviceID;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Card(
            elevation: isConnected ? 2 : 0,
            color: isConnected
                ? colorScheme.primaryContainer
                : colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isConnected
                  ? BorderSide.none
                  : BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: isConnected
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHigh,
                      child: Icon(
                        isConnected ? Icons.cast_connected : Icons.cast,
                        color: isConnected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      device.friendlyName,
                      style: TextStyle(
                        fontWeight: isConnected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      isConnected
                          ? '${device.modelName ?? ''} · Connected'
                          : device.modelName ?? '',
                      style: TextStyle(
                        color: isConnected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: isConnected
                        ? null
                        : FilledButton.tonal(
                            onPressed: onConnect,
                            child: const Text('Connect'),
                          ),
                  ),
                  if (isConnected) ...[
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _DeviceAction(
                          icon: Icons.play_circle_fill,
                          label: 'Queue',
                          color: colorScheme.primary,
                          onTap: onPlay,
                        ),
                        _DeviceAction(
                          icon: Icons.movie_outlined,
                          label: 'Single',
                          color: colorScheme.primary,
                          onTap: onLoadSingle,
                        ),
                        _DeviceAction(
                          icon: Icons.live_tv_outlined,
                          label: 'HLS',
                          color: colorScheme.primary,
                          onTap: onLoadHls,
                        ),
                        _DeviceAction(
                          icon: Icons.data_object,
                          label: 'Custom',
                          color: colorScheme.primary,
                          onTap: onLoadHlsCustom,
                        ),
                        _DeviceAction(
                          icon: Icons.logout,
                          label: 'Disconnect',
                          color: colorScheme.error,
                          onTap: onDisconnect,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DeviceAction extends StatelessWidget {
  const _DeviceAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State
// ---------------------------------------------------------------------------

class _EmptyDevicesState extends StatelessWidget {
  const _EmptyDevicesState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cast_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No devices found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start discovery to find Chromecast devices on your network.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
