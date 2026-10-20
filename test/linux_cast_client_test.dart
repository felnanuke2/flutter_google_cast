import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chrome_cast/linux.dart';
import 'package:flutter_chrome_cast/src/linux/cast_frame.dart';
import 'package:flutter_test/flutter_test.dart';

Future<(SecurityContext, Directory)> _ephemeralTls() async {
  // Ephemeral test-only certificate: never a production identity or secret.
  final directory = await Directory.systemTemp.createTemp('cast-tls-test-');
  final key = '${directory.path}/key.pem';
  final cert = '${directory.path}/cert.pem';
  final result = await Process.run('openssl', [
    'req',
    '-x509',
    '-newkey',
    'rsa:2048',
    '-nodes',
    '-keyout',
    key,
    '-out',
    cert,
    '-days',
    '1',
    '-subj',
    '/CN=localhost',
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  final context = SecurityContext()
    ..useCertificateChain(cert)
    ..usePrivateKey(key);
  return (context, directory);
}

/// Fake Google-TV-grade receiver: LOAD acks carry an intermediate MEDIA_STATUS
/// with extendedStatus, success arrives as an unsolicited requestId-0
/// broadcast and failures as LOAD_FAILED echoing the LOAD requestId.
class _FakeCastReceiver {
  _FakeCastReceiver({
    this.ignoreFirstGetStatus = false,
    this.emitStaleStatusAfterFailure = false,
    this.intermediateDelay = Duration.zero,
    this.finalBroadcastDelay = Duration.zero,
  });

  final bool ignoreFirstGetStatus;
  final bool emitStaleStatusAfterFailure;
  final Duration intermediateDelay;
  final Duration finalBroadcastDelay;

  /// Ordered wire events, e.g. 'stale:1', 'final:3', used to assert that a
  /// pending load completes only on the broadcast for its own session.
  final events = <String>[];
  final sockets = <SecureSocket>[];
  final requests = <Map<String, dynamic>>[];
  late final SecureServerSocket server;
  var _getStatusRequests = 0;
  var _disposed = false;

  Future<void> start(SecurityContext context) async {
    server = await SecureServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
      context,
    );
    server.listen((socket) {
      sockets.add(socket);
      final decoder = CastFrameDecoder();
      socket.listen((chunk) {
        for (final frame in decoder.add(chunk)) {
          final data = jsonDecode(frame.payload) as Map<String, dynamic>;
          requests.add(data);
          _respond(socket, frame, data);
        }
      });
    });
  }

  LinuxCastDevice get device => LinuxCastDevice(
    id: 'test',
    name: 'Fake receiver',
    host: '127.0.0.1',
    port: server.port,
  );

  Future<void> dispose() async {
    _disposed = true;
    for (final socket in sockets) {
      socket.destroy();
    }
    await server.close();
  }

  void _reply(SecureSocket socket, CastFrame frame, Map<String, dynamic> m) {
    final bytes = CastFrame(
      frame.destination,
      frame.source,
      frame.namespace,
      jsonEncode(m),
    ).encode();
    socket.add(bytes.sublist(0, 2));
    socket.add(bytes.sublist(2));
  }

  void _respond(
    SecureSocket socket,
    CastFrame frame,
    Map<String, dynamic> data,
  ) {
    if (data['requestId'] == null) return;
    final requestId = data['requestId'];
    final type = data['type'];
    if (type == 'LAUNCH') {
      _reply(socket, frame, {
        'type': 'RECEIVER_STATUS',
        'requestId': requestId,
        'status': {
          'applications': [
            {
              'appId': data['appId'],
              'transportId': 'transport-1',
              'sessionId': 'session-1',
            },
          ],
        },
      });
    } else if (type == 'STOP') {
      _reply(socket, frame, {
        'type': 'MEDIA_STATUS',
        'requestId': requestId,
        'status': <dynamic>[],
      });
    } else if (type == 'GET_STATUS') {
      _getStatusRequests++;
      if (ignoreFirstGetStatus && _getStatusRequests == 1) return;
      _reply(socket, frame, {
        'type': 'MEDIA_STATUS',
        'requestId': requestId,
        'status': [
          {'mediaSessionId': 7, 'playerState': 'PLAYING', 'currentTime': 0},
        ],
      });
    } else if (type == 'LOAD') {
      final contentId = (data['media'] as Map)['contentId'] as String;
      // Real receivers reuse the new session id from the intermediate ack
      // through the final unsolicited broadcast.
      final sessionId = contentId == 'bad' ? 1 : 3;
      void sendIntermediate() {
        if (_disposed) return;
        events.add('intermediate:$sessionId');
        _reply(socket, frame, {
          'type': 'MEDIA_STATUS',
          'requestId': requestId,
          'status': [
            {
              'mediaSessionId': sessionId,
              'playerState': 'IDLE',
              'currentTime': 0,
              'extendedStatus': {'playerState': 'LOADING'},
            },
          ],
        });
      }

      if (intermediateDelay == Duration.zero || contentId == 'bad') {
        sendIntermediate();
      } else {
        Timer(intermediateDelay, sendIntermediate);
      }
      if (contentId == 'bad') {
        _reply(socket, frame, {
          'type': 'LOAD_FAILED',
          'requestId': requestId,
          'itemId': 1,
        });
        if (emitStaleStatusAfterFailure) {
          Timer(const Duration(milliseconds: 150), () {
            if (_disposed) return;
            events.add('stale:1');
            _reply(socket, frame, {
              'type': 'MEDIA_STATUS',
              'requestId': 0,
              'status': [
                {
                  'mediaSessionId': 1,
                  'playerState': 'IDLE',
                  'idleReason': 'ERROR',
                },
              ],
            });
          });
        }
      } else {
        Timer(finalBroadcastDelay, () {
          if (_disposed) return;
          events.add('final:3');
          _reply(socket, frame, {
            'type': 'MEDIA_STATUS',
            'requestId': 0,
            'status': [
              {
                'mediaSessionId': 3,
                'playerState': 'BUFFERING',
                'currentTime': 0,
              },
            ],
          });
        });
      }
    } else {
      _reply(socket, frame, {
        'type': 'MEDIA_STATUS',
        'requestId': requestId,
        'status': [
          {
            'mediaSessionId': 7,
            'playerState': type == 'PAUSE' ? 'PAUSED' : 'PLAYING',
            'currentTime': data['currentTime'] ?? 0,
          },
        ],
      });
    }
  }
}

void main() {
  test('Cast envelope handles UTF-8 and fragmented/coalesced TCP packets', () {
    const frame = CastFrame(
      'sender-0',
      'receiver-0',
      'urn:x-cast:test',
      '{"title":"日本語"}',
    );
    final bytes = frame.encode();
    final decoder = CastFrameDecoder();
    expect(decoder.add(bytes.sublist(0, 3)), isEmpty);
    final frames = decoder.add([...bytes.sublist(3), ...bytes]);
    expect(frames, hasLength(2));
    expect(frames.first.payload, frame.payload);
    expect(frames.last.namespace, frame.namespace);
    expect(frames.last.destination, 'receiver-0');
  });

  test('untrusted framing rejects oversized and truncated protobuf fields', () {
    expect(
      () => CastFrameDecoder().add([255, 255, 255, 255]),
      throwsFormatException,
    );
    expect(
      () => CastFrame.decode(Uint8List.fromList([18, 9, 1])),
      throwsFormatException,
    );
  });

  test(
    'TLS receiver completes launch, load, controls and rejects failed load',
    () async {
      final (context, directory) = await _ephemeralTls();
      final receiver = _FakeCastReceiver();
      await receiver.start(context);
      final client = LinuxCastClient();
      try {
        await client.connect(receiver.device);
        expect(client.isConnected, isTrue);
        await client.load(
          {
            'contentId': 'https://example.test/movie.mp4',
            'contentType': 'video/mp4',
          },
          activeTrackIds: [1],
        );
        expect(client.mediaStatus!['playerState'], 'BUFFERING');
        expect(client.mediaStatus!['mediaSessionId'], 3);
        await client.pause();
        expect(client.mediaStatus!['playerState'], 'PAUSED');
        await client.seek(const Duration(milliseconds: 1250));
        expect(client.mediaStatus!['currentTime'], 1.25);
        await client.setActiveTrackIds([1, 2]);
        await client.setTextTrackStyle({
          'fontScale': 1.5,
          'foregroundColor': '#FFFFFFFF',
        });
        expect(
          receiver.requests
              .where((r) => r['type'] == 'EDIT_TRACKS_INFO')
              .first['activeTrackIds'],
          [1, 2],
        );
        expect(
          receiver.requests
              .where((r) => r['type'] == 'SEEK')
              .single['mediaSessionId'],
          7,
        );
        await client.stop();
        expect(client.mediaStatus, isNull);
        await expectLater(client.play(), throwsStateError);
        await expectLater(client.load({'contentId': 'bad'}), throwsStateError);
        expect(client.mediaStatus, isNull);
        await client.disconnect();
        expect(client.isConnected, isFalse);
      } finally {
        await client.dispose();
        await receiver.dispose();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'load resolves on the unsolicited requestId-0 BUFFERING broadcast',
    () async {
      final (context, directory) = await _ephemeralTls();
      final receiver = _FakeCastReceiver();
      await receiver.start(context);
      final client = LinuxCastClient();
      try {
        await client.connect(receiver.device);
        await client.load({
          'contentId': 'https://example.test/movie.mp4',
          'contentType': 'video/mp4',
        });
        expect(client.mediaStatus!['playerState'], 'BUFFERING');
        expect(client.mediaStatus!['mediaSessionId'], 3);
        expect(
          receiver.requests
              .where((r) => r['type'] == 'LOAD')
              .single['activeTrackIds'],
          isNull,
        );
      } finally {
        await client.dispose();
        await receiver.dispose();
        await directory.delete(recursive: true);
      }
    },
  );

  test('connect retries GET_STATUS when a cold receiver drops it', () async {
    final (context, directory) = await _ephemeralTls();
    final receiver = _FakeCastReceiver(ignoreFirstGetStatus: true);
    await receiver.start(context);
    final client = LinuxCastClient();
    try {
      await client.connect(receiver.device);
      expect(client.isConnected, isTrue);
      expect(
        receiver.requests.where((r) => r['type'] == 'GET_STATUS').length,
        greaterThanOrEqualTo(2),
      );
    } finally {
      await client.dispose();
      await receiver.dispose();
      await directory.delete(recursive: true);
    }
  });

  test(
    'a stale status broadcast cannot complete a newer pending load',
    () async {
      final (context, directory) = await _ephemeralTls();
      // Real-device ordering: the failed load's late requestId-0 ERROR
      // broadcast (session 1) arrives BEFORE the new load's intermediate
      // ack (session 3), while the new load is still pending.
      final receiver = _FakeCastReceiver(
        emitStaleStatusAfterFailure: true,
        intermediateDelay: const Duration(milliseconds: 250),
        finalBroadcastDelay: const Duration(milliseconds: 400),
      );
      await receiver.start(context);
      final client = LinuxCastClient();
      try {
        await client.connect(receiver.device);
        await expectLater(client.load({'contentId': 'bad'}), throwsStateError);
        final good = client.load({
          'contentId': 'https://example.test/movie.mp4',
          'contentType': 'video/mp4',
        });
        good.whenComplete(() => receiver.events.add('resolved'));
        await good;
        expect(receiver.events, contains('stale:1'));
        expect(
          receiver.events.indexOf('stale:1'),
          lessThan(receiver.events.indexOf('intermediate:3')),
        );
        expect(
          receiver.events.indexOf('resolved'),
          greaterThan(receiver.events.indexOf('final:3')),
        );
        expect(client.mediaStatus!['mediaSessionId'], 3);
      } finally {
        await client.dispose();
        await receiver.dispose();
        await directory.delete(recursive: true);
      }
    },
  );

  test(
    'a session with disconnect(stopReceiver: true) emits one DISCONNECTED',
    () async {
      final (context, directory) = await _ephemeralTls();
      final receiver = _FakeCastReceiver();
      await receiver.start(context);
      final client = LinuxCastClient();
      try {
        final states = <String>[];
        client.mediaStatusStream.listen(
          (status) => states.add(status['playerState'] as String),
        );
        await client.connect(receiver.device);
        await client.disconnect(stopReceiver: true);
        await Future<void>.delayed(Duration.zero);
        await client.dispose();
        await Future<void>.delayed(Duration.zero);
        expect(states.where((state) => state == 'DISCONNECTED'), hasLength(1));
        expect(
          receiver.requests
              .where((r) => r['type'] == 'STOP')
              .single['sessionId'],
          'session-1',
        );
      } finally {
        await receiver.dispose();
        await directory.delete(recursive: true);
      }
    },
  );
}
