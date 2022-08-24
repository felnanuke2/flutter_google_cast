import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:google_cast/lib.dart';

import '../utils/extensions.dart';

class ExpandedGoogleCastPlayerController extends StatefulWidget {
  final void Function()? toggleExpand;
  const ExpandedGoogleCastPlayerController({
    Key? key,
    this.toggleExpand,
  }) : super(key: key);

  @override
  State<ExpandedGoogleCastPlayerController> createState() =>
      _ExpandedGoogleCastPlayerControllerState();
}

class _ExpandedGoogleCastPlayerControllerState
    extends State<ExpandedGoogleCastPlayerController> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GoggleCastMediaStatus?>(
        stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
        builder: (context, snapshot) {
          final mediaStatus = snapshot.data;
          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              leading: IconButton(
                  onPressed: widget.toggleExpand,
                  icon: const Icon(CupertinoIcons.chevron_down)),
              title: Hero(
                tag: 'com.felnanuke.google_cast.controller.title',
                child: Text(
                  mediaStatus?.mediaInformation?.metadata?.extractedTitle ?? '',
                ),
              ),
              actions: [
                IconButton(onPressed: _onCastPressed, icon: Icon(Icons.cast))
              ],
            ),
            body: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'com.felnanuke.google_cast.controller.image',
                  child: Image.network(
                    fit: BoxFit.cover,
                    mediaStatus?.mediaInformation?.metadata?.images?.first.url
                            .toString() ??
                        '',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          tileMode: TileMode.clamp,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                        Colors.black,
                        Colors.black.withOpacity(0.1),
                        ...List.generate(6, (index) => Colors.transparent),
                        Colors.black.withOpacity(0.5),
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ])),
                ),
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            '2:12',
                            style: theme.textTheme.caption?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          Slider(
                            value: 0.3,
                            onChanged: _onSliderChanged,
                          ),
                          Text(
                            '10:02',
                            style: theme.textTheme.caption?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: _previous,
                            icon: const Icon(Icons.skip_previous),
                            iconSize: 48,
                            color: Colors.white,
                          ),
                          IconButton(
                            color: Colors.white,
                            onPressed: _togglePlayAndPause,
                            icon: const Icon(Icons.pause_circle),
                            iconSize: 68,
                          ),
                          IconButton(
                            color: Colors.white,
                            onPressed: _next,
                            icon: const Icon(Icons.skip_next),
                            iconSize: 48,
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _collapsePlayer() {}

  void _onCastPressed() {}

  void _previous() {}

  void _togglePlayAndPause() {}

  void _next() {}

  void _onSliderChanged(double value) {}

  ThemeData get theme => Theme.of(context);
}
