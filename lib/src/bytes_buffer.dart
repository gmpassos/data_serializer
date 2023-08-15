import "dart:convert";
import 'dart:typed_data';

import 'bytes_io.dart';
import 'bytes_io_uint8list.dart';
import 'extension.dart';
import 'int_codec.dart';
import 'platform.dart';
import 'utils.dart';

final DataSerializerPlatform _platform = DataSerializerPlatform.instance;

/// Optimized buffer of [Uint8List].
class BytesBuffer {
  final BytesIO bytesIO;

  IntCodec get _bytesData => bytesIO.bytesData;

  BytesBuffer.fromIO(this.bytesIO);

  BytesBuffer([int initialCapacity = 32])
      : bytesIO = BytesUint8ListIO(initialCapacity);

  BytesBuffer.from(Uint8List bytes,
      {int offset = 0, int? length, int? bufferLength, bool copyBuffer = false})
      : bytesIO = BytesUint8ListIO.from(bytes,
            offset: offset,
            length: length,
            bufferLength: bufferLength,
            copyBuffer: copyBuffer);

  /// Returns the size of the internal bytes buffer ([Uint8List]).
  int get capacity => bytesIO.capacity;

  /// The length of bytes in this buffer.
  int get length => bytesIO.length;

  /// Returns `true` if `this` instance is empty.
  bool get isEmpty => bytesIO.isEmpty;

  /// Returns `true` if `this` instance is NOT empty.
  bool get isNotEmpty => bytesIO.isNotEmpty;

  /// The current read/write cursor position in the bytes buffer.
  int get position => bytesIO.position;

  /// The remaining bytes to read from [position] to the end of the buffer.
  int get remaining => bytesIO.remaining;

  /// Changes the read/write cursor [position].
  int seek(int position) => bytesIO.seek(position);

  /// Flushes [bytesIO] data.
  void flush() => bytesIO.flush();

  /// Returns `true` if [bytesIO] is closed.
  /// - See [close].
  bool get isClosed => bytesIO.isClosed;

  /// Closes [bytesIO].
  void close() => bytesIO.close();

  /// Writes 1 byte. Increments [position] by 1.
  int writeByte(int b) => bytesIO.writeByte(b);

  /// Reads 1 byte. Increments [position] by 1.
  int readByte() => bytesIO.readByte();

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
  int writeAll(List<int> list) => bytesIO.writeAll(list);

  /// Writes the `int` at [list] as bytes, respecting [offset] and [length] parameters.
  int write(List<int> list, [int offset = 0, int? length]) =>
      bytesIO.write(list, offset, length);

  /// Writes all the [bytes] into this buffer.
  int writeAllBytes(Uint8List bytes) => bytesIO.writeAllBytes(bytes);

  /// Writes the [bytes] into this buffer, respecting [offset] and [length] parameters.
  int writeBytes(Uint8List bs, [int offset = 0, int? length]) =>
      bytesIO.writeBytes(bs, offset, length);

  /// Reads an [Uint8List] of [length].
  Uint8List readBytes(int length) => bytesIO.readBytes(length);

  /// Reads the remaining bytes.
  /// See [remaining] and [readBytes].
  Uint8List readRemainingBytes() => readBytes(remaining);

  /// Writes a blocks of data using a 32-bit integer as length prefix.
  int writeBlock32(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    final pos = position;
    bytesIO.ensureCapacity(pos + 4 + length);

    var sz = writeUint32(length);
    writeBytes(bs, offset, length);

    return sz + length;
  }

  /// Reads a blocks of data that uses a 32-bit integer as length prefix.
  Uint8List readBlock32() {
    bytesIO.checkCanRead(4);
    var sz = _bytesData.getUint32(position, Endian.big);
    bytesIO.incrementPosition(4);
    return readBytes(sz);
  }

  /// Writes a blocks of data using a 16-bit integer as length prefix.
  int writeBlock16(Uint8List bs, [int offset = 0, int? length]) {
    length ??= bs.length - offset;

    final pos = position;
    bytesIO.ensureCapacity(pos + 2 + length);

    var sz = writeUint16(length);
    bytesIO.writeBytes(bs, offset, length);

    return sz + length;
  }

  /// Reads a blocks of data that uses a 16-bit integer as length prefix.
  Uint8List readBlock16() {
    bytesIO.checkCanRead(2);
    var sz = _bytesData.getUint16(position, Endian.big);
    bytesIO.incrementPosition(2);
    return readBytes(sz);
  }

  /// Writes a lists of bytes blocks. Uses [writeBlock32].
  int writeBlocks(Iterable<Uint8List> blocks) {
    var blocksSz = blocks.isEmpty
        ? 0
        : blocks
            .map((e) => e.length)
            .reduce((value, element) => value + 4 + element);

    final writeSz = 4 + 4 + blocksSz;
    bytesIO.ensureCapacity(bytesIO.position + writeSz);

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

    bytesIO.ensureCapacity(position + 4 + (length * 8));

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
    final pos = bytesIO.position;
    bytesIO.ensureCapacity(pos + 2);
    _bytesData.setInt16(pos, n, endian);
    bytesIO.incrementPosition(2);
    return 2;
  }

  /// Reads an [Int16].
  int readInt16([Endian endian = Endian.big]) {
    bytesIO.checkCanRead(2);
    final pos = bytesIO.position;
    var n = _bytesData.getInt16(pos, endian);
    bytesIO.incrementPosition(2);
    return n;
  }

  /// Writes an [Uint16].
  int writeUint16(int n, [Endian endian = Endian.big]) {
    final pos = bytesIO.position;
    bytesIO.ensureCapacity(pos + 2);
    _bytesData.setUint16(pos, n, endian);
    bytesIO.incrementPosition(2);
    return 2;
  }

  /// Reads an [Uint16].
  int readUint16([Endian endian = Endian.big]) {
    bytesIO.checkCanRead(2);
    final pos = bytesIO.position;
    var n = _bytesData.getUint16(pos, endian);
    bytesIO.incrementPosition(2);
    return n;
  }

  /// Writes an [Int32].
  int writeInt32(int n, [Endian endian = Endian.big]) {
    final pos = bytesIO.position;
    bytesIO.ensureCapacity(pos + 4);
    _bytesData.setInt32(pos, n, endian);
    bytesIO.incrementPosition(4);
    return 4;
  }

  /// Reads an [Int32].
  int readInt32([Endian endian = Endian.big]) {
    bytesIO.checkCanRead(4);
    final pos = bytesIO.position;
    var n = _bytesData.getInt32(pos, endian);
    bytesIO.incrementPosition(4);
    return n;
  }

  /// Writes an [Uint32].
  int writeUint32(int n, [Endian endian = Endian.big]) {
    final pos = bytesIO.position;
    bytesIO.ensureCapacity(pos + 4);
    _bytesData.setUint32(pos, n, endian);
    bytesIO.incrementPosition(4);
    return 4;
  }

  /// Reads an [Uint32].
  int readUint32([Endian endian = Endian.big]) {
    bytesIO.checkCanRead(4);
    final pos = bytesIO.position;
    var n = _bytesData.getUint32(pos, endian);
    bytesIO.incrementPosition(4);
    return n;
  }

  /// Writes an [Int64].
  int writeInt64(int n, [Endian endian = Endian.big]) {
    final pos = bytesIO.position;
    bytesIO.ensureCapacity(pos + 8);
    _platform.setDataTypeHandlerInt64(_bytesData, n, pos);
    bytesIO.incrementPosition(8);
    return 8;
  }

  /// Reads an [Int64].
  int readInt64([Endian endian = Endian.big]) {
    bytesIO.checkCanRead(8);
    final pos = bytesIO.position;
    var n = _platform.getDataTypeHandlerInt64(_bytesData, pos);
    bytesIO.incrementPosition(8);
    return n;
  }

  /// Writes an [Uint64].
  int writeUint64(int n, [Endian endian = Endian.big]) {
    final pos = bytesIO.position;
    bytesIO.ensureCapacity(pos + 8);
    _platform.setDataTypeHandlerUint64(_bytesData, n, pos);
    bytesIO.incrementPosition(8);
    return 8;
  }

  /// Reads an [Uint64].
  int readUint64([Endian endian = Endian.big]) {
    bytesIO.checkCanRead(8);
    final pos = bytesIO.position;
    var n = _platform.getDataTypeHandlerUint64(_bytesData, pos);
    bytesIO.incrementPosition(8);
    return n;
  }

  /// Writes a [BigInt]. See [BigIntExtension.toBytes] for encoding description.
  int writeBigInt(BigInt n) {
    return n.writeTo(this);
  }

  /// Reads a [BigInt]. See [BigIntExtension.toBytes] for encoding description.
  BigInt readBigInt() {
    bytesIO.checkCanRead(5);

    try {
      final pos0 = bytesIO.position;

      final b0 = readByte();
      if (b0 == 0) {
        var n = readInt32();
        var bigInt = BigInt.from(n);
        return bigInt;
      } else {
        seek(pos0);
        var sz = -readInt32();
        var bs = readBytes(sz);
        var s = latin1.decode(bs);
        var bigInt = BigInt.parse(s);
        return bigInt;
      }
    } catch (_) {
      throw BytesBufferEOF();
    }
  }

  /// Writes a [DateTime].
  int writeDateTime(DateTime dateTime) => dateTime.writeTo(this);

  /// Reads a [DateTime].
  DateTime readDateTime() {
    var t = readInt64();
    return DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
  }

  /// Sets the [length] of this buffer. Increases internal bytes buffer [capacity] if needed.
  void setLength(int length) => bytesIO.setLength(length);

  /// Resets this buffer. Sets the [length] and [position] to `0`.
  void reset() => bytesIO.reset();

  /// Compact the internal bytes [capacity] to [length].
  bool compact() => bytesIO.compact();

  /// Returns `this` instance as a [Uint8List]. Returns the internal `bytes`
  /// buffer if the [length] and [capacity] is the same, otherwise creates a
  /// copy with the exact [length].
  Uint8List asUint8List([int offset = 0, int? length]) =>
      bytesIO.asUint8List(offset, length);

  /// Returns a copy of the internal bytes ([Uint8List]) of `this` instance.
  Uint8List toBytes([int offset = 0, int? length]) =>
      bytesIO.toBytes(offset, length);

  /// Calls the function [output] with the internal bytes of this instance.
  R bytesTo<R>(R Function(Uint8List bytes, int offset, int length) output,
          [int offset = 0, int? length]) =>
      bytesIO.bytesTo(output, offset, length);

  /// Returns the index of [byte] inf [offset] and [length] range.
  int indexOf(int byte, [int offset = 0, int? length]) =>
      bytesIO.indexOf(byte, offset, length);

  @override
  String toString() {
    return 'BytesBuffer@$bytesIO';
  }
}
