import 'dart:convert' as dart_convert;
import 'dart:typed_data';

import 'bytes_buffer.dart';
import 'platform.dart';

final DataSerializerPlatform _platform = DataSerializerPlatform.instance;

/// LEB128 integer compression.
class Leb128 {
  /// Decodes a LEB128 [bytes] of a signed integer.
  /// - [n] (optional) argument specifies the number of bits in the integer.
  static int decodeUnsigned(List<int> bytes, {int n = 64}) {
    var result = 0;
    var shift = 0;
    var i = 0;

    while (true) {
      var byte = bytes[i++] & 0xFF;
      result |= _platform.shiftLeftInt((byte & 0x7F), shift);
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return result;
  }

  /// Decodes a LEB128 [bytes] of a signed integer.
  /// - [n] (optional) argument specifies the number of bits in the integer.
  static int decodeSigned(List<int> bytes, {int n = 64}) {
    var result = 0;
    var shift = 0;
    var i = 0;

    while (true) {
      var byte = bytes[i];
      result |= _platform.shiftLeftInt((byte & 0x7F), shift);
      shift += 7;

      if ((byte & 0x80) == 0) {
        break;
      }

      ++i;
    }

    if ((shift < n) && (bytes[i] & 0x40) != 0) {
      result |= _platform.shiftLeftInt(~0, shift);
    }

    return result;
  }

  /// Encodes an [int] into LEB128 unsigned integer.
  static Uint8List encodeUnsigned(int n) {
    if (n < 0) {
      n = n.abs();
    }

    var size = (n.toRadixString(2).length / 7.0).ceil();
    var parts = <int>[];
    var i = 0;

    while (i < size) {
      var part = n & 0x7F;
      n = _platform.shiftRightInt(n, 7);
      parts.add(part);

      ++i;
    }

    for (var i = 0; i < parts.length - 1; i++) {
      parts[i] |= 0x80;
    }

    return Uint8List.fromList(parts);
  }

  /// Encodes an [int] into a LEB128 signed integer.
  static Uint8List encodeSigned(int n) {
    var more = true;
    var parts = <int>[];

    while (more) {
      var byte = n & 0x7F;
      n = _platform.shiftRightInt(n, 7);

      if (n == 0 && (byte & 0x40) == 0) {
        more = false;
      } else if (n == -1 && (byte & 0x40) > 0) {
        more = false;
      } else {
        byte |= 0x80;
      }

      parts.add(byte);
    }

    return Uint8List.fromList(parts);
  }

  /// Encodes a varInt7.
  static int encodeVarInt7(int n) {
    if (n < -64 || n > 63) {
      throw ArgumentError('Value is out of range for varInt7: $n');
    }

    final signBit = (n < 0) ? 1 : 0;
    final absValue = (n < 0) ? -n : n;

    final encoded = (signBit << 6) | (absValue & 0x3F);
    return encoded;
  }

  /// Decodes a varInt7.
  static decodeVarInt7(int b0) {
    final signBit = (b0 & 0x40) >> 6;
    final absValue = b0 & 0x3F;

    final int decoded;
    if (signBit == 1) {
      if (absValue == 0) {
        return -64;
      }
      decoded = -absValue;
    } else {
      decoded = absValue;
    }

    return decoded;
  }

  /// Encodes a varUInt7.
  static int encodeVarUInt7(int n) {
    if (n < 0 || n > 127) {
      throw ArgumentError('Value is out of range for varUInt7: $n');
    }

    final encoded = n & 0x7F;
    return encoded;
  }

  /// Decodes a varUInt7.
  static decodeVarUInt7(int b0) {
    final int decoded = b0 & 0x7F;
    return decoded;
  }
}

/// LEB128 extension for BytesBuffer.
extension BytesBufferLeb128Extension on BytesBuffer {
  /// Reads a LEB128 unsigned integer.
  int readLeb128UnsignedInt() {
    var result = 0;
    var shift = 0;

    while (true) {
      var byte = readByte();
      result |= _platform.shiftLeftInt((byte & 0x7F), shift);
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return result;
  }

  /// Reads a LEB128 signed integer.
  /// - [bits] (optional) argument specifies the number of bits in the integer. Default: 64
  int readLeb128SignedInt({int bits = 64}) {
    var result = 0;
    var shift = 0;

    var lastByte = 0;

    while (true) {
      var byte = readByte();
      result |= _platform.shiftLeftInt((byte & 0x7F), shift);
      shift += 7;

      if ((byte & 0x80) == 0) {
        break;
      }

      lastByte = byte;
    }

    if ((shift < bits) && (lastByte & 0x40) != 0) {
      result |= _platform.shiftLeftInt(~0, shift);
    }

    return result;
  }

  /// Write a LEB128 unsigned integer.
  int writeLeb128UnsignedInt(int n) {
    var bs = Leb128.encodeUnsigned(n);
    return writeAllBytes(bs);
  }

  /// Write a LEB128 signed integer.
  int writeLeb128SignedInt(int n) {
    var bs = Leb128.encodeSigned(n);
    return writeAllBytes(bs);
  }

  /// Reads a LEB128 bytes block.
  Uint8List readLeb128Block() {
    var blockSize = readLeb128UnsignedInt();
    var block = readBytes(blockSize);
    return block;
  }

  /// Writes a LEB128 bytes [block].
  int writeLeb128Block(List<int> block) {
    writeLeb128UnsignedInt(block.length);
    return writeAll(block);
  }

  /// Reads a [String] inside a LEB128 bytes block.
  String readLeb128String(
      {dart_convert.Encoding encoding = dart_convert.latin1}) {
    var block = readLeb128Block();
    return encoding.decode(block);
  }

  /// Writes [String] [s] inside a LEB128 bytes block.
  int writeLeb128String(String s,
      {dart_convert.Encoding encoding = dart_convert.latin1}) {
    var bs = encoding.encode(s);
    return writeLeb128Block(bs);
  }
}
