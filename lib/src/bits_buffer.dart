import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';

/// A buffer of bits over a [BytesBuffer].
class BitsBuffer {
  final BytesBuffer _bytesBuffer;

  BitsBuffer([int initialCapacity = 32])
      : _bytesBuffer = BytesBuffer(initialCapacity);

  /// The internal [BytesBuffer].
  BytesBuffer get bytesBuffer => _bytesBuffer;

  BitsBuffer.from(BytesBuffer bytes) : _bytesBuffer = bytes;

  int seek(int position) => _bytesBuffer.seek(position);

  /// The position of the [bytesBuffer].
  int get position => _bytesBuffer.position;

  /// The length of the [bytesBuffer].
  int get length => _bytesBuffer.length;

  /// The remaining bytes of the [bytesBuffer].
  int get remaining => _bytesBuffer.remaining;

  int _bitsBuffer = 0;
  int _bitsBufferLength = 0;

  /// Returns `true` if there are any remaining bits that haven't been written
  /// to the [bytesBuffer].
  bool get hasUnflushedBits => _bitsBufferLength > 0;

  /// Returns the length of unflushed bits in the internal bit buffer. See [hasUnflushedBits].
  int get unflushedBitsLength => _bitsBufferLength;

  /// Checks for unflushed bits using [hasUnflushedBits] and throws a [StateError]
  /// if there are any bits that haven't been written.
  void checkUnflushedBits() {
    if (hasUnflushedBits) {
      throw StateError("Unflushed bits: $_bitsBufferLength");
    }
  }

  /// Writes a byte [b].
  int writeByte(int b) {
    if (_bitsBufferLength == 0) {
      _bytesBuffer.writeByte(b & 0xFF);
      return 1;
    }

    writeBits(b, 8);
    return 1;
  }

  /// Writes a list of bytes.
  int writeBytes(List<int> bs) {
    if (_bitsBufferLength == 0) {
      _bytesBuffer.writeAll(bs);
      return 1;
    }

    final length = bs.length;
    for (var i = 0; i < length; ++i) {
      writeByte(bs[i]);
    }

    return length;
  }

  /// Writes a [bit] (`true`: `1` ; `false`: `0`).
  /// Returns the number of bits successfully written into the buffer.
  ///
  /// Note that a byte is written to the internal [bytesBuffer] for every 8 accumulated bits.
  /// See [writeBits] and [unflushedBitsLength].
  int writeBit(bool bit) {
    return writeBits(bit ? 1 : 0, 1);
  }

  /// Writes the specified number of bits from the given integer value into the internal [bytesBuffer].
  ///
  /// Parameters:
  /// - `bits`: The integer containing the bits to be written.
  /// - `bitsLength`: The number of bits to write from the `bits` integer.
  ///
  /// Returns the number of bits successfully written into the buffer.
  ///
  /// Note that a byte is written to the internal [bytesBuffer] for every 8 accumulated bits.
  /// See [writeBit] and [unflushedBitsLength].
  int writeBits(int bits, int bitsLength) {
    if (bitsLength == 8 && _bitsBufferLength == 0) {
      _bytesBuffer.writeByte(bits & 0xFF);
      return 8;
    }

    var bitsWrote = 0;

    while (bitsLength > 0) {
      var bufferRemaining = 8 - _bitsBufferLength;
      assert(bufferRemaining > 0);

      var bitsLng = bitsLength;
      if (bitsLng > bufferRemaining) {
        bitsLng = bufferRemaining;
      }
      assert(bitsLng >= 1 && bitsLng <= 8);

      var bitsExtra = bitsLength - bitsLng;

      var bMask = (1 << bitsLng) - 1;
      assert(bMask > 0);
      var bMask2 = (1 << bitsExtra) - 1;

      _bitsBuffer = (_bitsBuffer << bitsLng) | ((bits >> bitsExtra) & bMask);
      _bitsBufferLength += bitsLng;
      bits = bits & bMask2;

      bitsWrote += bitsLng;
      bitsLength -= bitsLng;

      assert(_bitsBufferLength >= 1 && _bitsBufferLength <= 8);

      if (_bitsBufferLength == 8) {
        _bytesBuffer.writeByte(_bitsBuffer);
        _bitsBuffer = 0;
        _bitsBufferLength = 0;
      }
    }

    return bitsWrote;
  }

  /// Reads a byte.
  int readByte() => readBits(8);

  /// Reads a bit.
  int readBit() {
    return readBits(1);
  }

  /// Reads and returns the specified number of bits from the internal buffer.
  ///
  /// Parameters:
  /// - `bitsLength`: The number of bits to be read from the internal buffer.
  ///
  /// Returns an integer containing the read bits.
  int readBits(int bitsLength) {
    if (bitsLength == 8 && _bitsBufferLength == 0) {
      return _bytesBuffer.readByte();
    }

    while (_bitsBufferLength < bitsLength) {
      var rb = _bytesBuffer.readByte();
      _bitsBuffer = (_bitsBuffer << 8) | (rb & 0xFF);
      _bitsBufferLength += 8;
    }

    if (bitsLength == _bitsBufferLength) {
      var b = _bitsBuffer;
      _bitsBuffer = 0;
      _bitsBufferLength = 0;
      return b;
    }

    var extraBits = _bitsBufferLength - bitsLength;

    var bMask = (1 << bitsLength) - 1;
    assert(bMask > 0);
    var bMask2 = (1 << extraBits) - 1;

    var b = (_bitsBuffer >>> extraBits) & bMask;

    _bitsBuffer = _bitsBuffer & bMask2;
    _bitsBufferLength -= bitsLength;

    return b;
  }

  /// Writes padding bits to ensure proper byte alignment.
  ///
  /// Since data is flushed in blocks of 8 bits (bytes), if the internal buffer's
  /// size is not a multiple of 8, padding bits are needed to ensure that the
  /// remaining bits are properly flushed.
  ///
  /// The padding format consists of a `1` bit (the head) and an optional
  /// sequence of `0` bits until a full byte is completed.
  ///
  /// Example:
  /// - If the internal unflushed buffer contains 5 bits (e.g., `00110`) and
  ///   you call [writePadding], it will add a `1` bit and 2 `0` bits (`100`)
  ///   to the buffer, completing the byte to flush (`00110100`). This ensures
  ///   that the unflushed bits can be written to [bytesBuffer] and later be
  ///   read, with knowledge of how to remove the padding.
  ///
  /// - If there are no unflushed bits, a full padding byte (`10000000`)
  ///   is written to [bytesBuffer].
  ///
  /// See [isAtPadding].
  void writePadding() {
    if (_bitsBufferLength == 0) {
      var padding = (1 << 7);
      _bytesBuffer.writeByte(padding);
    } else {
      final gapBits = 8 - _bitsBufferLength;
      assert(gapBits > 0);

      var padding = 1 << (gapBits - 1);

      writeBits(padding, gapBits);
    }
  }

  /// If the current buffer is at the padding position, it consumes the padding
  /// bits and then returns `true`.
  /// If not, it simply returns `false` without changing the internal buffer's
  /// status or position.
  ///
  /// If the [paddingPosition] is not explicitly passed, its value will be set
  /// to the last byte position of the [bytesBuffer].
  bool isAtPadding({int? paddingPosition}) {
    paddingPosition ??= _bytesBuffer.length - 1;
    final pos = _bytesBuffer.position;

    if (pos >= paddingPosition) {
      if ((pos == paddingPosition && _bitsBufferLength == 0) ||
          (pos > paddingPosition && _bitsBufferLength > 0)) {
        var padding = readPadding();
        if (padding > 0) {
          return true;
        }
      }
    }

    return false;
  }

  /// Reads the padding and returns the amount of bits read. If the current
  /// buffer is not at the padding position, it will return `false` without
  /// changing the internal buffer's status or position.
  int readPadding() {
    if (_bitsBufferLength == 0) {
      final initPos = _bytesBuffer.position;

      var b = _bytesBuffer.readByte();

      if (b == (1 << 7)) {
        return 8;
      } else {
        _bytesBuffer.seek(initPos);
        return 0;
      }
    }

    final initBitsBuffer = _bitsBuffer;
    final initBitsBufferLength = _bitsBufferLength;

    final paddingBits = _bitsBufferLength;
    assert(paddingBits > 0);

    var head = readBits(1);
    if (head != 1) {
      _bitsBuffer = initBitsBuffer;
      _bitsBufferLength = initBitsBufferLength;
      return 0;
    }

    for (var i = 1; i < paddingBits; ++i) {
      var tailBit = readBits(1);
      if (tailBit != 0) {
        _bitsBuffer = initBitsBuffer;
        _bitsBufferLength = initBitsBufferLength;
        return 0;
      }
    }
    assert(_bitsBufferLength == 0);

    return paddingBits;
  }

  /// Returns the internal [bytesBuffer] bytes.
  /// See [BytesBuffer.toBytes].
  Uint8List toBytes([int offset = 0, int? length]) {
    checkUnflushedBits();
    return _bytesBuffer.toBytes(offset, length);
  }

  @override
  String toString() {
    return 'BitsBuffer{unflushedBits: $_bitsBuffer, unflushedBitsLength: $unflushedBitsLength}@$_bytesBuffer';
  }
}
