import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';
import 'package:flutter_chrome_cast/lib.dart' hide GoogleCastPlayerTexts;
import 'package:flutter_chrome_cast/themes.dart';

/// A full-screen cast player controller widget with improved UX,
/// accessibility, and customizable theming.
class ExpandedGoogleCastPlayerController extends StatefulWidget {
  /// Callback function called when the user wants to collapse the expanded player.
  final void Function()? toggleExpand;

  /// Theme configuration for customizing the visual appearance.
  final GoogleCastPlayerTheme? theme;

  /// Text configuration for customizing all displayed text content.
  final GoogleCastPlayerTexts? texts;

  /// Creates an expanded Google Cast player controller.
  const ExpandedGoogleCastPlayerController({
    super.key,
    this.toggleExpand,
    this.theme,
    this.texts,
  });

  @override
  State<ExpandedGoogleCastPlayerController> createState() =>
      _ExpandedGoogleCastPlayerControllerState();
}

class _ExpandedGoogleCastPlayerControllerState
    extends State<ExpandedGoogleCastPlayerController>
    with TickerProviderStateMixin {
  bool _isSliding = false;
  double _sliderPercentage = 0;
  late AnimationController _playPauseController;
  late AnimationController _dragController;
  double _dragOffset = 0;
  bool _isDragging = false;

  static const _minTouchTarget = 44.0;

  @override
  void initState() {
    super.initState();
    _playPauseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _dragController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void dispose() {
    _playPauseController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final texts = widget.texts ?? const GoogleCastPlayerTexts();
    return StreamBuilder<GoggleCastMediaStatus?>(
      stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
      builder: (context, snapshot) {
        final mediaStatus =
            snapshot.data ?? GoogleCastRemoteMediaClient.instance.mediaStatus;
        final deviceName = GoogleCastSessionManager
            .instance
            .currentSession
            ?.device
            ?.friendlyName;
        if (mediaStatus == null) return const SizedBox.shrink();
        return Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Opacity(
            opacity: _isDragging
                ? (1 - (_dragOffset / 300)).clamp(0.4, 1.0)
                : 1.0,
            child: Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: Semantics(
                  label: texts.collapsePlayer,
                  button: true,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    margin: const EdgeInsets.all(8),
                    child: IconButton(
                      onPressed: widget.toggleExpand,
                      icon: const Icon(
                        CupertinoIcons.chevron_down,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  texts.nowPlaying,
                  style:
                      theme?.titleTextStyle ??
                      Theme.of(context).textTheme.titleLarge,
                ),
                actions: [
                  Semantics(
                    label: texts.disconnectCast,
                    button: true,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      margin: const EdgeInsets.all(8),
                      child: IconButton(
                        onPressed: _onCastPressed,
                        icon: const Icon(Icons.cast, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  if (theme?.backgroundWidget != null)
                    theme!.backgroundWidget!
                  else
                    _buildBackgroundImage(mediaStatus, texts),
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                  _buildDragHandle(texts),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient:
                          theme?.backgroundGradient ??
                          LinearGradient(
                            tileMode: TileMode.clamp,
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF232526),
                              const Color(0xFF414345),
                              Colors.black.withValues(alpha: 0.7),
                            ],
                          ),
                    ),
                  ),
                  Positioned.fill(
                    child: SafeArea(
                      child: Column(
                        children: [
                          const Spacer(flex: 2),
                          _buildMediaImageSection(mediaStatus, texts, theme),
                          const SizedBox(height: 24),
                          _buildTitleAndSubtitle(
                            mediaStatus,
                            texts,
                            theme,
                            context,
                          ),
                          const Spacer(flex: 1),
                          _buildDeviceBadge(
                            deviceName,
                            texts,
                            theme,
                            context,
                          ),
                          const SizedBox(height: 16),
                          _buildSliderSection(mediaStatus, theme),
                          const SizedBox(height: 12),
                          _buildControlsSection(mediaStatus, texts, theme),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDragHandle(GoogleCastPlayerTexts texts) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 4,
      left: 0,
      right: 0,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (details) {
          _dragController.stop();
          setState(() {
            _isDragging = true;
          });
        },
        onVerticalDragUpdate: (details) {
          setState(() {
            _dragOffset += details.delta.dy;
            if (_dragOffset < 0) {
              _dragOffset *= 0.2;
            }
            _dragOffset = _dragOffset.clamp(-50.0, 300.0);
          });
        },
        onVerticalDragEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond.dy;
          final shouldDismiss = _dragOffset > 60 || velocity > 600;

          if (shouldDismiss) {
            HapticFeedback.mediumImpact();
            widget.toggleExpand?.call();
          } else {
            final startOffset = _dragOffset;
            _dragController.reset();

            void animationListener() {
              setState(() {
                _dragOffset = startOffset * (1 - _dragController.value);
              });
            }

            _dragController.addListener(animationListener);
            _dragController
                .animateTo(
                  1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.elasticOut,
                )
                .then((_) {
                  _dragController.removeListener(animationListener);
                  setState(() {
                    _dragOffset = 0;
                    _isDragging = false;
                  });
                });
          }
        },
        child: Semantics(
          label: texts.dragToDismiss,
          button: true,
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: _isDragging ? 70 : 40,
                height: _isDragging ? 5 : 4,
                decoration: BoxDecoration(
                  color: _isDragging
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: _isDragging
                      ? [
                          BoxShadow(
                            color: Colors.white.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMediaImageSection(
    GoggleCastMediaStatus mediaStatus,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: theme?.imageMaxWidth ?? 300,
          maxHeight: theme?.imageMaxHeight ?? 300,
        ),
        decoration: BoxDecoration(
          borderRadius:
              theme?.imageBorderRadius ?? BorderRadius.circular(16),
          boxShadow:
              theme?.imageShadow ??
              [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
        ),
        child: ClipRRect(
          borderRadius:
              theme?.imageBorderRadius ?? BorderRadius.circular(16),
          child: Semantics(
            label: texts.mediaArtwork,
            image: true,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: _buildMediaImage(mediaStatus, theme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceBadge(
    String? deviceName,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          texts.castingToDevice(deviceName ?? 'Unknown Device'),
          style:
              theme?.deviceTextStyle ??
              Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.white),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildSliderSection(
    GoggleCastMediaStatus mediaStatus,
    GoogleCastPlayerTheme? theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          StreamBuilder<Duration?>(
            stream:
                GoogleCastRemoteMediaClient.instance.playerPositionStream,
            builder: (context, snapshot) {
              return SizedBox(
                width: 48,
                child: Text(
                  _getCurrentTimeText(mediaStatus),
                  style:
                      theme?.timeTextStyle ??
                      Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.white),
                ),
              );
            },
          ),
          _buildSlider(mediaStatus, theme),
          SizedBox(
            width: 48,
            child: Text(
              _getDurationText(mediaStatus),
              style:
                  theme?.timeTextStyle ??
                  Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentTimeText(GoggleCastMediaStatus mediaStatus) {
    final isLiveWithoutDuration =
        mediaStatus.mediaInformation?.streamType ==
            CastMediaStreamType.live &&
        (mediaStatus.mediaInformation?.duration == null ||
            mediaStatus.mediaInformation!.duration!.inSeconds == 0);
    if (isLiveWithoutDuration) return '';
    if (_isSliding) {
      return _getDurationToSeek(_sliderPercentage, mediaStatus).formatted;
    }
    return GoogleCastRemoteMediaClient.instance.playerPosition.formatted;
  }

  String _getDurationText(GoggleCastMediaStatus mediaStatus) {
    final isLiveWithoutDuration =
        mediaStatus.mediaInformation?.streamType ==
            CastMediaStreamType.live &&
        (mediaStatus.mediaInformation?.duration == null ||
            mediaStatus.mediaInformation!.duration!.inSeconds == 0);
    if (isLiveWithoutDuration) return 'LIVE';
    return mediaStatus.mediaInformation?.duration?.formatted ?? '-';
  }

  bool _isLiveStream(GoggleCastMediaStatus? mediaStatus) {
    return mediaStatus?.mediaInformation?.streamType ==
            CastMediaStreamType.live &&
        (mediaStatus?.mediaInformation?.duration == null ||
            mediaStatus?.mediaInformation?.duration?.inSeconds == 0);
  }

  Widget _buildControlsSection(
    GoggleCastMediaStatus mediaStatus,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  onPressed: _previous,
                  icon: Icons.skip_previous,
                  semanticLabel: texts.previousTrack,
                  theme: theme,
                ),
                _buildControlButton(
                  onPressed: _seekBackward30,
                  icon: Icons.replay_30,
                  semanticLabel: texts.seekBackward30,
                  theme: theme,
                ),
                _buildPlayPauseButton(mediaStatus, texts, theme),
                _buildControlButton(
                  onPressed: _seekForward30,
                  icon: Icons.forward_30,
                  semanticLabel: texts.seekForward30,
                  theme: theme,
                ),
                _buildControlButton(
                  onPressed:
                      GoogleCastRemoteMediaClient.instance.queueHasNextItem
                      ? _next
                      : null,
                  icon: Icons.skip_next,
                  semanticLabel: texts.nextTrack,
                  theme: theme,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCaptionButton(mediaStatus, texts, theme),
                GoogleCastVolume(
                  iconColor: theme?.iconColor ?? Colors.white,
                  iconSize: theme?.iconSize ?? 40,
                  popupBackgroundColor:
                      theme?.popupBackgroundColor ??
                      const Color(0xFF333333),
                  sliderActiveColor: theme?.volumeSliderActiveColor,
                  sliderInactiveColor: theme?.volumeSliderInactiveColor,
                  sliderThumbColor: theme?.volumeSliderThumbColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String semanticLabel,
    required GoogleCastPlayerTheme? theme,
  }) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onPressed != null,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _minTouchTarget,
          minHeight: _minTouchTarget,
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          iconSize: theme?.iconSize ?? 40,
          color: theme?.iconColor ?? Colors.white,
          disabledColor: theme?.disabledIconColor ?? Colors.grey,
          splashRadius: 24,
        ),
      ),
    );
  }

  Widget _buildPlayPauseButton(
    GoggleCastMediaStatus mediaStatus,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
  ) {
    final isPlaying =
        mediaStatus.playerState == CastMediaPlayerState.playing ||
        mediaStatus.playerState == CastMediaPlayerState.buffering ||
        mediaStatus.playerState == CastMediaPlayerState.loading;
    final label = isPlaying ? texts.pause : texts.play;

    return Semantics(
      label: label,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: _minTouchTarget + 12,
          minHeight: _minTouchTarget + 12,
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _togglePlayAndPause(mediaStatus.playerState);
              if (isPlaying) {
                _playPauseController.reverse();
              } else {
                _playPauseController.forward();
              }
            },
            splashColor: (theme?.iconColor ?? Colors.white).withValues(
              alpha: 0.2,
            ),
            highlightColor: (theme?.iconColor ?? Colors.white).withValues(
              alpha: 0.1,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: AnimatedIcon(
                icon: AnimatedIcons.play_pause,
                progress: _playPauseController,
                color: theme?.iconColor ?? Colors.white,
                size: theme?.iconSize != null ? theme!.iconSize! + 16 : 56,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptionButton(
    GoggleCastMediaStatus mediaStatus,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
  ) {
    return Semantics(
      label: texts.captions,
      button: true,
      child: PopupMenuButton<int>(
        itemBuilder: (context) =>
            _buildCaptionMenuItems(mediaStatus, texts, theme),
        onSelected: (trackId) => _toggleTextTrack(trackId, mediaStatus),
        icon: Icon(
          Icons.closed_caption,
          color: theme?.iconColor ?? Colors.white,
        ),
        iconSize: theme?.iconSize ?? 40,
        color:
            theme?.popupBackgroundColor ?? const Color(0xFF333333),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        tooltip: texts.captions,
      ),
    );
  }

  Expanded _buildSlider(
    GoggleCastMediaStatus? mediaStatus,
    GoogleCastPlayerTheme? theme,
  ) {
    final isLive = _isLiveStream(mediaStatus);
    final sliderValue = isLive
        ? 1.0
        : _isSliding
        ? _sliderPercentage
        : _getProgressPercentage(
            mediaStatus,
            GoogleCastRemoteMediaClient.instance.playerPosition,
          );
    final currentFormatted = _isSliding
        ? _getDurationToSeek(_sliderPercentage, mediaStatus!).formatted
        : GoogleCastRemoteMediaClient.instance.playerPosition.formatted;
    final durationFormatted =
        mediaStatus?.mediaInformation?.duration?.formatted ?? '-';

    return Expanded(
      child: StreamBuilder<Duration>(
        stream: GoogleCastRemoteMediaClient.instance.playerPositionStream,
        builder: (context, snapshot) {
          return Semantics(
            label: 'Playback position',
            value: '$currentFormatted of $durationFormatted',
            increasedValue: 'Seek forward',
            decreasedValue: 'Seek backward',
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 10,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 18,
                ),
                trackHeight: 4,
                activeTrackColor:
                    theme?.iconColor ??
                    Theme.of(context).colorScheme.primary,
                inactiveTrackColor:
                    theme?.iconColor?.withValues(alpha: 0.3) ??
                    Colors.white30,
                thumbColor: theme?.iconColor ?? Colors.white,
                overlayColor: (theme?.iconColor ?? Colors.white)
                    .withValues(alpha: 0.2),
              ),
              child: Slider(
                value: sliderValue,
                onChanged: isLive ? null : _onSliderChanged,
                onChangeStart: isLive ? null : _onSliderStarts,
                onChangeEnd: isLive
                    ? null
                    : (value) => _onSliderEnd.call(value, mediaStatus!),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCastPressed() async {
    HapticFeedback.mediumImpact();
    try {
      await GoogleCastSessionManager.instance.endSession();
    } catch (e) {
      debugPrint('Failed to end cast session: $e');
    }
  }

  void _previous() {
    HapticFeedback.lightImpact();
    GoogleCastRemoteMediaClient.instance.queuePrevItem();
  }

  void _togglePlayAndPause(CastMediaPlayerState playerState) {
    switch (playerState) {
      case CastMediaPlayerState.playing:
      case CastMediaPlayerState.buffering:
      case CastMediaPlayerState.loading:
        GoogleCastRemoteMediaClient.instance.pause();
        break;
      case CastMediaPlayerState.paused:
      case CastMediaPlayerState.idle:
      case CastMediaPlayerState.unknown:
        GoogleCastRemoteMediaClient.instance.play();
        break;
    }
  }

  void _next() {
    HapticFeedback.lightImpact();
    GoogleCastRemoteMediaClient.instance.queueNextItem();
  }

  void _seekBackward30() {
    HapticFeedback.lightImpact();
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: const Duration(seconds: -30),
        relative: true,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  void _seekForward30() {
    HapticFeedback.lightImpact();
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: const Duration(seconds: 30),
        relative: true,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  double _getProgressPercentage(
    GoggleCastMediaStatus? mediaStatus,
    Duration playerPosition,
  ) {
    final mediaDuration =
        mediaStatus?.mediaInformation?.duration ?? Duration.zero;
    if (mediaDuration.inSeconds == 0) return 0;
    if (playerPosition.inSeconds == 0) return 0;
    return playerPosition.inSeconds / mediaDuration.inSeconds;
  }

  void _onSliderStarts(double value) {
    setState(() {
      _isSliding = true;
      _sliderPercentage = value;
    });
  }

  void _onSliderChanged(double value) {
    setState(() {
      _sliderPercentage = value;
    });
  }

  void _onSliderEnd(double value, GoggleCastMediaStatus mediaStatus) {
    setState(() {
      _isSliding = false;
    });
    final durationToSeek = _getDurationToSeek(value, mediaStatus);
    GoogleCastRemoteMediaClient.instance.seek(
      GoogleCastMediaSeekOption(
        position: durationToSeek,
        resumeState: GoogleCastMediaResumeState.play,
      ),
    );
  }

  Duration _getDurationToSeek(
    double value,
    GoggleCastMediaStatus mediaStatus,
  ) {
    final duration =
        mediaStatus.mediaInformation?.duration ?? Duration.zero;
    final secondsToSeek = duration.inSeconds * value;
    return Duration(seconds: secondsToSeek.round());
  }

  Widget _buildMediaImage(
    GoggleCastMediaStatus? mediaStatus,
    GoogleCastPlayerTheme? theme,
  ) {
    final images = mediaStatus?.mediaInformation?.metadata?.images;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final sortedImages = List<GoogleCastImage>.from(images);
      sortedImages.sort((a, b) {
        final aSize = (a.width ?? 0) * (a.height ?? 0);
        final bSize = (b.width ?? 0) * (b.height ?? 0);
        return bSize.compareTo(aSize);
      });
      imageUrl = sortedImages.first.url.toString();
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: theme?.imageFit ?? BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[800],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white54,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) =>
            theme?.noImageFallback ??
            Container(
              color: Colors.grey[800],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getMediaIcon(
                      mediaStatus
                          ?.mediaInformation?.metadata?.metadataType,
                    ),
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Image unavailable',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
      );
    }

    return theme?.noImageFallback ??
        Container(
          color: Colors.grey[800],
          child: Icon(
            _getMediaIcon(
              mediaStatus?.mediaInformation?.metadata?.metadataType,
            ),
            size: 80,
            color: Colors.white54,
          ),
        );
  }

  IconData _getMediaIcon(GoogleCastMediaMetadataType? metadataType) {
    switch (metadataType) {
      case GoogleCastMediaMetadataType.movieMediaMetadata:
        return Icons.movie;
      case GoogleCastMediaMetadataType.musicTrackMediaMetadata:
        return Icons.music_note;
      case GoogleCastMediaMetadataType.tvShowMediaMetadata:
        return Icons.tv;
      case GoogleCastMediaMetadataType.photoMediaMetadata:
        return Icons.photo;
      case GoogleCastMediaMetadataType.genericMediaMetadata:
      default:
        return Icons.play_circle_filled;
    }
  }

  Widget _buildBackgroundImage(
    GoggleCastMediaStatus? mediaStatus,
    GoogleCastPlayerTexts texts,
  ) {
    final images = mediaStatus?.mediaInformation?.metadata?.images;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      final sortedImages = List<GoogleCastImage>.from(images);
      sortedImages.sort((a, b) {
        final aSize = (a.width ?? 0) * (a.height ?? 0);
        final bSize = (b.width ?? 0) * (b.height ?? 0);
        return bSize.compareTo(aSize);
      });
      imageUrl = sortedImages.first.url.toString();
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Semantics(
        label: texts.mediaArtwork,
        image: true,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[900],
            child: const Icon(
              Icons.music_note,
              size: 100,
              color: Colors.white54,
            ),
          ),
        ),
      );
    }

    return Container(
      color: Colors.grey[900],
      child: Icon(
        _getMediaIcon(
          mediaStatus?.mediaInformation?.metadata?.metadataType,
        ),
        size: 100,
        color: Colors.white54,
      ),
    );
  }

  List<PopupMenuEntry<int>> _buildCaptionMenuItems(
    GoggleCastMediaStatus? mediaStatus,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
  ) {
    final tracks = mediaStatus?.mediaInformation?.tracks;
    final activeTrackIds = mediaStatus?.activeTrackIds ?? [];

    if (tracks == null || tracks.isEmpty) {
      return [
        PopupMenuItem<int>(
          enabled: false,
          child: Text(
            texts.noCaptionsAvailable,
            style:
                theme?.popupTextStyle ??
                TextStyle(color: theme?.popupTextColor ?? Colors.white),
          ),
        ),
      ];
    }

    final textTracks = tracks
        .where(
          (track) =>
              track.type == TrackType.text ||
              track.subtype == TextTrackType.subtitles ||
              track.subtype == TextTrackType.captions,
        )
        .toList();

    if (textTracks.isEmpty) {
      return [
        PopupMenuItem<int>(
          enabled: false,
          child: Text(
            texts.noCaptionsAvailable,
            style:
                theme?.popupTextStyle ??
                TextStyle(color: theme?.popupTextColor ?? Colors.white),
          ),
        ),
      ];
    }

    final menuItems = <PopupMenuEntry<int>>[];

    menuItems.add(
      PopupMenuItem<int>(
        value: -1,
        child: Row(
          children: [
            Icon(
              activeTrackIds.isEmpty ? Icons.check : null,
              color: theme?.popupTextColor ?? Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              texts.captionsOff,
              style:
                  theme?.popupTextStyle ??
                  TextStyle(
                    color: theme?.popupTextColor ?? Colors.white,
                  ),
            ),
          ],
        ),
      ),
    );

    for (final track in textTracks) {
      final isActive = activeTrackIds.contains(track.trackId);
      menuItems.add(
        PopupMenuItem<int>(
          value: track.trackId,
          child: Row(
            children: [
              Icon(
                isActive ? Icons.check : null,
                color: theme?.popupTextColor ?? Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  track.name ??
                      track.language?.toString() ??
                      texts.trackFallback(track.trackId),
                  overflow: TextOverflow.ellipsis,
                  style:
                      theme?.popupTextStyle ??
                      TextStyle(
                        color: theme?.popupTextColor ?? Colors.white,
                      ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return menuItems;
  }

  void _toggleTextTrack(
    int trackId,
    GoggleCastMediaStatus? mediaStatus,
  ) {
    final activeTrackIds = List<int>.from(
      mediaStatus?.activeTrackIds ?? [],
    );

    if (trackId == -1) {
      final tracks = mediaStatus?.mediaInformation?.tracks;
      if (tracks != null) {
        final textTrackIds = tracks
            .where(
              (track) =>
                  track.type == TrackType.text ||
                  track.subtype == TextTrackType.subtitles ||
                  track.subtype == TextTrackType.captions,
            )
            .map((track) => track.trackId)
            .toList();
        activeTrackIds.removeWhere((id) => textTrackIds.contains(id));
      }
    } else {
      if (activeTrackIds.contains(trackId)) {
        activeTrackIds.remove(trackId);
      } else {
        final tracks = mediaStatus?.mediaInformation?.tracks;
        if (tracks != null) {
          final textTrackIds = tracks
              .where(
                (track) =>
                    track.type == TrackType.text ||
                    track.subtype == TextTrackType.subtitles ||
                    track.subtype == TextTrackType.captions,
              )
              .map((track) => track.trackId)
              .toList();
          activeTrackIds.removeWhere(
            (id) => textTrackIds.contains(id),
          );
        }
        activeTrackIds.add(trackId);
      }
    }

    GoogleCastRemoteMediaClient.instance.setActiveTrackIDs(activeTrackIds);
  }

  Widget _buildTitleAndSubtitle(
    GoggleCastMediaStatus mediaStatus,
    GoogleCastPlayerTexts texts,
    GoogleCastPlayerTheme? theme,
    BuildContext context,
  ) {
    final title =
        mediaStatus.mediaInformation?.metadata?.extractedTitle ??
        texts.unknownTitle;
    final subtitle =
        mediaStatus.mediaInformation?.metadata?.extractedSubtitle;

    final titleStyle =
        theme?.titleTextStyle ??
        Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        );

    final subtitleStyle =
        theme?.titleTextStyle?.copyWith(
          fontSize: (theme.titleTextStyle?.fontSize ?? 20) * 0.8,
          fontWeight: FontWeight.normal,
          color: Colors.white70,
        ) ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white70,
          fontWeight: FontWeight.normal,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: 'Now playing: $title',
            liveRegion: true,
            child: SizedBox(
              height: 40,
              child: _buildMarqueeText(title, titleStyle),
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Semantics(
              label: subtitle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 30,
                  minHeight: 30,
                ),
                child: _buildMarqueeText(subtitle, subtitleStyle),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMarqueeText(String text, TextStyle? style) {
    return Marquee(
      text: text,
      style: style,
      scrollAxis: Axis.horizontal,
      crossAxisAlignment: CrossAxisAlignment.center,
      blankSpace: 50.0,
      velocity: 50.0,
      pauseAfterRound: const Duration(seconds: 2),
      startPadding: 10.0,
      accelerationDuration: const Duration(milliseconds: 500),
      accelerationCurve: Curves.linear,
      decelerationDuration: const Duration(milliseconds: 500),
      decelerationCurve: Curves.easeOut,
      startAfter: const Duration(milliseconds: 1000),
    );
  }
}
