import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:multicast_dns/multicast_dns.dart';

import 'cast_frame.dart';

/// A Cast endpoint resolved from the local network or supplied manually.
class LinuxCastDevice {
  /// Creates an endpoint; port 8009 is the standard Cast TLS port.
  const LinuxCastDevice({
    required this.id,
    required this.name,
    required this.host,
    this.port = 8009,
  });

  /// Stable device identifier from mDNS.
  final String id;

  /// User-visible name advertised by the receiver.
  final String name;

  /// Reachable local IPv4 address or hostname.
  final String host;

  /// Cast TLS service port.
  final int port;
}

/// Cast V2 sender without a native plugin or Google Play Services dependency.
///
/// Cast devices use self-signed TLS certificates. This client encrypts traffic,
/// but does not implement Google's device-auth certificate verification. Use
/// only on a trusted LAN; do not send credentials or protected media secrets.
class LinuxCastClient {
  static const _connection = 'urn:x-cast:com.google.cast.tp.connection';
  static const _heartbeat = 'urn:x-cast:com.google.cast.tp.heartbeat';
  static const _receiver = 'urn:x-cast:com.google.cast.receiver';
  static const _media = 'urn:x-cast:com.google.cast.media';
  static const _deadline = Duration(seconds: 15);
  static const _launchDeadline = Duration(seconds: 30);
  static const _getStatusDeadline = Duration(seconds: 5);
  static const _getStatusAttempts = 6;
  final _statuses = StreamController<Map<String, dynamic>>.broadcast();
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  SecureSocket? _socket;
  StreamSubscription<List<int>>? _subscription;
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  String? _transport;
  String? _session;
  int? _mediaSession;
  int _nextRequest = 0;
  bool _disposed = false;
  Map<String, dynamic>? _status;
  Completer<Map<String, dynamic>>? _pendingLoad;
  Timer? _loadWatchTimer;
  int? _pendingLoadRequestId;
  int? _pendingLoadSessionId;
  final _knownSessions = <int>{};
  Set<int> _loadPriorSessions = const {};
  bool _failed = false;

  /// Whether the receiver application is connected.
  bool get isConnected => _socket != null && _transport != null;

  /// Latest Cast MEDIA_STATUS entry, or null before loading media.
  Map<String, dynamic>? get mediaStatus => _status;

  /// Media status updates and a DISCONNECTED state on connection loss.
  Stream<Map<String, dynamic>> get mediaStatusStream => _statuses.stream;

  /// All JSON messages, including custom receiver namespace responses.
  Stream<Map<String, dynamic>> get messageStream => _messages.stream;

  /// Discovers IPv4 Cast endpoints through mDNS. Timeout applies per query.
  static Future<List<LinuxCastDevice>> discover({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final client = MDnsClient();
    final devices = <String, LinuxCastDevice>{};
    try {
      await client.start();
      final services = await client
          .lookup<PtrResourceRecord>(
            ResourceRecordQuery.serverPointer('_googlecast._tcp.local'),
            timeout: timeout,
          )
          .toList();
      await Future.wait(
        services.map((ptr) async {
          final records = await client
              .lookup<SrvResourceRecord>(
                ResourceRecordQuery.service(ptr.domainName),
                timeout: timeout,
              )
              .toList();
          final texts = await client
              .lookup<TxtResourceRecord>(
                ResourceRecordQuery.text(ptr.domainName),
                timeout: timeout,
              )
              .toList();
          final properties = <String, String>{};
          for (final text in texts) {
            for (final entry in text.text.split('\n')) {
              final separator = entry.indexOf('=');
              if (separator > 0) {
                properties[entry.substring(0, separator)] = entry.substring(
                  separator + 1,
                );
              }
            }
          }
          for (final record in records) {
            final addresses = await client
                .lookup<IPAddressResourceRecord>(
                  ResourceRecordQuery.addressIPv4(record.target),
                  timeout: timeout,
                )
                .toList();
            for (final address in addresses) {
              final id = properties['id'] ?? ptr.domainName;
              devices[id] = LinuxCastDevice(
                id: id,
                name: properties['fn'] ?? ptr.domainName,
                host: address.address.address,
                port: record.port,
              );
            }
          }
        }),
      );
      return devices.values.toList();
    } finally {
      client.stop();
    }
  }

  /// Opens TLS and launches the selected receiver, waiting for its response.
  Future<void> connect(
    LinuxCastDevice device, {
    String receiverApplicationId = 'CC1AD845',
  }) async {
    if (_disposed) throw StateError('Client is disposed');
    await disconnect();
    _failed = false;
    try {
      _socket = await SecureSocket.connect(
        device.host,
        device.port,
        onBadCertificate: (_) => true,
        timeout: _deadline,
      );
      final decoder = CastFrameDecoder();
      _subscription = _socket!.listen(
        (chunk) {
          try {
            for (final frame in decoder.add(chunk)) {
              _handle(frame);
            }
          } catch (error, stack) {
            _fail(error, stack);
          }
        },
        onError: (Object error, StackTrace stack) => _fail(error, stack),
        onDone: () => _fail(
          const SocketException('Cast connection closed'),
          StackTrace.current,
        ),
      );
      _send(_connection, {'type': 'CONNECT'}, destination: 'receiver-0');
      _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        _send(_heartbeat, {'type': 'PING'}, destination: 'receiver-0');
      });
      final response = await _request(
        _receiver,
        {'type': 'LAUNCH', 'appId': receiverApplicationId},
        destination: 'receiver-0',
        timeout: _launchDeadline,
      );
      final status = response['status'] as Map<String, dynamic>?;
      final apps = status?['applications'] as List<dynamic>? ?? [];
      final app = apps
          .cast<Map<String, dynamic>>()
          .where((item) => item['appId'] == receiverApplicationId)
          .firstOrNull;
      if (app == null || app['transportId'] is! String) {
        throw StateError('Receiver application did not launch');
      }
      _transport = app['transportId'] as String;
      _session = app['sessionId'] as String?;
      _send(_connection, {'type': 'CONNECT'});
      for (var attempt = 1; ; attempt++) {
        try {
          await _request(_media, {
            'type': 'GET_STATUS',
          }, timeout: _getStatusDeadline);
          break;
        } on TimeoutException {
          if (attempt == _getStatusAttempts) rethrow;
        }
      }
      _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (isConnected) {
          _send(_media, {'type': 'GET_STATUS', 'requestId': ++_nextRequest});
        }
      });
    } catch (_) {
      await disconnect();
      rethrow;
    }
  }

  void _handle(CastFrame frame) {
    final decoded = jsonDecode(frame.payload);
    if (decoded is! Map<String, dynamic>) return;
    final type = decoded['type'] as String? ?? '';
    if (frame.namespace == _heartbeat && type == 'PING') {
      _send(_heartbeat, {'type': 'PONG'}, destination: frame.source);
    }
    if (frame.namespace == _connection && type == 'CLOSE') {
      _fail(
        const SocketException('Receiver ended Cast connection'),
        StackTrace.current,
      );
      return;
    }
    if (frame.namespace == _media && type == 'MEDIA_STATUS') {
      _applyMediaStatus(decoded);
    }
    if (!_disposed) {
      _messages.add({'namespace': frame.namespace, 'message': decoded});
    }
    if (frame.namespace == _media &&
        (type == 'LOAD_FAILED' || type == 'LOAD_CANCELLED') &&
        decoded['requestId'] == _pendingLoadRequestId) {
      _status = null;
      _mediaSession = null;
      if (!_disposed) _statuses.add({'playerState': 'IDLE'});
      _failLoad(StateError('Cast load rejected: $decoded'));
      return;
    }
    final requestId = decoded['requestId'];
    final pending = _pending.remove(requestId);
    if (pending != null) {
      if (type.endsWith('_FAILED') ||
          type.endsWith('_ERROR') ||
          type == 'INVALID_REQUEST' ||
          type == 'LAUNCH_ERROR') {
        pending.completeError(StateError('Cast request rejected: $decoded'));
      } else {
        pending.complete(decoded);
      }
    }
  }

  void _applyMediaStatus(Map<String, dynamic> decoded) {
    final statuses = decoded['status'] as List<dynamic>? ?? [];
    if (statuses.isEmpty) {
      _status = null;
      _mediaSession = null;
      if (!_disposed) _statuses.add({'playerState': 'IDLE'});
      return;
    }
    final entry = Map<String, dynamic>.from(statuses.first as Map);
    if (!_disposed) _statuses.add(entry);
    if (entry['mediaSessionId'] is int) {
      _knownSessions.add(entry['mediaSessionId'] as int);
    }
    if (entry['extendedStatus'] != null) {
      if (decoded['requestId'] == _pendingLoadRequestId &&
          entry['mediaSessionId'] is int) {
        _pendingLoadSessionId = entry['mediaSessionId'] as int;
      }
      return;
    }
    _status = entry;
    _mediaSession = entry['mediaSessionId'] as int?;
    if (entry['mediaSessionId'] is int &&
        (_pendingLoadSessionId != null
            ? entry['mediaSessionId'] == _pendingLoadSessionId
            : !_loadPriorSessions.contains(entry['mediaSessionId']))) {
      _completeLoad(decoded);
    }
  }

  void _completeLoad(Map<String, dynamic> response) {
    final completer = _pendingLoad;
    if (completer == null || completer.isCompleted) return;
    completer.complete(response);
  }

  void _failLoad(Object error, [StackTrace? stack]) {
    final completer = _pendingLoad;
    if (completer == null || completer.isCompleted) return;
    completer.completeError(error, stack);
  }

  void _fail(Object error, StackTrace stack) {
    if (_failed) return;
    _failed = true;
    final wasConnected = _socket != null || _transport != null;
    _failLoad(error, stack);
    for (final pending in _pending.values) {
      pending.completeError(error, stack);
    }
    _pending.clear();
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    _socket?.destroy();
    _socket = null;
    _transport = null;
    _session = null;
    _mediaSession = null;
    _status = null;
    if (wasConnected && !_disposed) {
      _statuses.add({'playerState': 'DISCONNECTED'});
    }
  }

  void _send(
    String namespace,
    Map<String, dynamic> payload, {
    String? destination,
  }) {
    final socket = _socket;
    final target = destination ?? _transport;
    if (socket == null || target == null) {
      throw StateError('No Cast connection');
    }
    socket.add(
      CastFrame('sender-0', target, namespace, jsonEncode(payload)).encode(),
    );
  }

  Future<Map<String, dynamic>> _request(
    String namespace,
    Map<String, dynamic> payload, {
    String? destination,
    Duration? timeout,
  }) async {
    final id = ++_nextRequest;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    try {
      _send(namespace, {...payload, 'requestId': id}, destination: destination);
      return await completer.future.timeout(timeout ?? _deadline);
    } finally {
      _pending.remove(id);
    }
  }

  /// Loads a Cast MediaInformation JSON object; URLs must reach the receiver.
  ///
  /// Resolves only on a final MEDIA_STATUS update: intermediate LOADING acks
  /// are ignored and LOAD_FAILED or LOAD_CANCELLED reject the future.
  Future<void> load(
    Map<String, dynamic> media, {
    bool autoplay = true,
    List<int>? activeTrackIds,
  }) async {
    final previous = _pendingLoad;
    if (previous != null && !previous.isCompleted) {
      throw StateError('A media load is already pending');
    }
    final id = ++_nextRequest;
    final completer = Completer<Map<String, dynamic>>();
    _pendingLoad = completer;
    _pendingLoadRequestId = id;
    _pendingLoadSessionId = null;
    _loadPriorSessions = Set.of(_knownSessions);
    _loadWatchTimer = Timer(_deadline, () {
      _failLoad(TimeoutException('Cast load timed out', _deadline));
    });
    try {
      _send(_media, {
        'type': 'LOAD',
        'requestId': id,
        'media': media,
        'autoplay': autoplay,
        'activeTrackIds': ?activeTrackIds,
      });
      await completer.future;
    } finally {
      _loadWatchTimer?.cancel();
      _loadWatchTimer = null;
      if (identical(_pendingLoad, completer)) {
        _pendingLoad = null;
        _pendingLoadRequestId = null;
        _pendingLoadSessionId = null;
      }
    }
  }

  Future<void> _mediaCommand(
    String type, [
    Map<String, dynamic> data = const {},
  ]) async {
    if (_mediaSession == null) throw StateError('No media session');
    await _request(_media, {
      'type': type,
      'mediaSessionId': _mediaSession,
      ...data,
    });
  }

  /// Resumes the active media session.
  Future<void> play() => _mediaCommand('PLAY');

  /// Pauses the active media session.
  Future<void> pause() => _mediaCommand('PAUSE');

  /// Stops the active media session.
  Future<void> stop() => _mediaCommand('STOP');

  /// Seeks to an absolute media position.
  Future<void> seek(Duration position) =>
      _mediaCommand('SEEK', {'currentTime': position.inMilliseconds / 1000});

  /// Selects tracks supported by the receiver (default receiver: one text).
  Future<void> setActiveTrackIds(List<int> ids) =>
      _mediaCommand('EDIT_TRACKS_INFO', {'activeTrackIds': ids});

  /// Applies a Cast TextTrackStyle JSON object to receiver-rendered captions.
  Future<void> setTextTrackStyle(Map<String, dynamic> style) =>
      _mediaCommand('EDIT_TRACKS_INFO', {'textTrackStyle': style});

  /// Sends JSON to a custom receiver namespace without awaiting an ACK.
  Future<void> sendMessage(
    String namespace,
    Map<String, dynamic> message,
  ) async => _send(namespace, message);

  /// Closes the sender connection, optionally stopping the receiver app.
  Future<void> disconnect({bool stopReceiver = false}) async {
    try {
      if (stopReceiver && _socket != null && _session != null) {
        await _request(_receiver, {
          'type': 'STOP',
          'sessionId': _session,
        }, destination: 'receiver-0');
      }
    } finally {
      _fail(
        const SocketException('Cast session disconnected'),
        StackTrace.current,
      );
      await _subscription?.cancel();
      _subscription = null;
    }
  }

  /// Disconnects and closes streams. A disposed client cannot reconnect.
  Future<void> dispose() async {
    if (_disposed) return;
    await disconnect();
    _disposed = true;
    await _statuses.close();
    await _messages.close();
  }
}
