import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'bytes_io.dart';
import 'extension.dart';
import 'int_codec.dart';

/// [BytesIO] implementation over [RandomAccessFile].
class BytesFileIO extends BytesIO {
  final RandomAccessFile _io;

  /// The [RandomAccessFile] of this IO.
  RandomAccessFile get randomAccessFile => _io;

  @override
  late final FileDataIntCodec bytesData;

  int _length;

  int _capacity = 0;
  int _ioCapacity;

  int _position = 0;
  int _ioPosition = 0;

  bool get _positionSynced => _position == _ioPosition;

  BytesFileIO._(this._io, this._length) : _ioCapacity = _io.lengthSync() {
    _capacity = _ioCapacity;
    bytesData = FileDataIntCodec(this);
    _ioSetPosition(0);

    if (_length > _capacity) {
      ensureCapacity(_length);
    }
  }

  BytesFileIO(RandomAccessFile io, {int? length})
      : this._(io, length ??= io.lengthSync());

  factory BytesFileIO.fromFile(File file, {int? length, bool append = true}) {
    var io = file.openSync(mode: append ? FileMode.append : FileMode.write);
    return BytesFileIO(io, length: length);
  }

  static Future<BytesFileIO> fromFileAsync(File file,
      {int? length, bool append = true}) async {
    var io = await file.open(mode: append ? FileMode.append : FileMode.write);
    return BytesFileIO(io, length: length);
  }

  @override
  int get position => _position;

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

  void _ioSetPosition(int pos) {
    _io.setPositionSync(pos);
    _ioPosition = pos;
    assert(_ioPosition == _io.positionSync());
  }

  void _ioSyncPosition() {
    if (!_positionSynced) {
      _ioSetPosition(_position);
    }
    assert(_position == _ioPosition);
    assert(_ioPosition == _io.positionSync());
  }

  int _ioReadByte() {
    var b = _io.readByteSync();
    ++_ioPosition;
    assert(_ioPosition == _io.positionSync());
    return b;
  }

  void _ioReadBytes(Uint8List bs, int off, int lng) {
    var r = _io.readIntoSync(bs, off, off + lng);
    assert(r == lng);
    _ioPosition += lng;
    assert(_ioPosition == _io.positionSync());
  }

  void _ioWriteByte(int b) {
    _io.writeByteSync(b);
    ++_ioPosition;
    assert(_ioPosition == _io.positionSync());
  }

  void _ioWriteBytes(List<int> bs, int off, int lng) {
    _io.writeFromSync(bs, off, off + lng);
    _ioPosition += lng;
    assert(_ioPosition == _io.positionSync());
  }

  @override
  void ensureCapacity(int needed) {
    if (_capacity < needed) {
      final prevCapacity = _capacity;
      final newCapacity = math.max(prevCapacity * 2, needed);

      var extra = newCapacity - prevCapacity;

      if (extra <= 1024 * 32) {
        final bsZero = Uint8List(extra);
        _ioSetPosition(prevCapacity);
        _ioWriteBytes(bsZero, 0, extra);
      } else {
        _io.truncateSync(newCapacity);

        final bsSz = 1024 * 32;
        final bsZero = Uint8List(bsSz);

        _ioSetPosition(prevCapacity);

        for (var p = prevCapacity; p < newCapacity;) {
          var lng = newCapacity - p;
          if (lng > bsSz) lng = bsSz;
          _ioWriteBytes(bsZero, 0, lng);
          p += lng;
        }
      }

      _ioSyncPosition();

      _ioCapacity = _capacity = newCapacity;
      assert(_ioCapacity == _io.lengthSync());
    }
  }

  @override
  int get capacity => _capacity;

  @override
  int get length => _length;

  @override
  void setLength(int length) {
    if (length < 0) {
      length = 0;
    } else if (length > _capacity) {
      ensureCapacity(length);
    }

    _length = length;
    if (_position > _length) {
      _position = _length;
    }
  }

  @override
  bool compact() {
    if (_length < _capacity) {
      _io.truncateSync(_length);
      _ioCapacity = _capacity = _length;
      _ioSetPosition(_position);
      return true;
    }
    return false;
  }

  /// Flushes this instance data.
  /// - Flushes [randomAccessFile].
  @override
  void flush() {
    try {
      _io.flushSync();
    } catch (_) {}
  }

  /// Returns `true` on [BytesFileIO] implementation.
  @override
  bool get supportsClosing => true;

  bool _closed = false;

  @override
  bool get isClosed => _closed;

  /// Flushes then closes this instance.
  /// - Closes [randomAccessFile].
  /// - See [isClosed].
  @override
  close() {
    flush();

    try {
      _closed = true;
      _io.closeSync();
    } catch (_) {}
  }

  @override
  void incrementPosition(int n) {
    _position += n;
    if (_position > _length) {
      _length = _position;
    }
  }

  @override
  int indexOf(int byte, [int offset = 0, int? length]) {
    if (offset >= _length) return -1;

    length ??= _length - offset;

    var end = offset + length;
    if (end > _length) {
      end = _length;
    }

    final bsSz = math.min(1024 * 4, _length - offset);
    final bs = Uint8List(bsSz);

    _ioSetPosition(offset);

    for (var p = offset; p < end;) {
      var lng = end - p;
      if (lng > bsSz) lng = bsSz;

      _ioReadBytes(bs, 0, lng);

      var idx = bs.indexOf(byte);
      if (idx >= 0 && idx < lng) {
        var idxPos = p + idx;
        return idxPos;
      }

      p += lng;
    }

    return -1;
  }

  @override
  int readByte() {
    checkCanRead(1);

    _ioSyncPosition();
    int b = _ioReadByte();
    incrementPosition(1);
    assert(_position == _ioPosition);

    return b;
  }

  @override
  int writeByte(int b) {
    ensureCapacity(_position + 1);
    _ioSyncPosition();
    _ioWriteByte(b);
    incrementPosition(1);
    assert(_position == _ioPosition);
    return 1;
  }

  @override
  Uint8List readBytes(int length) {
    checkCanRead(length);

    var bs = Uint8List(length);

    _ioSyncPosition();
    _ioReadBytes(bs, 0, length);

    incrementPosition(length);
    assert(_position == _ioPosition);

    return bs;
  }

  @override
  int writeBytes(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    ensureCapacity(_position + length);
    _ioSyncPosition();
    _ioWriteBytes(bs, offset, length);
    incrementPosition(length);
    assert(_position == _ioPosition);

    return length;
  }

  @override
  void reset() {
    _length = 0;
    _position = 0;
  }

  @override
  Uint8List toBytes([int offset = 0, int? length]) {
    length ??= _length - offset;
    if (length <= 0) {
      return Uint8List(0);
    }

    var bs = Uint8List(length);

    _ioSetPosition(offset);
    _ioReadBytes(bs, 0, length);

    return bs;
  }

  @override
  int write(List<int> list, [int offset = 0, int? length]) {
    length ??= list.length - offset;

    if (length <= 0) return 0;

    final pos = _position;
    ensureCapacity(pos + length);

    _ioSyncPosition();
    _ioWriteBytes(list, offset, length);
    incrementPosition(length);
    assert(_position == _ioPosition);

    return length;
  }

  @override
  int writeAll(List<int> list) {
    var bsLength = list.length;

    final pos = _position;
    ensureCapacity(pos + bsLength);

    _ioSyncPosition();
    _ioWriteBytes(list, 0, bsLength);
    incrementPosition(bsLength);
    assert(_position == _ioPosition);
    assert(_ioPosition == _io.positionSync());

    return bsLength;
  }

  @override
  int writeAllBytes(Uint8List bytes) {
    var bsLength = bytes.length;

    final pos = _position;
    ensureCapacity(pos + bsLength);

    _ioSyncPosition();
    _ioWriteBytes(bytes, 0, bsLength);
    incrementPosition(bsLength);
    assert(_position == _ioPosition);

    return bsLength;
  }

  @override
  Uint8List asUint8List([int offset = 0, int? length]) =>
      toBytes(offset, length);

  @override
  R bytesTo<R>(R Function(Uint8List bytes, int offset, int length) output,
      [int offset = 0, int? length]) {
    length ??= _length - offset;

    var bs = toBytes(offset, length);
    return output(bs, 0, length);
  }

  @override
  String toString() {
    return 'BytesFileIO{position: $_position ~$_ioPosition, length: $_length, capacity: $_capacity ~$_ioCapacity}@$_io';
  }
}

/// [IntCodec] implementation for [BytesFileIO].
class FileDataIntCodec extends IntCodec {
  final BytesFileIO _fileIO;
  final RandomAccessFile _io;

  final Uint8List _buffer;

  late final ByteData _bufferByteData;

  FileDataIntCodec(this._fileIO)
      : _io = _fileIO._io,
        _buffer = Uint8List(8) {
    _bufferByteData = _buffer.asByteData();
  }

  void _ioSetPosition(int position) {
    if (_fileIO._ioPosition != position) {
      _fileIO._ioSetPosition(position);
    }
  }

  void _readBufferBytes(int position, int length) {
    _ioSetPosition(position);
    _io.readIntoSync(_buffer, 0, length);
    _fileIO._ioPosition = position + length;
    assert(_fileIO._ioPosition == _io.positionSync());
  }

  ByteData _getBufferData(int position, int length) {
    _readBufferBytes(position, length);
    return _bufferByteData;
  }

  void _ioWriteBufferBytes(int position, int length) {
    _ioSetPosition(position);
    _io.writeFromSync(_buffer, 0, length);
    _fileIO._ioPosition = position + length;
    assert(_fileIO._ioPosition == _io.positionSync());
  }

  @override
  int getInt16(int position, Endian endian) =>
      _getBufferData(position, 2).getInt16(0, endian);

  @override
  int getInt32(int position, Endian endian) =>
      _getBufferData(position, 4).getInt32(0, endian);

  @override
  int getUint16(int position, Endian endian) =>
      _getBufferData(position, 2).getUint16(0, endian);

  @override
  int getUint32(int position, Endian endian) =>
      _getBufferData(position, 4).getUint32(0, endian);

  @override
  void setInt16(int position, int n, Endian endian) {
    _bufferByteData.setInt16(0, n, endian);
    _ioWriteBufferBytes(position, 2);
  }

  @override
  void setInt32(int position, int n, Endian endian) {
    _bufferByteData.setInt32(0, n, endian);
    _ioWriteBufferBytes(position, 4);
  }

  @override
  void setUint16(int position, int n, Endian endian) {
    _bufferByteData.setUint16(0, n, endian);
    _ioWriteBufferBytes(position, 2);
  }

  @override
  void setUint32(int position, int n, Endian endian) {
    _bufferByteData.setUint32(0, n, endian);
    _ioWriteBufferBytes(position, 4);
  }

  @override
  String toString() {
    return 'FileDataIntCodec@$_io';
  }
}
