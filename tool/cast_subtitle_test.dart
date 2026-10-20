// Manual hardware-validation harness; not part of the public API.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter_chrome_cast/linux.dart';

const hls = 'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8';
final vtt =
    Platform.environment['CAST_VTT_URL'] ??
    'http://192.168.68.104:8000/subs.vtt';

void log(String s) =>
    print('[${DateTime.now().toIso8601String().substring(11, 19)}] $s');

Future<void> main() async {
  log('-- DISCOVERY (10s) --');
  var devices = await LinuxCastClient.discover(
    timeout: const Duration(seconds: 10),
  );
  for (var attempt = 2; devices.isEmpty && attempt <= 3; attempt++) {
    log('no devices, retry $attempt...');
    devices = await LinuxCastClient.discover(
      timeout: const Duration(seconds: 10),
    );
  }
  if (devices.isEmpty) {
    log('RESULT: no devices found');
    return;
  }
  final device = devices.firstWhere(
    (d) => d.name.toUpperCase().contains('POKEMON'),
    orElse: () => devices.first,
  );
  log('using: ${device.name} (${device.host})');
  final client = LinuxCastClient();
  client.mediaStatusStream.listen((s) {
    final state = s['playerState'];
    if (state == 'IDLE' || state == 'DISCONNECTED') {
      log('  [status] $state idleReason=${s['idleReason']}');
    }
  });

  await client.connect(device);
  log('-- LOAD mux HLS + external VTT sidecar (activeTrackIds [2]) --');
  try {
    await client.load(
      {
        'contentId': hls,
        'contentType': 'application/x-mpegurl',
        'streamType': 'BUFFERED',
        'tracks': [
          {
            'trackId': 2,
            'type': 'TEXT',
            'subtype': 'CAPTIONS',
            'trackContentId': vtt,
            'trackContentType': 'text/vtt',
            'name': 'Test',
            'language': 'en',
          },
        ],
      },
      activeTrackIds: [2],
    );
  } catch (e) {
    log('load failed: $e');
    await client.dispose();
    return;
  }
  log('loaded; waiting 10s (subtitles should be visible on the TV)...');
  await Future<void>.delayed(const Duration(seconds: 10));
  final status = client.mediaStatus;
  final tracks =
      (status?['media'] as Map<String, dynamic>?)?['tracks']
          as List<dynamic>? ??
      [];
  log('playerState=${status?['playerState']}');
  log('activeTrackIds=${status?['activeTrackIds']}');
  log('tracks:');
  for (final t in tracks) {
    log('  ${jsonEncode(t)}');
  }

  log('-- APPLY text style (huge red, black background) --');
  await client.setTextTrackStyle({
    'foregroundColor': '#FF0000FF',
    'backgroundColor': '#000000FF',
    'fontScale': 2.5,
    'fontStyle': 'BOLD',
  });
  await Future<void>.delayed(const Duration(seconds: 12));
  log('-- DEACTIVATE track --');
  await client.setActiveTrackIds([]);
  await Future<void>.delayed(const Duration(seconds: 4));
  log('activeTrackIds now: ${client.mediaStatus?['activeTrackIds']}');
  log('-- REACTIVATE track (default style) --');
  await client.setActiveTrackIds([2]);
  await Future<void>.delayed(const Duration(seconds: 5));
  log('activeTrackIds now: ${client.mediaStatus?['activeTrackIds']}');
  await client.disconnect(stopReceiver: true);
  await client.dispose();
  log('RESULT: subtitle test completed');
}
