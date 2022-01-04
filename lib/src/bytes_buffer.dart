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

  int get capacity => _bytes.length;

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  int get position => _position;

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

  int writeByte(int b) {
    _ensureCapacity(_position + 1);

    _bytes[_position] = b;
    _incrementPosition(1);

    return 1;
  }

  int readByte() {
    _checkCanRead(1);
    var b = _bytes[_position];
    _incrementPosition(1);
    return b;
  }

  int writeBoolean(bool b) => writeByte(b ? 1 : 0);

  bool readBoolean() => readByte() != 0;

  int writeEnum<E extends Enum>(E e) {
    var index = e.index;
    if (index > 255) {
      throw StateError("Can't write an enum of index > 255: $index");
    }
    writeByte(index);
    return 1;
  }

  E readEnum<E extends Enum>(List<E> enumValues) {
    var idx = readByte();
    return enumValues[idx];
  }

  int writeAll(List<int> bs) {
    var bsLength = bs.length;

    _ensureCapacity(_position + bsLength);

    _bytes.setAll(_position, bs);
    _incrementPosition(bsLength);

    return bsLength;
  }

  int write(List<int> bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + length);

    _bytes.setRange(_position, _position + length, bs, offset);
    _incrementPosition(length);

    return length;
  }

  int writeAllBytes(Uint8List bs) {
    var length = bs.length;

    _ensureCapacity(_position + length);

    _bytes.setAll(_position, bs);
    _incrementPosition(length);

    return length;
  }

  int writeBytes(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + length);

    _bytes.setRange(_position, _position + length, bs, offset);
    _incrementPosition(length);

    return length;
  }

  Uint8List readBytes(int length) {
    _checkCanRead(length);
    var bs = _bytes.sublist(_position, _position + length);
    _incrementPosition(length);
    return bs;
  }

  Uint8List readRemainingBytes() => readBytes(remaining);

  void _checkCanRead(int length) {
    if (_position + length > _length) {
      throw BytesBufferEOF();
    }
  }

  int writeBlock32(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + 4 + length);

    var sz = writeUint32(length);
    writeBytes(bs, offset, length);

    return sz + length;
  }

  Uint8List readBlock32() {
    _checkCanRead(4);
    var sz = _bytesData.getUint32(_position);
    _incrementPosition(4);
    return readBytes(sz);
  }

  int writeBlock16(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    _ensureCapacity(_position + 2 + length);

    var sz = writeUint16(length);
    writeBytes(bs, offset, length);

    return sz + length;
  }

  Uint8List readBlock16() {
    _checkCanRead(2);
    var sz = _bytesData.getUint16(_position);
    _incrementPosition(2);
    return readBytes(sz);
  }

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

  List<Uint8List> readBlocks() {
    var sz = readInt32();
    var blocks = List.generate(sz, (i) => readBlock32());
    return blocks;
  }

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

  List<W> readWritables<W extends Writable>(
      W Function(BytesBuffer input) reader) {
    var sz = readInt32();
    var list = List.generate(sz, (i) => reader(this));
    return list;
  }

  int writeWritable(Writable writable) => writable.writeTo(this);

  W readWritable<W extends Writable>(W Function(BytesBuffer input) reader) =>
      reader(this);

  int writeString(String s) {
    var bs = s.encodeUTF8Bytes();
    var length = bs.length;
    writeInt32(length);
    writeAll(bs);
    return 4 + length;
  }

  String readString() {
    var bs = readBlock32();
    var s = utf8.decode(bs);
    return s;
  }

  int writeInt16(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 2);
    _bytesData.setInt16(_position, n, endian);
    _incrementPosition(2);
    return 2;
  }

  int readInt16([Endian endian = Endian.big]) {
    _checkCanRead(2);
    var n = _bytesData.getInt16(_position, endian);
    _incrementPosition(2);
    return n;
  }

  int writeUint16(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 2);
    _bytesData.setUint16(_position, n, endian);
    _incrementPosition(2);
    return 2;
  }

  int readUint16([Endian endian = Endian.big]) {
    _checkCanRead(2);
    var n = _bytesData.getUint16(_position, endian);
    _incrementPosition(2);
    return n;
  }

  int writeInt32(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 4);
    _bytesData.setInt32(_position, n, endian);
    _incrementPosition(4);
    return 4;
  }

  int readInt32([Endian endian = Endian.big]) {
    _checkCanRead(4);
    var n = _bytesData.getInt32(_position, endian);
    _incrementPosition(4);
    return n;
  }

  int writeUint32(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 4);
    _bytesData.setUint32(_position, n, endian);
    _incrementPosition(4);
    return 4;
  }

  int readUint32([Endian endian = Endian.big]) {
    _checkCanRead(4);
    var n = _bytesData.getUint32(_position, endian);
    _incrementPosition(4);
    return n;
  }

  int writeInt64(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 8);
    _platform.setInt64(_bytesData, n, _position);
    _incrementPosition(8);
    return 8;
  }

  int readInt64([Endian endian = Endian.big]) {
    _checkCanRead(8);
    var n = _platform.getInt64(_bytesData, _position);
    _incrementPosition(8);
    return n;
  }

  int writeUint64(int n, [Endian endian = Endian.big]) {
    _ensureCapacity(_position + 8);
    _platform.setUint64(_bytesData, n, _position);
    _incrementPosition(8);
    return 8;
  }

  int readUint64([Endian endian = Endian.big]) {
    _checkCanRead(8);
    var n = _platform.getUint64(_bytesData, _position);
    _incrementPosition(8);
    return n;
  }

  int writeBigInt(BigInt n) {
    return n.writeTo(this);
  }

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

  int writeDateTime(DateTime time) => time.writeTo(this);

  DateTime readDateTime() {
    _checkCanRead(8);
    var t = _bytes.readDateTime(_position);
    _incrementPosition(8);
    return t;
  }

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

  void reset() {
    _length = 0;
    _position = 0;
  }

  bool compact() {
    if (_length < _bytes.length) {
      _bytes = _bytes.sublist(0, _length);
      _bytesData = _bytes.asByteData();
      return true;
    }
    return false;
  }

  Uint8List toUint8List([int offset = 0, int? length]) =>
      _fromUint8List(_bytes, offset, length, _length);

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
