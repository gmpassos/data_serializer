import "dart:math" as math;
import 'dart:typed_data';

import 'bytes_io.dart';
import 'extension.dart';
import 'int_codec.dart';

/// [BytesIO] implementation using [Uint8List].
class BytesUint8ListIO extends BytesIO {
  Uint8List _bytes;

  @override
  late IntCodec bytesData;
  int _length = 0;
  int _position = 0;

  BytesUint8ListIO([int initialCapacity = 32])
      : _bytes = Uint8List(initialCapacity) {
    bytesData = ByteDataIntCodec(_bytes.asByteData());
  }

  BytesUint8ListIO.from(Uint8List bytes,
      {int offset = 0, int? length, int? bufferLength, bool copyBuffer = false})
      : _bytes = _fromUint8List(bytes, offset, length) {
    _length = bufferLength ?? _bytes.length;
    bytesData = ByteDataIntCodec(_bytes.asByteData());
  }

  static Uint8List _fromUint8List(Uint8List bytes,
      [int offset = 0, int? length, int? bytesLength, bool copy = false]) {
    length ??= (bytesLength ?? bytes.length) - offset;

    if (offset == 0 && length == bytes.length) {
      return copy ? bytes.copy() : bytes;
    } else {
      return bytes.sublist(offset, offset + length);
    }
  }

  @override
  int get capacity => _bytes.length;

  @override
  int get length => _length;

  @override
  int get position => _position;

  @override
  void ensureCapacity(int needed) {
    if (capacity < needed) {
      var newCapacity = math.max(capacity * 2, needed);
      var bs = Uint8List(newCapacity);
      bs.setAll(0, _bytes);
      _bytes = bs;
      bytesData = ByteDataIntCodec(_bytes.asByteData());
    }
  }

  @override
  int seek(int position) {
    if (position < 0) {
      position = 0;
    } else if (position > _length) {
      position = _length;
    }
    _position = position;
    return position;
  }

  @override
  void incrementPosition(int n) {
    _position += n;
    if (_position > _length) {
      _length = _position;
    }
  }

  @override
  void setLength(int length) {
    if (length < 0) {
      length = 0;
    } else if (length > _bytes.length) {
      ensureCapacity(length);
    }

    _length = length;
    if (_position > _length) {
      _position = _length;
    }
  }

  @override
  void reset() {
    _length = 0;
    _position = 0;
  }

  @override
  bool compact() {
    if (_length < _bytes.length) {
      _bytes = _bytes.sublist(0, _length);
      bytesData = ByteDataIntCodec(_bytes.asByteData());
      return true;
    }
    return false;
  }

  /// Has no effect on [BytesUint8ListIO] implementation.
  @override
  void flush() {}

  /// Returns `false` on [BytesUint8ListIO] implementation.
  @override
  bool get supportsClosing => false;

  /// Always return `false` on [BytesUint8ListIO] implementation.
  @override
  bool get isClosed => false;

  /// Has no effect on [BytesUint8ListIO] implementation.
  @override
  close() {}

  @override
  int writeByte(int b) {
    final pos = _position;
    ensureCapacity(pos + 1);

    _bytes[pos] = b;
    incrementPosition(1);

    return 1;
  }

  @override
  int readByte() {
    checkCanRead(1);
    var b = _bytes[_position];
    incrementPosition(1);
    return b;
  }

  @override
  int write(List<int> list, [int offset = 0, int? length]) {
    length ??= list.length - offset;

    final pos = _position;
    ensureCapacity(pos + length);

    _bytes.setRange(pos, pos + length, list, offset);
    incrementPosition(length);

    return length;
  }

  @override
  Uint8List readBytes(int length) {
    checkCanRead(length);

    final pos = _position;
    var bs = _bytes.sublist(pos, pos + length);

    incrementPosition(length);
    return bs;
  }

  @override
  int writeBytes(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    final pos = _position;
    ensureCapacity(pos + length);

    _bytes.setRange(pos, pos + length, bs, offset);
    incrementPosition(length);

    return length;
  }

  @override
  int writeAllBytes(Uint8List bytes) {
    var length = bytes.length;

    final pos = _position;
    ensureCapacity(pos + length);

    _bytes.setAll(pos, bytes);
    incrementPosition(length);

    return length;
  }

  @override
  int writeAll(List<int> list) {
    var bsLength = list.length;

    final pos = _position;
    ensureCapacity(pos + bsLength);

    _bytes.setAll(pos, list);
    incrementPosition(bsLength);

    return bsLength;
  }

  @override
  int readTo(BytesIO io, [int? length]) {
    length ??= remaining;

    if (io is BytesUint8ListIO) {
      final bytes = _bytes;
      final bytes2 = io._bytes;

      final offset = _position;
      final offset2 = io._position;

      for (var i = 0; i < length; ++i) {
        var b = bytes[offset + i];
        bytes2[offset2 + i] = b;
      }

      incrementPosition(length);
      io.incrementPosition(length);

      return length;
    } else {
      var bs = readBytes(length);
      io.writeAll(bs);
      return bs.length;
    }
  }

  @override
  int writeFrom(BytesIO io, [int? length]) {
    length ??= io.remaining;

    if (io is BytesUint8ListIO) {
      final bytes = _bytes;
      final bytes2 = io._bytes;

      final offset = _position;
      final offset2 = io._position;

      for (var i = 0; i < length; ++i) {
        var b = bytes2[offset2 + i];
        bytes[offset + i] = b;
      }

      incrementPosition(length);
      io.incrementPosition(length);

      return length;
    } else {
      var bs = io.readBytes(length);
      writeAll(bs);
      return bs.length;
    }
  }

  @override
  Uint8List asUint8List([int offset = 0, int? length]) =>
      _fromUint8List(_bytes, offset, length, _length);

  @override
  Uint8List toBytes([int offset = 0, int? length]) =>
      _fromUint8List(_bytes, offset, length, _length, true);

  @override
  R bytesTo<R>(R Function(Uint8List bytes, int offset, int length) output,
      [int offset = 0, int? length]) {
    length ??= _length - offset;

    return output(_bytes, offset, length);
  }

  @override
  int indexOf(int byte, [int offset = 0, int? length]) {
    if (offset >= _length) return -1;

    length ??= _length - offset;

    var end = offset + length;
    if (end > _length) {
      end = _length;
    }

    if (end == _bytes.length) {
      return _bytes.indexOf(byte, offset);
    }

    for (var i = offset; i < end; ++i) {
      var b = _bytes[i];
      if (b == byte) return i;
    }

    return -1;
  }

  @override
  String toString() {
    return 'BytesUint8ListIO{position: $position, length: $length, capacity: $capacity}';
  }
}
