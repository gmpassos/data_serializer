import 'dart:typed_data';

import 'extension.dart';
import 'int_codec.dart';
import 'platform.dart';

class DataSerializerPlatformIO extends DataSerializerPlatform {
  DataSerializerPlatformIO() : super.base();

  static final int _maxSafeInt = 9223372036854775807;

  static final int _minSafeInt = -9223372036854775808;

  static final Uint8List _maxSafeIntBytes =
      _maxSafeInt.toUint8List64().asUnmodifiableView();

  static final Uint8List _minSafeIntBytes =
      _minSafeInt.toUint8List64().asUnmodifiableView();

  @override
  int get maxSafeInt => _maxSafeInt;

  @override
  int get minSafeInt => _minSafeInt;

  @override
  Uint8List get maxSafeIntBytes => _maxSafeIntBytes;

  @override
  Uint8List get minSafeIntBytes => _minSafeIntBytes;

  @override
  int get safeIntBits => 64;

  @override
  bool get supportsFullBitsShift => true;

  @override
  bool get supportsFullInt64 => true;

  @override
  bool isSafeInteger(int n) => true;

  @override
  void setUint64(ByteData data, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      data.setUint64(offset, n, endian);

  @override
  void setInt64(ByteData data, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      data.setInt64(offset, n, endian);

  @override
  int getUint64(ByteData data, [int offset = 0, Endian endian = Endian.big]) =>
      data.getUint64(offset, endian);

  @override
  int getInt64(ByteData data, [int offset = 0, Endian endian = Endian.big]) =>
      data.getInt64(offset, endian);

  @override
  void writeUint64(Uint8List out, int n,
      [int offset = 0, Endian endian = Endian.big]) {
    out.asByteData().setUint64(offset, n, endian);
  }

  @override
  void writeInt64(Uint8List out, int n,
      [int offset = 0, Endian endian = Endian.big]) {
    out.asByteData().setInt64(offset, n, endian);
  }

  @override
  int readUint64(Uint8List out, [int offset = 0, Endian endian = Endian.big]) {
    return out.asByteData().getUint64(offset, endian);
  }

  @override
  int readInt64(Uint8List out, [int offset = 0, Endian endian = Endian.big]) {
    return out.asByteData().getInt64(offset, endian);
  }

  @override
  int getDataTypeHandlerInt64(IntCodec data,
      [int offset = 0, Endian endian = Endian.big]) {
    var n0 = data.getUint32(offset, endian);
    var n1 = data.getUint32(offset + 4, endian);
    if (endian.isLittleEndian) {
      var tmp = n0;
      n0 = n1;
      n1 = tmp;
    }
    var n = (n0 << 32) | n1;
    return n;
  }

  @override
  int getDataTypeHandlerUint64(IntCodec data,
      [int offset = 0, Endian endian = Endian.big]) {
    var n0 = data.getUint32(offset, endian);
    var n1 = data.getUint32(offset + 4, endian);
    if (endian.isLittleEndian) {
      var tmp = n0;
      n0 = n1;
      n1 = tmp;
    }
    var n = (n0 << 32) | n1;
    return n;
  }

  @override
  void setDataTypeHandlerInt64(IntCodec data, int n,
      [int offset = 0, Endian endian = Endian.big]) {
    var n0 = (n >> 32) & 0xFFFFFFFF;
    var n1 = n & 0xFFFFFFFF;
    if (endian.isLittleEndian) {
      var tmp = n0;
      n0 = n1;
      n1 = tmp;
    }
    data.setUint32(offset, n0, endian);
    data.setUint32(offset + 4, n1, endian);
  }

  @override
  void setDataTypeHandlerUint64(IntCodec data, int n,
      [int offset = 0, Endian endian = Endian.big]) {
    var n0 = (n >> 32) & 0xFFFFFFFF;
    var n1 = n & 0xFFFFFFFF;
    if (endian.isLittleEndian) {
      var tmp = n0;
      n0 = n1;
      n1 = tmp;
    }
    data.setUint32(offset, n0, endian);
    data.setUint32(offset + 4, n1, endian);
  }

  @override
  int shiftRightInt(int n, int shift) {
    return n >> shift;
  }

  @override
  int shiftLeftInt(int n, int shift) {
    return n << shift;
  }
}

DataSerializerPlatform createPlatformInstance() => DataSerializerPlatformIO();
