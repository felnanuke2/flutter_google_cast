// Manual hardware-validation harness; not part of the public API.
// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:flutter_chrome_cast/linux.dart';

const candidates = [
  (
    'https://media.w3.org/2010/05/sintel/trailer.mp4',
    'video/mp4',
    'MP4 (expected to FAIL on these TVs)',
  ),
  (
    'https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8',
    'application/x-mpegurl',
    'HLS (expected to PLAY)',
  ),
];

void log(String s) =>
    print('[${DateTime.now().toIso8601String().substring(11, 19)}] $s');

Future<void> main() async {
  var disconnectedCount = 0;
  log('-- DISCOVERY (10s) --');
  final devices = await LinuxCastClient.discover(
    timeout: const Duration(seconds: 10),
  );
  if (devices.isEmpty) {
    log('RESULT: no devices found');
    return;
  }
  for (final d in devices) {
    log('found: ${d.name} | ${d.host}:${d.port}');
  }
  final device = devices.firstWhere(
    (d) => d.name.toUpperCase().contains('POKEMON'),
    orElse: () => devices.first,
  );
  final client = LinuxCastClient();
  client.mediaStatusStream.listen((s) {
    if (s['playerState'] == 'DISCONNECTED') {
      disconnectedCount++;
      log('  [status] DISCONNECTED emission #$disconnectedCount');
      return;
    }
    final m = jsonEncode(s);
    log('  [status] ${m.length > 200 ? '${m.substring(0, 200)}...' : m}');
  });
  client.messageStream.listen((m) {
    final msg = m['message'] as Map;
    final type = msg['type'];
    if (type == 'PONG' || type == 'MEDIA_STATUS' || type == 'RECEIVER_STATUS') {
      return;
    }
    log('  [msg] ${jsonEncode(msg)}');
  });

  log('-- CONNECT to ${device.name} (cold-start, GET_STATUS retries) --');
  await client.connect(device);
  log('connected=${client.isConnected}');

  for (final (url, contentType, note) in candidates) {
    log('-- LOAD $note --');
    log('       $url');
    try {
      await client.load({
        'contentId': url,
        'contentType': contentType,
        'streamType': 'BUFFERED',
      });
      log('load() resolved successfully');
    } catch (e) {
      log('load() THREW (correct for expected-failure case): $e');
      continue;
    }
    log('observing 12s (watch the TV)...');
    await Future<void>.delayed(const Duration(seconds: 12));
    final state = client.mediaStatus?['playerState'];
    log('playerState=$state');
    if (state == 'PLAYING' || state == 'PAUSED' || state == 'BUFFERING') {
      log('-- media controls --');
      await client.pause();
      await Future<void>.delayed(const Duration(seconds: 3));
      await client.play();
      await Future<void>.delayed(const Duration(seconds: 3));
      await client.seek(const Duration(seconds: 30));
      await Future<void>.delayed(const Duration(seconds: 6));
      log('final mediaStatus=${jsonEncode(client.mediaStatus)}');
      break;
    }
    log('no playback state reached');
  }

  log('-- DISCONNECT (stop receiver) --');
  await client.disconnect(stopReceiver: true);
  await client.dispose();
  await Future<void>.delayed(const Duration());
  log('DISCONNECTED emissions total: $disconnectedCount (expected: 1)');
  log('RESULT: smoke test completed');
}
