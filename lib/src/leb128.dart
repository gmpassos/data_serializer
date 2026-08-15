import 'dart:convert' as dart_convert;
import 'dart:typed_data';

import 'bytes_buffer.dart';
import 'platform.dart';

final DataSerializerPlatform _platform = DataSerializerPlatform.instance;

/// Where the signed accumulator is split, in bits.
///
/// A LEB128 negative sign-extends into every bit below its terminating byte, so
/// the *unsigned* form of a negative value is roughly `2^shift` — far larger
/// than the value itself. Accumulating that in one `int` overflows the range a
/// JavaScript double represents exactly (2^53) once the magnitude passes about
/// 2^49, which silently corrupted values well inside the range Dart can hold —
/// microsecond timestamps sit right there, at about 2^50.6.
///
/// Splitting at 49 keeps each half exact, and the halves are recombined with
/// [BigInt] only when the value actually reaches that far.
const int _signedSplitBits = 49;

/// Folds [byte]'s 7-bit group into the low half of a signed accumulator.
int accumulateLow(int low, int byte, int shift) {
  if (shift >= _signedSplitBits) return low;
  // `+`, not `|`: the groups occupy disjoint bit ranges, so the two agree —
  // but `|` is a 32-bit operation on the web and truncated anything past 2^32.
  return low + _platform.shiftLeftInt(byte & 0x7F, shift);
}

/// Folds [byte]'s 7-bit group into the high half of a signed accumulator.
int accumulateHigh(int high, int byte, int shift) {
  if (shift < _signedSplitBits) return high;
  return high + _platform.shiftLeftInt(byte & 0x7F, shift - _signedSplitBits);
}

/// Recombines the two halves of a signed accumulator, sign-extending when
/// [negative].
int combineSigned(int low, int high, int shift, bool negative) {
  if (high == 0) {
    if (!negative) return low;

    if (_platform.supportsFullBitsShift) {
      return low | _platform.shiftLeftInt(-1, shift);
    }
    return (BigInt.from(low) | (BigInt.from(-1) << shift)).toInt();
  }

  var value = (BigInt.from(high) << _signedSplitBits) + BigInt.from(low);
  if (negative) {
    value |= BigInt.from(-1) << shift;
  }
  return value.toInt();
}

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
      // `+`, not `|=`: each 7-bit group lands in its own bit range, so the two
      // are equivalent here — but `|` is a 32-bit operation where an `int` is a
      // JavaScript double, and truncated any value past 2^32.
      result += _platform.shiftLeftInt((byte & 0x7F), shift);
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return result;
  }

  /// Decodes a LEB128 [bytes] of a signed integer.
  /// - [n] (optional) argument specifies the number of bits in the integer.
  static int decodeSigned(List<int> bytes, {int n = 64}) {
    var low = 0;
    var high = 0;
    var shift = 0;
    var i = 0;

    while (true) {
      var byte = bytes[i];
      low = accumulateLow(low, byte, shift);
      high = accumulateHigh(high, byte, shift);
      shift += 7;

      if ((byte & 0x80) == 0) {
        break;
      }

      ++i;
    }

    var negative = (shift < n) && (bytes[i] & 0x40) != 0;

    return combineSigned(low, high, shift, negative);
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
      // See [Leb128.decodeUnsigned]: `+` rather than `|=`, which is a 32-bit
      // operation on the web and truncated anything past 2^32.
      result += _platform.shiftLeftInt((byte & 0x7F), shift);
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }

    return result;
  }

  /// Reads a LEB128 signed integer.
  /// - [bits] (optional) argument specifies the number of bits in the integer. Default: 64
  int readLeb128SignedInt({int bits = 64}) {
    var low = 0;
    var high = 0;
    var shift = 0;

    var lastByte = 0;

    while (true) {
      var byte = readByte();
      low = accumulateLow(low, byte, shift);
      high = accumulateHigh(high, byte, shift);
      shift += 7;

      // The sign lives in bit 6 of the *terminating* byte, so record every
      // byte — including the one that ends the loop. Assigning after the
      // `break` left [lastByte] holding the previous continuation byte (or 0
      // for a single-byte value), which made the sign test below read the
      // wrong bit: `-2` decoded as `126`, and `64` as `-16320`.
      lastByte = byte;

      if ((byte & 0x80) == 0) {
        break;
      }
    }

    var negative = (shift < bits) && (lastByte & 0x40) != 0;

    return combineSigned(low, high, shift, negative);
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

  /// Reads a LEB128 bytes block into [dst].
  int readLeb128BlockTo(BytesBuffer dst) {
    var blockSize = readLeb128UnsignedInt();
    return readTo(dst, blockSize);
  }

  /// Writes a LEB128 bytes [block] from [src].
  int writeLeb128BlockFrom(BytesBuffer src, [int? length]) {
    length ??= src.length;
    var bsLng = Leb128.encodeUnsigned(length);
    writeAllBytes(bsLng);
    return writeFrom(src, length) + bsLng.length;
  }

  /// Reads a [String] inside a LEB128 bytes block.
  String readLeb128String({
    dart_convert.Encoding encoding = dart_convert.latin1,
  }) {
    var block = readLeb128Block();
    return encoding.decode(block);
  }

  /// Writes [String] [s] inside a LEB128 bytes block.
  int writeLeb128String(
    String s, {
    dart_convert.Encoding encoding = dart_convert.latin1,
  }) {
    var bs = encoding.encode(s);
    return writeLeb128Block(bs);
  }
}
