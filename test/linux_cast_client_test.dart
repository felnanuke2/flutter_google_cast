import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_chrome_cast/linux.dart';
import 'package:flutter_chrome_cast/src/linux/cast_frame.dart';
import 'package:flutter_test/flutter_test.dart';

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
      final server = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      final sockets = <SecureSocket>[];
      final requests = <Map<String, dynamic>>[];
      final subscription = server.listen((socket) {
        sockets.add(socket);
        final decoder = CastFrameDecoder();
        socket.listen((chunk) {
          for (final frame in decoder.add(chunk)) {
            final data = jsonDecode(frame.payload) as Map<String, dynamic>;
            requests.add(data);
            if (data['requestId'] == null) continue;
            Map<String, dynamic> response;
            if (data['type'] == 'LAUNCH') {
              response = {
                'type': 'RECEIVER_STATUS',
                'status': {
                  'applications': [
                    {
                      'appId': data['appId'],
                      'transportId': 'transport-1',
                      'sessionId': 'session-1',
                    },
                  ],
                },
              };
            } else if (data['type'] == 'STOP') {
              response = {'type': 'MEDIA_STATUS', 'status': <dynamic>[]};
            } else if (data['type'] == 'LOAD' &&
                (data['media'] as Map)['contentId'] == 'bad') {
              response = {'type': 'LOAD_FAILED'};
            } else {
              response = {
                'type': 'MEDIA_STATUS',
                'status': [
                  {
                    'mediaSessionId': 7,
                    'playerState': data['type'] == 'PAUSE'
                        ? 'PAUSED'
                        : 'PLAYING',
                    'currentTime': data['currentTime'] ?? 0,
                  },
                ],
              };
            }
            response['requestId'] = data['requestId'];
            final bytes = CastFrame(
              frame.destination,
              frame.source,
              frame.namespace,
              jsonEncode(response),
            ).encode();
            socket.add(bytes.sublist(0, 2));
            socket.add(bytes.sublist(2));
          }
        });
      });
      final client = LinuxCastClient();
      try {
        await client.connect(
          LinuxCastDevice(
            id: 'test',
            name: 'Fake receiver',
            host: '127.0.0.1',
            port: server.port,
          ),
        );
        expect(client.isConnected, isTrue);
        await client.load(
          {
            'contentId': 'https://example.test/movie.mp4',
            'contentType': 'video/mp4',
          },
          activeTrackIds: [1],
        );
        await client.pause();
        expect(client.mediaStatus!['playerState'], 'PAUSED');
        await client.seek(const Duration(milliseconds: 1250));
        expect(client.mediaStatus!['currentTime'], 1.25);
        await client.setActiveTrackIds([1, 2]);
        await client.setTextTrackStyle({
          'fontScale': 1.5,
          'foregroundColor': '#FFFFFFFF',
        });
        await expectLater(client.load({'contentId': 'bad'}), throwsStateError);
        expect(
          requests
              .where((r) => r['type'] == 'EDIT_TRACKS_INFO')
              .first['activeTrackIds'],
          [1, 2],
        );
        expect(
          requests.where((r) => r['type'] == 'SEEK').single['mediaSessionId'],
          7,
        );
        await client.stop();
        expect(client.mediaStatus, isNull);
        await expectLater(client.play(), throwsStateError);
        await client.disconnect();
        expect(client.isConnected, isFalse);
      } finally {
        await client.dispose();
        for (final socket in sockets) {
          socket.destroy();
        }
        await subscription.cancel();
        await server.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
