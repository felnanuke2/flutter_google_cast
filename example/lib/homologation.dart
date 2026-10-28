/// Homologation harness for the flutter_chrome_cast Android implementation.
///
/// Every case emits one machine-readable logcat line so an external driver
/// (adb + logcat) can assert on results:
///
///   HOMOLOG|SUITE_START|{suite}
///   HOMOLOG|CASE|{suite}|{case}|PASS|{detail}
///   HOMOLOG|CASE|{suite}|{case}|FAIL|{detail}
///   HOMOLOG|CASE|{suite}|{case}|SKIP|{detail}
///   HOMOLOG|SUITE_DONE|{suite}|pass={n}|fail={n}|skip={n}
///   HOMOLOG|ALL_DONE|pass={n}|fail={n}|skip={n}
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_chrome_cast/cast_context.dart';
import 'package:flutter_chrome_cast/discovery.dart';
import 'package:flutter_chrome_cast/media.dart';
import 'package:flutter_chrome_cast/models.dart';
import 'package:flutter_chrome_cast/session.dart';

import 'media_urls.dart';

const String kHomologTargetDeviceName = 'Pokemon';
const String kHomologNamespace = 'urn:x-cast:com.felnanuke.homolog';

void _log(String line) {
  // debugPrint surfaces as `I/flutter` in logcat and is chunked safely.
  debugPrint('HOMOLOG|$line', wrapWidth: 1024);
}

class HomologationRunner {
  HomologationRunner({this.targetDeviceName = kHomologTargetDeviceName});

  final String targetDeviceName;

  int _pass = 0;
  int _fail = 0;
  int _skip = 0;

  bool _running = false;
  bool get isRunning => _running;

  GoogleCastDevice? _device;

  GoogleCastDevice? get device => _device;

  final List<String> _lines = <String>[];
  ValueNotifier<List<String>> results = ValueNotifier<List<String>>(<String>[]);

  void _emit(String line) {
    _log(line);
    _lines.add(line);
    results.value = List<String>.from(_lines);
  }

  Future<void> _case(
    String suite,
    String name,
    FutureOr<String> Function() body, {
    Duration timeout = const Duration(seconds: 25),
  }) async {
    try {
      final detail = await Future<String>.value(body()).timeout(timeout);
      _pass++;
      _emit('CASE|$suite|$name|PASS|${_sanitize(detail)}');
    } on TimeoutException {
      _fail++;
      _emit('CASE|$suite|$name|FAIL|timeout after ${timeout.inSeconds}s');
    } catch (e) {
      _fail++;
      _emit('CASE|$suite|$name|FAIL|${_sanitize(e.toString())}');
    }
  }

  void _markSkip(String suite, String name, String reason) {
    _skip++;
    _emit('CASE|$suite|$name|SKIP|$reason');
  }

  bool _nameMatches(String name) =>
      name.toLowerCase().contains(targetDeviceName.toLowerCase());

  static String _sanitize(String value) =>
      value.replaceAll('\n', ' ').replaceAll('|', '/').trim();

  void _suiteStart(String suite) => _emit('SUITE_START|$suite');
  void _suiteDone(String suite) =>
      _emit('SUITE_DONE|$suite|pass=$_pass|fail=$_fail|skip=$_skip');

  // ── Media fixtures ────────────────────────────────────────────────────────

  GoogleCastMediaInformation _mp4Info({
    required String id,
    String title = 'Homolog Clip',
    bool withTrack = false,
  }) {
    return GoogleCastMediaInformation(
      contentId: id,
      streamType: CastMediaStreamType.buffered,
      contentUrl: Uri.parse(MediaUrls.bigBuckBunnyShortClip),
      contentType: 'video/mp4',
      duration: const Duration(seconds: 10),
      metadata: GoogleCastMovieMediaMetadata(
        title: title,
        studio: 'Homologation',
        images: [
          GoogleCastImage(url: Uri.parse(MediaUrls.bigBuckBunnySplash)),
        ],
      ),
      tracks: withTrack
          ? [
              GoogleCastMediaTrack(
                trackId: 0,
                type: TrackType.text,
                trackContentId: MediaUrls.elephantsDreamSubtitles,
                trackContentType: 'text/vtt',
                name: 'English',
                language: Rfc5646Language.englishUnitedStates,
                subtype: TextTrackType.subtitles,
              ),
            ]
          : null,
    );
  }

  GoogleCastMediaInformation get _hlsInfo => GoogleCastMediaInformation(
    contentId: 'hls',
    streamType: CastMediaStreamType.buffered,
    contentUrl: Uri.parse(MediaUrls.appleHlsSample),
    contentType: 'application/x-mpegURL',
    metadata: GoogleCastGenericMediaMetadata(title: 'Homolog HLS'),
  );

  List<GoogleCastQueueItem> _queue(int n, {String prefix = 'q'}) =>
      List<GoogleCastQueueItem>.generate(
        n,
        (i) => GoogleCastQueueItem(
          preLoadTime: const Duration(seconds: 5),
          mediaInformation: _mp4Info(id: '$prefix-$i', title: 'Homolog $prefix-$i'),
        ),
      );

  // ── Suite: discovery ──────────────────────────────────────────────────────

  Future<void> runDiscovery() async {
    const s = 'discovery';
    _suiteStart(s);
    final mgr = GoogleCastDiscoveryManager.instance;

    List<GoogleCastDevice> latest = const [];
    final sub = mgr.devicesStream.listen((d) => latest = d);

    // Normalise: a previous suite may have left discovery running.
    await mgr.stopDiscovery();
    await Future<void>.delayed(const Duration(milliseconds: 500));

    await _case(s, 'isDiscoveryActive_false_beforeStart', () async {
      final active = await mgr.isDiscoveryActiveForDeviceCategory(
        GoogleCastDiscoveryCriteria.kDefaultApplicationId,
      );
      if (active) {
        throw StateError(
          'reported active before startDiscovery (MediaRouter always has the '
          'local Phone route, so `routes.isNotEmpty` is not a valid check)',
        );
      }
      return 'active=false';
    });

    await _case(s, 'startDiscovery', () async {
      await mgr.startDiscovery();
      return 'ok';
    });

    await _case(s, 'devicesStream_emits', () async {
      final seen = await mgr.devicesStream
          .firstWhere((d) => d.isNotEmpty)
          .timeout(const Duration(seconds: 40));
      latest = seen;
      return 'count=${seen.length} names=${seen.map((e) => e.friendlyName).toList()}';
    });

    await _case(s, 'target_device_found', () async {
      _device = latest.cast<GoogleCastDevice?>().firstWhere(
            (d) => _nameMatches(d!.friendlyName),
            orElse: () => null,
          );
      if (_device == null) {
        throw StateError(
          'device "$targetDeviceName" not in [${latest.map((e) => e.friendlyName).toList()}]',
        );
      }
      return 'deviceId=${_device!.deviceID} name=${_device!.friendlyName}';
    });

    await _case(s, 'devicesGetter_matchesStream', () async {
      return 'devices=${mgr.devices.length} stream=${latest.length}';
    });

    await _case(s, 'isDiscoveryActive_true', () async {
      final active = await mgr.isDiscoveryActiveForDeviceCategory(
        GoogleCastDiscoveryCriteria.kDefaultApplicationId,
      );
      if (!active) throw StateError('reported inactive while discovery runs');
      return 'active=$active';
    });

    await _case(s, 'startDiscovery_activeScan', () async {
      await mgr.startDiscovery(activeScan: true);
      await Future<void>.delayed(const Duration(seconds: 3));
      return 'activeScan=true ok, devices=${mgr.devices.length}';
    });

    await _case(s, 'devices_not_duplicated_by_name', () async {
      final ids = mgr.devices.map((e) => e.deviceID).toList();
      final names = mgr.devices.map((e) => e.friendlyName).toList();
      if (ids.toSet().length != ids.length) {
        throw StateError('duplicate device ids: $ids');
      }
      // Two receivers sharing a friendly name must remain two entries.
      if (names.toSet().length != names.length && ids.toSet().length != names.length) {
        throw StateError('same-name devices collapsed: $names / $ids');
      }
      return 'ids=$ids names=$names';
    });

    await _case(s, 'stopDiscovery', () async {
      await mgr.stopDiscovery();
      return 'ok';
    });

    await _case(s, 'devices_cleared_after_stop', () async {
      await Future<void>.delayed(const Duration(seconds: 2));
      final after = mgr.devices;
      if (after.isNotEmpty) {
        throw StateError(
          'stale devices retained after stopDiscovery: '
          '${after.map((e) => e.friendlyName).toList()}',
        );
      }
      if (latest.isNotEmpty) {
        throw StateError(
          'devicesStream did not emit empty list on stop, latest='
          '${latest.map((e) => e.friendlyName).toList()}',
        );
      }
      return 'cleared';
    });

    await _case(s, 'isDiscoveryActive_false_afterStop', () async {
      final active = await mgr.isDiscoveryActiveForDeviceCategory(
        GoogleCastDiscoveryCriteria.kDefaultApplicationId,
      );
      if (active) throw StateError('reported active after stopDiscovery');
      return 'active=false';
    });

    await sub.cancel();
    _suiteDone(s);
  }

  // ── Suite: session ────────────────────────────────────────────────────────

  Future<void> runSession() async {
    const s = 'session';
    _suiteStart(s);
    final mgr = GoogleCastSessionManager.instance;

    await _ensureDevice();

    GoogleCastSession? lastSession;
    final sessionSub = mgr.currentSessionStream.listen((e) => lastSession = e);

    await _case(
      s,
      'startSessionWithDevice',
      () async {
        final ok = await mgr
            .startSessionWithDevice(_device!)
            .timeout(const Duration(seconds: 45));
        if (!ok) throw StateError('startSessionWithDevice returned false');
        await _waitFor(() => mgr.hasConnectedSession, const Duration(seconds: 75));
        return 'connected=${mgr.hasConnectedSession}';
      },
      timeout: const Duration(seconds: 120),
    );

    await _case(s, 'session_fields', () async {
      final sess = mgr.currentSession;
      if (sess == null) throw StateError('currentSession is null');
      return 'id=${sess.sessionID} device=${sess.device?.friendlyName} '
          'state=${sess.connectionState.name} vol=${sess.currentDeviceVolume} '
          'muted=${sess.currentDeviceMuted} status=${sess.deviceStatusText}';
    });

    await _case(s, 'connectionState_connected', () async {
      final st = mgr.connectionState;
      if (st != GoogleCastConnectState.connected) {
        throw StateError('connectionState=${st.name}');
      }
      return 'state=${st.name}';
    });

    await _case(s, 'sessionStream_emitted', () async {
      if (lastSession == null) throw StateError('no session event observed');
      return 'event device=${lastSession!.device?.friendlyName}';
    });

    await _case(s, 'endSession', () async {
      final ok = await mgr.endSession().timeout(const Duration(seconds: 30));
      await _waitFor(() => !mgr.hasConnectedSession, const Duration(seconds: 15));
      return 'ok=$ok connected=${mgr.hasConnectedSession}';
    });

    await _case(
      s,
      'reconnect_after_endSession',
      () async {
        final ok = await mgr.startSessionWithDevice(_device!);
        if (!ok) throw StateError('reconnect returned false');
        await _waitFor(() => mgr.hasConnectedSession, const Duration(seconds: 75));
        return 'reconnected=${mgr.hasConnectedSession}';
      },
      timeout: const Duration(seconds: 120),
    );

    await _case(s, 'resetSession', () async {
      final ok = await mgr.resetSession().timeout(const Duration(seconds: 30));
      return 'ok=$ok connected=${mgr.hasConnectedSession}';
    });

    await _case(
      s,
      'reconnect_after_reset',
      () async {
        final ok = await mgr.startSessionWithDevice(_device!);
        if (!ok) throw StateError('reconnect after reset returned false');
        await _waitFor(() => mgr.hasConnectedSession, const Duration(seconds: 75));
        return 'reconnected=${mgr.hasConnectedSession}';
      },
      timeout: const Duration(seconds: 120),
    );

    await _case(s, 'unimplemented_startSessionWithOpenURLOptions', () async {
      try {
        await mgr.startSessionWithOpenURLOptions();
        return 'returned (no throw)';
      } on UnimplementedError {
        return 'threw UnimplementedError as expected';
      }
    });

    await _case(s, 'unimplemented_suspendSessionWithReason', () async {
      try {
        await mgr.suspendSessionWithReason();
        return 'returned (no throw)';
      } on UnimplementedError {
        return 'threw UnimplementedError as expected';
      }
    });

    await _case(s, 'unimplemented_setDefaultSessionOptions', () async {
      try {
        await mgr.setDefaultSessionOptions();
        return 'returned (no throw)';
      } on UnimplementedError {
        return 'threw UnimplementedError as expected';
      }
    });

    await sessionSub.cancel();
    _suiteDone(s);
  }

  // ── Suite: load ───────────────────────────────────────────────────────────

  Future<void> runLoad() async {
    const s = 'load';
    _suiteStart(s);
    final rmc = GoogleCastRemoteMediaClient.instance;
    await _requireSession(s);

    await _case(s, 'loadMediaWithRequest_mp4', () async {
      await rmc.loadMediaWithRequest(
        GoogleCastLoadMediaRequest(
          mediaInfo: _mp4Info(id: 'req-mp4', title: 'LoadRequest MP4'),
          playPosition: const Duration(seconds: 1),
        ),
      );
      await _waitFor(() => rmc.mediaStatus != null, const Duration(seconds: 20));
      final st = rmc.mediaStatus;
      return 'playerState=${st?.playerState.name} contentId=${st?.mediaInformation?.contentId}';
    });

    await _case(s, 'loadMedia_mp4', () async {
      await rmc.loadMedia(_mp4Info(id: 'legacy-mp4', title: 'LoadMedia MP4'));
      await Future<void>.delayed(const Duration(seconds: 3));
      return 'contentId=${rmc.mediaStatus?.mediaInformation?.contentId}';
    });

    await _case(s, 'loadMedia_hls', () async {
      await rmc.loadMedia(_hlsInfo);
      await Future<void>.delayed(const Duration(seconds: 5));
      return 'contentId=${rmc.mediaStatus?.mediaInformation?.contentId} '
          'type=${rmc.mediaStatus?.mediaInformation?.contentType}';
    });

    await _case(s, 'loadMedia_customData', () async {
      await rmc.loadMedia(
        _hlsInfo,
        customData: const {
          'authorization': 'Bearer homolog-token',
          'options': {'quality': 'high'},
        },
      );
      await Future<void>.delayed(const Duration(seconds: 4));
      return 'contentId=${rmc.mediaStatus?.mediaInformation?.contentId}';
    });

    await _case(s, 'mediaStatusStream_emits', () async {
      final st = await rmc.mediaStatusStream
          .firstWhere((e) => e != null)
          .timeout(const Duration(seconds: 25));
      return 'playerState=${st!.playerState.name} session=${st.mediaSessionID}';
    });

    await _case(s, 'queueLoadItems_withTracks', () async {
      await rmc.queueLoadItems(
        _queue(2, prefix: 'loadq'),
        options: GoogleCastQueueLoadOptions(
          startIndex: 0,
          playPosition: const Duration(seconds: 1),
        ),
      );
      await _waitFor(() => rmc.queueItems.isNotEmpty, const Duration(seconds: 20));
      return 'queue=${rmc.queueItems.length} ids=${rmc.queueItems.map((e) => e.itemId).toList()}';
    });

    _suiteDone(s);
  }

  // ── Suite: transport ──────────────────────────────────────────────────────

  Future<void> runTransport() async {
    const s = 'transport';
    _suiteStart(s);
    final rmc = GoogleCastRemoteMediaClient.instance;
    await _requireSession(s);
    await _ensurePlaying(rmc);

    await _case(s, 'pause', () async {
      await rmc.pause();
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'state=${rmc.mediaStatus?.playerState.name}';
    });

    await _case(s, 'play', () async {
      await rmc.play();
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'state=${rmc.mediaStatus?.playerState.name}';
    });

    await _case(s, 'playerPositionStream', () async {
      final pos = await rmc.playerPositionStream
          .firstWhere((d) => d > Duration.zero)
          .timeout(const Duration(seconds: 25));
      return 'position=${pos.inSeconds}s';
    });

    await _case(s, 'seek_absolute', () async {
      await rmc.seek(
        GoogleCastMediaSeekOption(position: const Duration(seconds: 4)),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      final p = rmc.playerPosition.inSeconds;
      if (p < 2 || p > 8) throw StateError('position $p not near 4s');
      return 'position=${p}s';
    });

    await _case(s, 'seek_relative_plus', () async {
      final before = rmc.playerPosition.inSeconds;
      await rmc.seek(
        GoogleCastMediaSeekOption(
          position: const Duration(seconds: 2),
          relative: true,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      final after = rmc.playerPosition.inSeconds;
      if (after < before + 1) {
        throw StateError('relative +2s seek: before=${before}s after=${after}s');
      }
      return 'before=${before}s after=${after}s';
    });

    await _case(s, 'seek_relative_minus', () async {
      final before = rmc.playerPosition.inSeconds;
      await rmc.seek(
        GoogleCastMediaSeekOption(
          position: const Duration(seconds: -3),
          relative: true,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      final after = rmc.playerPosition.inSeconds;
      if (after > before - 1) {
        throw StateError('relative -3s seek: before=${before}s after=${after}s');
      }
      return 'before=${before}s after=${after}s';
    });

    await _case(s, 'setPlaybackRate_half', () async {
      await rmc.setPlaybackRate(0.5);
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'rate=${rmc.mediaStatus?.playbackRate}';
    });

    await _case(s, 'setPlaybackRate_normal', () async {
      await rmc.setPlaybackRate(1.0);
      await Future<void>.delayed(const Duration(seconds: 2));
      return 'rate=${rmc.mediaStatus?.playbackRate}';
    });

    await _case(s, 'playerPositionGetter', () async {
      return 'position=${rmc.playerPosition.inMilliseconds}ms';
    });

    _suiteDone(s);
  }

  // ── Suite: queue ──────────────────────────────────────────────────────────

  Future<void> runQueue() async {
    const s = 'queue';
    _suiteStart(s);
    final rmc = GoogleCastRemoteMediaClient.instance;
    await _requireSession(s);

    await _case(s, 'queueLoadItems_5', () async {
      await rmc.queueLoadItems(_queue(5, prefix: 'q5'));
      await _waitFor(() => rmc.queueItems.length >= 5, const Duration(seconds: 25));
      return 'count=${rmc.queueItems.length} ids=${rmc.queueItems.map((e) => e.itemId).toList()}';
    });

    await _case(s, 'queueItemsStream_emits', () async {
      final items = await rmc.queueItemsStream
          .firstWhere((e) => e.isNotEmpty)
          .timeout(const Duration(seconds: 25));
      return 'count=${items.length}';
    });

    await _case(s, 'queueHasNextItem', () async {
      return 'hasNext=${rmc.queueHasNextItem} hasPrev=${rmc.queueHasPreviousItem} '
          'current=${rmc.mediaStatus?.currentItemId}';
    });

    await _case(s, 'queueNextItem', () async {
      final before = rmc.mediaStatus?.currentItemId;
      await rmc.queueNextItem();
      await _waitFor(
        () => rmc.mediaStatus?.currentItemId != before,
        const Duration(seconds: 15),
      );
      return 'before=$before after=${rmc.mediaStatus?.currentItemId}';
    });

    await _case(s, 'queuePrevItem', () async {
      final before = rmc.mediaStatus?.currentItemId;
      await rmc.queuePrevItem();
      await _waitFor(
        () => rmc.mediaStatus?.currentItemId != before,
        const Duration(seconds: 15),
      );
      return 'before=$before after=${rmc.mediaStatus?.currentItemId}';
    });

    await _case(s, 'queueJumpToItemWithId', () async {
      final ids = rmc.queueItems.map((e) => e.itemId).toList();
      final target = ids.last;
      await rmc.queueJumpToItemWithId(target!);
      await _waitFor(
        () => rmc.mediaStatus?.currentItemId == target,
        const Duration(seconds: 15),
      );
      return 'jumped to $target (ids=$ids)';
    });

    await _case(s, 'queueInsertItemsWithRequest', () async {
      final before = rmc.queueItems.length;
      await rmc.queueInsertItemsWithRequest(
        GoogleCastQueueInsertItemsRequest(items: _queue(1, prefix: 'ins')),
      );
      await _waitFor(
        () => rmc.queueItems.length > before,
        const Duration(seconds: 15),
      );
      return 'before=$before after=${rmc.queueItems.length}';
    });

    await _case(s, 'queueInsertItems_legacy', () async {
      final before = rmc.queueItems.length;
      await rmc.queueInsertItems(_queue(1, prefix: 'insl'));
      await _waitFor(
        () => rmc.queueItems.length > before,
        const Duration(seconds: 15),
      );
      return 'before=$before after=${rmc.queueItems.length}';
    });

    await _case(s, 'queueInsertItemAndPlayWithRequest', () async {
      final ids = rmc.queueItems.map((e) => e.itemId).toList();
      final anchor = ids.length > 2 ? ids[1] : ids.first;
      await rmc.queueInsertItemAndPlayWithRequest(
        GoogleCastQueueInsertItemAndPlayRequest(
          item: _queue(1, prefix: 'iplay').first,
          beforeItemWithId: anchor!,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 4));
      return 'current=${rmc.mediaStatus?.currentItemId} count=${rmc.queueItems.length}';
    });

    await _case(s, 'queueRemoveItemsWithIds', () async {
      final ids = rmc.queueItems
          .map((e) => e.itemId)
          .whereType<int>()
          .toList();
      final current = rmc.mediaStatus?.currentItemId;
      final removable = ids.where((id) => id != current).take(2).toList();
      if (removable.isEmpty) throw StateError('no removable ids in $ids');
      await rmc.queueRemoveItemsWithIds(removable);
      await _waitFor(
        () => !rmc.queueItems.any((e) => removable.contains(e.itemId)),
        const Duration(seconds: 15),
      );
      return 'removed=$removable remaining=${rmc.queueItems.map((e) => e.itemId).toList()}';
    });

    await _case(s, 'queueReorderItemsWithRequest', () async {
      final ids = rmc.queueItems.map((e) => e.itemId).whereType<int>().toList();
      if (ids.length < 2) throw StateError('need >=2 items, got $ids');
      final movable = ids.last;
      await rmc.queueReorderItemsWithRequest(
        GoogleCastQueueReorderItemsRequest(
          itemsIds: [movable],
          beforeItemWithId: ids.first,
        ),
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      final after = rmc.queueItems.map((e) => e.itemId).toList();
      return 'before=$ids after=$after';
    });

    await _case(s, 'queueReorderItems_legacy', () async {
      final ids = rmc.queueItems.map((e) => e.itemId).whereType<int>().toList();
      if (ids.length < 2) throw StateError('need >=2 items, got $ids');
      await rmc.queueReorderItems(
        itemsIds: [ids.first],
        beforeItemWithId: ids.last,
      );
      await Future<void>.delayed(const Duration(seconds: 3));
      return 'after=${rmc.queueItems.map((e) => e.itemId).toList()}';
    });

    _suiteDone(s);
  }

  // ── Suite: tracks ─────────────────────────────────────────────────────────

  Future<void> runTracks() async {
    const s = 'tracks';
    _suiteStart(s);
    final rmc = GoogleCastRemoteMediaClient.instance;
    await _requireSession(s);

    await _case(s, 'loadMedia_withTextTrack', () async {
      await rmc.loadMedia(_mp4Info(id: 'tracks', title: 'Tracks', withTrack: true));
      await Future<void>.delayed(const Duration(seconds: 4));
      final tracks = rmc.mediaStatus?.mediaInformation?.tracks;
      return 'tracks=${tracks?.length} ids=${tracks?.map((e) => e.trackId).toList()}';
    });

    final trackId = rmc.mediaStatus?.mediaInformation?.tracks?.first.trackId;
    if (trackId == null) {
      _markSkip(s, 'setActiveTrackIDs', 'no track id after load');
    } else {
      await _case(s, 'setActiveTrackIDs_on', () async {
        await rmc.setActiveTrackIDs([trackId]);
        await _waitFor(
          () => (rmc.mediaStatus?.activeTrackIds ?? []).contains(trackId),
          const Duration(seconds: 10),
        );
        return 'active=${rmc.mediaStatus?.activeTrackIds} expected=$trackId';
      });

      await _case(s, 'setActiveTrackIDs_off', () async {
        await rmc.setActiveTrackIDs(const []);
        await _waitFor(
          () => !(rmc.mediaStatus?.activeTrackIds ?? []).contains(trackId),
          const Duration(seconds: 10),
        );
        return 'active=${rmc.mediaStatus?.activeTrackIds}';
      });
    }

    await _case(s, 'setTextTrackStyle', () async {
      await rmc.setTextTrackStyle(
        TextTrackStyle(
          backgroundColor: const Color(0xCC000000),
          foregroundColor: const Color(0xFFFFFFFF),
          fontScale: 2,
          edgeColor: const Color(0xFF000000),
          windowColor: const Color(0x66000000),
          windowRoundedCornerRadius: 8,
        ),
      );
      return 'style sent';
    });

    if (trackId != null) {
      await _case(s, 'setActiveTrackIDs_afterStyle', () async {
        await rmc.setActiveTrackIDs([trackId]);
        await _waitFor(
          () => (rmc.mediaStatus?.activeTrackIds ?? []).contains(trackId),
          const Duration(seconds: 10),
        );
        return 'active=${rmc.mediaStatus?.activeTrackIds}';
      });
    }

    _suiteDone(s);
  }

  // ── Suite: volume ─────────────────────────────────────────────────────────

  Future<void> runVolume() async {
    const s = 'volume';
    _suiteStart(s);
    final mgr = GoogleCastSessionManager.instance;
    await _requireSession(s);

    await _case(s, 'setDeviceVolumeLevel_0.3', () async {
      mgr.setDeviceVolumeLevel(const CastDeviceVolume(0.3));
      await _waitFor(
        () => (mgr.currentSession?.currentDeviceVolume ?? -1) < 0.35,
        const Duration(seconds: 10),
      );
      return 'volume=${mgr.currentSession?.currentDeviceVolume}';
    });

    await _case(s, 'setDeviceVolumeLevel_0.7', () async {
      mgr.setDeviceVolumeLevel(const CastDeviceVolume(0.7));
      await _waitFor(
        () => (mgr.currentSession?.currentDeviceVolume ?? -1) > 0.65,
        const Duration(seconds: 10),
      );
      return 'volume=${mgr.currentSession?.currentDeviceVolume}';
    });

    await _case(s, 'setDeviceVolumeLevel_0.5_muted', () async {
      mgr.setDeviceVolumeLevel(const CastDeviceVolume(0.5, muted: true));
      await _waitFor(
        () => mgr.currentSession?.currentDeviceMuted == true,
        const Duration(seconds: 10),
      );
      final s0 = mgr.currentSession;
      return 'volume=${s0?.currentDeviceVolume} muted=${s0?.currentDeviceMuted}';
    });

    await _case(s, 'setDeviceVolumeLevel_unmuted', () async {
      mgr.setDeviceVolumeLevel(const CastDeviceVolume(0.5, muted: false));
      await _waitFor(
        () => mgr.currentSession?.currentDeviceMuted == false,
        const Duration(seconds: 10),
      );
      final s0 = mgr.currentSession;
      return 'volume=${s0?.currentDeviceVolume} muted=${s0?.currentDeviceMuted}';
    });

    await _case(s, 'setDeviceVolume_deprecated', () async {
      mgr.setDeviceVolume(0.6);
      await _waitFor(
        () => (mgr.currentSession?.currentDeviceVolume ?? -1) > 0.55,
        const Duration(seconds: 10),
      );
      return 'volume=${mgr.currentSession?.currentDeviceVolume}';
    });

    _suiteDone(s);
  }

  // ── Suite: messages ───────────────────────────────────────────────────────

  Future<void> runMessages() async {
    const s = 'messages';
    _suiteStart(s);
    final mgr = GoogleCastSessionManager.instance;
    await _requireSession(s);

    GoogleCastMessage? lastMessage;
    final sub = mgr.messageStream.listen((m) => lastMessage = m);

    await _case(s, 'addMessageChannel', () async {
      final ok = await mgr.addMessageChannel(kHomologNamespace);
      if (!ok) throw StateError('addMessageChannel returned false');
      return 'namespace=$kHomologNamespace ok=$ok';
    });

    await _case(s, 'sendMessage', () async {
      final ok = await mgr.sendMessage(kHomologNamespace, '{"type":"homolog"}');
      return 'ok=$ok';
    });

    await _case(s, 'sendMessage_withoutChannel_fails', () async {
      final ok = await mgr.sendMessage('urn:x-cast:not.registered', 'x');
      return 'ok=$ok (expected false)';
    });

    await _case(s, 'sendMessage_invalidNamespace_fails', () async {
      try {
        final ok = await mgr.sendMessage('not-a-namespace', 'x');
        return 'ok=$ok (expected INVALID_ARGUMENT throw)';
      } on PlatformException catch (e) {
        return 'threw ${e.code} as expected';
      }
    });

    await _case(s, 'addMessageChannel_invalidNamespace_fails', () async {
      try {
        final ok = await mgr.addMessageChannel('bad-namespace');
        return 'ok=$ok (expected INVALID_ARGUMENT throw)';
      } on PlatformException catch (e) {
        return 'threw ${e.code} as expected';
      }
    });

    await _case(s, 'removeMessageChannel', () async {
      final ok = await mgr.removeMessageChannel(kHomologNamespace);
      return 'ok=$ok';
    });

    await _case(s, 'removeMessageChannel_unknown', () async {
      final ok = await mgr.removeMessageChannel('urn:x-cast:never.added');
      return 'ok=$ok';
    });

    await _case(s, 'messageStream_listening', () async {
      return 'lastMessage=${lastMessage?.namespace}/${lastMessage?.message} '
          '(null is OK if receiver does not echo)';
    });

    await sub.cancel();
    _suiteDone(s);
  }

  // ── Suite: context ────────────────────────────────────────────────────────

  Future<void> runContext() async {
    const s = 'context';
    _suiteStart(s);

    await _case(s, 'setSharedInstanceWithOptions', () async {
      final ok = await GoogleCastContext.instance.setSharedInstanceWithOptions(
        GoogleCastOptions(
          appId: Platform.isAndroid
              ? GoogleCastDiscoveryCriteria.kDefaultApplicationId
              : null,
          discoveryCriteria: Platform.isIOS
              ? GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
                  GoogleCastDiscoveryCriteria.kDefaultApplicationId,
                )
              : null,
          stopCastingOnAppTerminated: false,
        ),
      );
      return 'ok=$ok';
    });

    _suiteDone(s);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _ensureDevice() async {
    final mgr = GoogleCastDiscoveryManager.instance;
    await mgr.startDiscovery();
    var found = mgr.devices.cast<GoogleCastDevice?>().firstWhere(
          (d) => _nameMatches(d!.friendlyName),
          orElse: () => null,
        );
    if (found == null) {
      final all = await mgr.devicesStream
          .firstWhere(
            (list) => list.any((d) => _nameMatches(d.friendlyName)),
          )
          .timeout(const Duration(seconds: 60));
      found = all.firstWhere((d) => _nameMatches(d.friendlyName));
    }
    _device = found;
  }

  Future<void> _requireSession(String suite) async {
    final mgr = GoogleCastSessionManager.instance;
    if (mgr.hasConnectedSession) return;
    try {
      await _ensureDevice();
      final ok = await mgr
          .startSessionWithDevice(_device!)
          .timeout(const Duration(seconds: 45));
      if (!ok) throw StateError('startSessionWithDevice returned false');
      await _waitFor(() => mgr.hasConnectedSession, const Duration(seconds: 75));
    } catch (e) {
      _markSkip(suite, 'prereq_session', 'auto-reconnect failed: ${_sanitize(e.toString())}');
      throw StateError('prereq: no connected session');
    }
  }

  Future<void> _ensurePlaying(GoogleCastRemoteMediaClientPlatformInterface rmc) async {
    if (rmc.mediaStatus == null) {
      await rmc.loadMedia(_mp4Info(id: 'transport-prereq', title: 'Transport'));
      await _waitFor(() => rmc.mediaStatus != null, const Duration(seconds: 25));
    }
    await rmc.play();
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  Future<void> _waitFor(
    bool Function() predicate,
    Duration timeout,
  ) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (predicate()) return;
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    if (!predicate()) {
      throw StateError('condition not met within ${timeout.inSeconds}s');
    }
  }

  // ── Orchestration ─────────────────────────────────────────────────────────

  Future<void> run(List<String> suites) async {
    if (_running) return;
    _running = true;
    _pass = 0;
    _fail = 0;
    _skip = 0;
    _lines.clear();
    _emit('ALL_START|suites=${suites.join(',')}|target=$targetDeviceName');

    for (final suite in suites) {
      try {
        switch (suite) {
          case 'context':
            await runContext();
          case 'discovery':
            await runDiscovery();
          case 'session':
            await runSession();
          case 'load':
            await runLoad();
          case 'transport':
            await runTransport();
          case 'queue':
            await runQueue();
          case 'tracks':
            await runTracks();
          case 'volume':
            await runVolume();
          case 'messages':
            await runMessages();
          default:
            _emit('CASE|$suite|unknown|FAIL|unknown suite');
            _fail++;
        }
      } catch (e) {
        _emit('CASE|$suite|suite_aborted|FAIL|${_sanitize(e.toString())}');
      }
    }

    _emit('ALL_DONE|pass=$_pass|fail=$_fail|skip=$_skip');
    _running = false;
  }
}

// ── UI ──────────────────────────────────────────────────────────────────────

class HomologationScreen extends StatefulWidget {
  const HomologationScreen({super.key});

  @override
  State<HomologationScreen> createState() => _HomologationScreenState();
}

class _HomologationScreenState extends State<HomologationScreen> {
  final _runner = HomologationRunner();
  static const _all = <String>[
    'context',
    'discovery',
    'session',
    'load',
    'transport',
    'queue',
    'tracks',
    'volume',
    'messages',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homologation'),
        actions: [
          IconButton(
            key: const ValueKey('homolog_run_all'),
            tooltip: 'Run all suites',
            icon: const Icon(Icons.play_arrow),
            onPressed: _runner.isRunning ? null : () => _runner.run(_all),
          ),
        ],
      ),
      body: ValueListenableBuilder<List<String>>(
        valueListenable: _runner.results,
        builder: (context, lines, _) {
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in _all)
                    ActionChip(
                      key: ValueKey('homolog_$s'),
                      label: Text(s),
                      onPressed: _runner.isRunning
                          ? null
                          : () => _runner.run([s]),
                    ),
                  ActionChip(
                    key: const ValueKey('homolog_connect_pokemon'),
                    label: Text('connect $kHomologTargetDeviceName'),
                    onPressed: _runner.isRunning
                        ? null
                        : () async {
                            await _runner.runDiscovery();
                            await _runner.runSession();
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final line in lines.reversed)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    line,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: line.contains('|FAIL|')
                          ? Colors.red
                          : line.contains('|PASS|')
                              ? Colors.green.shade800
                              : line.contains('|SKIP|')
                                  ? Colors.orange.shade800
                                  : null,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
