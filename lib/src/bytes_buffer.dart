import "dart:convert";
import "dart:math" as math;
import 'dart:typed_data';

import 'extension.dart';
import 'platform.dart';
import 'utils.dart';

final DataSerializerPlatform _platform = DataSerializerPlatform.instance;

/// Optimized buffer of [Uint8List].
class BytesBuffer {
  Uint8List _bytes;
  late ByteData _bytesData;
  int _length = 0;
  int _position = 0;

  BytesBuffer([int initialCapacity = 32])
      : _bytes = Uint8List(initialCapacity) {
    _bytesData = _bytes.asByteData();
  }

  BytesBuffer.from(Uint8List bytes,
      {int offset = 0, int? length, int? bufferLength, bool copyBuffer = false})
      : _bytes = _fromUint8List(bytes, offset, length) {
    _length = bufferLength ?? _bytes.length;
    _bytesData = _bytes.asByteData();
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

  /// Returns the size of the internal bytes buffer ([Uint8List]).
  int get capacity => _bytes.length;

  /// The length of bytes in this buffer.
  int get length => _length;

  /// Returns `true` if `this` instance is empty.
  bool get isEmpty => _length == 0;

  /// Returns `true` if `this` instance is NOT empty.
  bool get isNotEmpty => _length != 0;

  /// The current read/write cursor position in the bytes buffer.
  int get position => _position;

  /// The remaining bytes to read from [position] to the end of the buffer.
  int get remaining => _length - _position;

  void _ensureCapacity(int needed) {
    if (capacity < needed) {
      var newCapacity = math.max(capacity * 2, needed);
      var bs = Uint8List(newCapacity);
      bs.setAll(0, _bytes);
      _bytes = bs;
      _bytesData = _bytes.asByteData();
    }
  }

  /// Changes the read/write cursor [position].
  int seek(int position) {
    if (position < 0) {
      position = 0;
    } else if (position > _length) {
      position = _length;
    }
    _position = position;
    return position;
  }

  void _incrementPosition(int length) {
    _position += length;
    if (_position > _length) {
      _length = _position;
    }
  }

  /// Writes 1 byte. Increments [position] by 1.
  int writeByte(int b) {
    _ensureCapacity(_position + 1);

    _bytes[_position] = b;
    _incrementPosition(1);

    return 1;
  }

  /// Reads 1 byte. Increments [position] by 1.
  int readByte() {
    _checkCanRead(1);
    var b = _bytes[_position];
    _incrementPosition(1);
    return b;
  }

  /// Writes 1 boolean byte. Increments [position] by 1.
  int writeBoolean(bool b) => writeByte(b ? 1 : 0);

  /// Reads 1 boolean byte. Increments [position] by 1.
  bool readBoolean() => readByte() != 0;

  /// Writes an enum [e] index. Increments [position] by 1.
  ///
  /// - It won't allow `enum`s with more than 255 values.
  int writeEnum<E extends Enum>(E e) {
    var index = e.index;
    if (index > 255) {
      throw StateError("Can't write an enum of index > 255: $index");
    }
    writeByte(index);
    return 1;
  }

  /// Reads an enum index, and returns a value from [enumValues].
  /// Increments [position] by 1.
  E readEnum<E extends Enum>(List<E> enumValues) {
    var idx = readByte();
    return enumValues[idx];
  }

  /// Writes all the `int` at [list] as bytes.
  int writeAll(List<int> list) {
    var bsLength = list.length;

    _ensureCapacity(_position + bsLength);

    _bytes.setAll(_position, list);
    _incrementPosition(bsLength);

    return bsLength;
  }

  /// Writes the `int` at [list] as bytes, respecting [offset] and [length] parameters.
  int write(List<int> list, [int offset = 0, int? length]) {
    length ??= list.length - offset;

    _ensureCapacity(_position + length);

    _bytes.setRange(_position, _position + length, list, offset);
    _incrementPosition(length);

    return length;
  }

  /// Writes all the [bytes] into this buffer.
  int writeAllBytes(Uint8List bytes) {
    var length = bytes.length;

    _ensureCapacity(_position + length);

    _bytes.setAll(_position, bytes);
    _incrementPosition(length);

    return length;
  }

  /// Writes the [bytes] into this buffer, respecting [offset] and [length] parameters.
  int writeBytes(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + length);

    _bytes.setRange(_position, _position + length, bs, offset);
    _incrementPosition(length);

    return length;
  }

  /// Reads an [Uint8List] of [length].
  Uint8List readBytes(int length) {
    _checkCanRead(length);
    var bs = _bytes.sublist(_position, _position + length);
    _incrementPosition(length);
    return bs;
  }

  /// Reads the remaining bytes.
  /// See [remaining] and [readBytes].
  Uint8List readRemainingBytes() => readBytes(remaining);

  void _checkCanRead(int length) {
    if (_position + length > _length) {
      throw BytesBufferEOF();
    }
  }

  /// Writes a blocks of data using a 32-bit integer as length prefix.
  int writeBlock32(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + 4 + length);

    var sz = writeUint32(length);
    writeBytes(bs, offset, length);

    return sz + length;
  }

  /// Reads a blocks of data that uses a 32-bit integer as length prefix.
  Uint8List readBlock32() {
    _checkCanRead(4);
    var sz = _bytesData.getUint32(_position);
    _incrementPosition(4);
    return readBytes(sz);
  }

  /// Writes a blocks of data using a 16-bit integer as length prefix.
  int writeBlock16(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + 2 + length);

    var sz = writeUint16(length);
    writeBytes(bs, offset, length);

    return sz + length;
  }

  /// Reads a blocks of data that uses a 16-bit integer as length prefix.
  Uint8List readBlock16() {
    _checkCanRead(2);
    var sz = _bytesData.getUint16(_position);
    _incrementPosition(2);
    return readBytes(sz);
  }

  /// Writes a lists of bytes blocks. Uses [writeBlock32].
  int writeBlocks(Iterable<Uint8List> blocks) {
    var blocksSz = blocks.isEmpty
        ? 0
        : blocks
            .map((e) => e.length)
            .reduce((value, element) => value + 4 + element);
    _ensureCapacity(_position + 4 + blocksSz);

    writeInt32(blocks.length);
    var sz = 4;

    for (var block in blocks) {
      sz += writeBlock32(block);
    }

    return sz;
  }

  /// Reads a lists of bytes blocks. Uses [readBlock32].
  List<Uint8List> readBlocks() {
    var sz = readInt32();
    var blocks = List.generate(sz, (i) => readBlock32());
    return blocks;
  }

  /// Writes a [list] of [Writable].
  int writeWritables(Iterable<Writable> list) {
    var length = list.length;

    _ensureCapacity(_position + 4 + (length * 8));

    writeInt32(length);
    var sz = 4;

    for (var e in list) {
      sz += e.writeTo(this);
    }

    return sz;
  }

  /// Reads a list of [Writable] using the [reader] function to instantiate the [W] elements.
  List<W> readWritables<W extends Writable>(
      W Function(BytesBuffer input) reader) {
    var sz = readInt32();
    var list = List.generate(sz, (i) => reader(this));
    return list;
  }

  /// Writes a [writable]. See [Writable].
  int writeWritable(Writable writable) => writable.writeTo(this);

  /// Reads a [Writable] using the [reader] function to instantiate the [W] instance.
  W readWritable<W extends Writable>(W Function(BytesBuffer input) reader) =>
      reader(this);

  /// Writes a [String] using `UTF-8` encoding.
  int writeString(String s) {
    var bs = s.encodeUTF8Bytes();
    var length = bs.length;
    writeInt32(length);
    writeAll(bs);
    return 4 + length;
  }

  /// Reads a [String] using `UTF-8` decoding.
  String readString() {
    var bs = readBlock32();
    var s = utf8.decode(bs);
    return s;
  }

  /// Writes an [Int16].
  int writeInt16(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 2);
    _bytesData.setInt16(_position, n, endian);
    _incrementPosition(2);
    return 2;
  }

  /// Reads an [Int16].
  int readInt16([Endian endian = Endian.big]) {
    _checkCanRead(2);
    var n = _bytesData.getInt16(_position, endian);
    _incrementPosition(2);
    return n;
  }

  /// Writes an [Uint16].
  int writeUint16(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 2);
    _bytesData.setUint16(_position, n, endian);
    _incrementPosition(2);
    return 2;
  }

  /// Reads an [Uint16].
  int readUint16([Endian endian = Endian.big]) {
    _checkCanRead(2);
    var n = _bytesData.getUint16(_position, endian);
    _incrementPosition(2);
    return n;
  }

  /// Writes an [Int32].
  int writeInt32(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 4);
    _bytesData.setInt32(_position, n, endian);
    _incrementPosition(4);
    return 4;
  }

  /// Reads an [Int32].
  int readInt32([Endian endian = Endian.big]) {
    _checkCanRead(4);
    var n = _bytesData.getInt32(_position, endian);
    _incrementPosition(4);
    return n;
  }

  /// Writes an [Uint32].
  int writeUint32(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 4);
    _bytesData.setUint32(_position, n, endian);
    _incrementPosition(4);
    return 4;
  }

  /// Reads an [Uint32].
  int readUint32([Endian endian = Endian.big]) {
    _checkCanRead(4);
    var n = _bytesData.getUint32(_position, endian);
    _incrementPosition(4);
    return n;
  }

  /// Writes an [Int64].
  int writeInt64(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 8);
    _platform.setInt64(_bytesData, n, _position);
    _incrementPosition(8);
    return 8;
  }

  /// Reads an [Int64].
  int readInt64([Endian endian = Endian.big]) {
    _checkCanRead(8);
    var n = _platform.getInt64(_bytesData, _position);
    _incrementPosition(8);
    return n;
  }

  /// Writes an [Uint64].
  int writeUint64(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 8);
    _platform.setUint64(_bytesData, n, _position);
    _incrementPosition(8);
    return 8;
  }

  /// Reads an [Uint64].
  int readUint64([Endian endian = Endian.big]) {
    _checkCanRead(8);
    var n = _platform.getUint64(_bytesData, _position);
    _incrementPosition(8);
    return n;
  }

  /// Writes a [BigInt]. See [BigIntExtension.toBytes] for encoding description.
  int writeBigInt(BigInt n) {
    return n.writeTo(this);
  }

  /// Reads a [BigInt]. See [BigIntExtension.toBytes] for encoding description.
  BigInt readBigInt() {
    _checkCanRead(5);
    try {
      var ret = _bytes.readBigInt(_position);
      var sz = ret.key;
      _checkCanRead(sz);
      var bigInt = ret.value;
      _incrementPosition(sz);
      return bigInt;
    } catch (_) {
      throw BytesBufferEOF();
    }
  }

  /// Writes a [DateTime].
  int writeDateTime(DateTime time) => time.writeTo(this);

  /// Reads a [DateTime].
  DateTime readDateTime() {
    _checkCanRead(8);
    var t = _bytes.readDateTime(_position);
    _incrementPosition(8);
    return t;
  }

  /// Sets the [length] of this buffer. Increases internal bytes buffer [capacity] if needed.
  void setLength(int length) {
    if (length < 0) {
      length = 0;
    } else if (length > _bytes.length) {
      _ensureCapacity(length);
    }
    _length = length;
    if (_position > _length) {
      _position = _length;
    }
  }

  /// Resets this buffer. Sets the [length] and [position] to `0`.
  void reset() {
    _length = 0;
    _position = 0;
  }

  /// Compact the internal bytes [capacity] to [length].
  bool compact() {
    if (_length < _bytes.length) {
      _bytes = _bytes.sublist(0, _length);
      _bytesData = _bytes.asByteData();
      return true;
    }
    return false;
  }

  /// Returns `this` instance as a [Uint8List]. Returns the internal `bytes`
  /// buffer if the [length] and [capacity] is the same, otherwise creates a
  /// copy with the exact [length].
  Uint8List asUint8List([int offset = 0, int? length]) =>
      _fromUint8List(_bytes, offset, length, _length);

  /// Returns a copy of the internal bytes ([Uint8List]) of `this` instance.
  Uint8List toBytes([int offset = 0, int? length]) =>
      _fromUint8List(_bytes, offset, length, _length, true);

  /// Calls the function [output] with the internal bytes of this instance.
  void bytesTo(void Function(Uint8List bytes, int offset, int length) output,
      [int offset = 0, int? length]) {
    length ??= _length - offset;

    output(_bytes, offset, length);
  }

  @override
  String toString() {
    return 'BytesBuffer{position: $_position, length: $_length, capacity: $capacity}';
  }
}

class BytesBufferError extends Error {
  final String message;

  BytesBufferError(this.message);

  @override
  String toString() => "BytesBuffer error: $message";
}

class BytesBufferEOF extends BytesBufferError {
  BytesBufferEOF() : super('End of buffer');
}
