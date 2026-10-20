// Internal protocol codec; only linux.dart is a supported public entry point.
// ignore_for_file: public_member_api_docs

import 'dart:convert';
import 'dart:typed_data';

/// A UTF-8 Cast V2 envelope. Binary device-auth messages are ignored.
class CastFrame {
  const CastFrame(this.source, this.destination, this.namespace, this.payload);
  final String source;
  final String destination;
  final String namespace;
  final String payload;

  Uint8List encode() {
    final bytes = BytesBuilder();
    void number(int value) {
      while (value >= 128) {
        bytes.addByte((value & 127) | 128);
        value >>= 7;
      }
      bytes.addByte(value);
    }

    void string(int field, String value) {
      final data = utf8.encode(value);
      number((field << 3) | 2);
      number(data.length);
      bytes.add(data);
    }

    bytes.add([8, 0]);
    string(2, source);
    string(3, destination);
    string(4, namespace);
    bytes.add([40, 0]);
    string(6, payload);
    final body = bytes.takeBytes();
    final prefix = ByteData(4)..setUint32(0, body.length);
    return Uint8List.fromList([...prefix.buffer.asUint8List(), ...body]);
  }

  static CastFrame? decode(Uint8List bytes) {
    var offset = 0;
    int number() {
      var result = 0;
      for (var shift = 0; shift < 64; shift += 7) {
        if (offset >= bytes.length) {
          throw const FormatException('Truncated varint');
        }
        final byte = bytes[offset++];
        result |= (byte & 127) << shift;
        if (byte < 128) return result;
      }
      throw const FormatException('Invalid varint');
    }

    final strings = <int, String>{};
    var binary = false;
    while (offset < bytes.length) {
      final tag = number();
      final field = tag >> 3;
      switch (tag & 7) {
        case 0:
          final value = number();
          if (field == 5) binary = value != 0;
        case 2:
          final length = number();
          if (length < 0 || offset + length > bytes.length) {
            throw const FormatException('Truncated field');
          }
          if ([2, 3, 4, 6].contains(field)) {
            strings[field] = utf8.decode(
              bytes.sublist(offset, offset + length),
            );
          }
          offset += length;
        case 1:
          offset += 8;
        case 5:
          offset += 4;
        default:
          throw const FormatException('Unsupported protobuf wire type');
      }
      if (offset > bytes.length) throw const FormatException('Truncated field');
    }
    if (binary) return null;
    if (![2, 3, 4, 6].every(strings.containsKey)) {
      throw const FormatException('Missing Cast envelope field');
    }
    return CastFrame(strings[2]!, strings[3]!, strings[4]!, strings[6]!);
  }
}

/// Reassembles length-prefixed Cast frames across arbitrary TCP chunks.
class CastFrameDecoder {
  List<int> _buffer = [];
  List<CastFrame> add(List<int> chunk) {
    _buffer.addAll(chunk);
    final frames = <CastFrame>[];
    while (_buffer.length >= 4) {
      final length = ByteData.sublistView(
        Uint8List.fromList(_buffer.sublist(0, 4)),
      ).getUint32(0);
      if (length == 0 || length > 1024 * 1024) {
        throw const FormatException('Invalid Cast frame size');
      }
      if (_buffer.length < length + 4) break;
      final frame = CastFrame.decode(
        Uint8List.fromList(_buffer.sublist(4, length + 4)),
      );
      if (frame != null) frames.add(frame);
      _buffer = _buffer.sublist(length + 4);
    }
    return frames;
  }
}
