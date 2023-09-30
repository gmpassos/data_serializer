import 'dart:typed_data';

import 'extension.dart';
import 'int_codec.dart';
import 'platform.dart';

class DataSerializerPlatformGeneric extends DataSerializerPlatform {
  DataSerializerPlatformGeneric() : super.base();

  static final int _maxSafeInt = 9007199254740991;

  static final int _minSafeInt = -9007199254740991;

  static final Uint8List _maxSafeIntBytes =
      '001FFFFFFFFFFFFF'.decodeHex().asUnmodifiableView;

  static final Uint8List _minSafeIntBytes =
      'FFE0000000000001'.decodeHex().asUnmodifiableView;

  @override
  int get maxSafeInt => _maxSafeInt;

  @override
  int get minSafeInt => _minSafeInt;

  @override
  Uint8List get maxSafeIntBytes => _maxSafeIntBytes;

  @override
  Uint8List get minSafeIntBytes => _minSafeIntBytes;

  @override
  int get safeIntBits => 53;

  @override
  bool get supportsFullInt64 => false;

  @override
  bool isSafeInteger(int n) {
    return n <= _maxSafeInt && n >= _minSafeInt;
  }

  @override
  void setUint64(ByteData data, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      setInt64(data, n, offset, endian);

  @override
  void setDataTypeHandlerUint64(IntCodec data, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      setDataTypeHandlerInt64(data, n, offset, endian);

  @override
  void setInt64(ByteData data, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      _writeInt64(n, offset, endian, data.setUint32);

  @override
  void setDataTypeHandlerInt64(IntCodec data, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      _writeInt64(n, offset, endian, data.setUint32);

  void _writeInt64(int n, int offset, Endian endian,
      void Function(int byteOffset, int value, Endian endian) setUint32) {
    if (n.isNegative) {
      if (n >= -0x80000000) {
        if (endian.isBigEndian) {
          setUint32(offset, 0xFFFFFFFF, endian);
          setUint32(offset + 4, n, endian);
        } else {
          setUint32(offset, n, endian);
          setUint32(offset + 4, 0xFFFFFFFF, endian);
        }
      } else {
        _writeUint64Impl(n, offset, endian, setUint32);
      }
    } else {
      if (n <= 0xFFFFFFFF) {
        if (endian.isBigEndian) {
          setUint32(offset, 0, endian);
          setUint32(offset + 4, n, endian);
        } else {
          setUint32(offset, n, endian);
          setUint32(offset + 4, 0, endian);
        }
      } else {
        _writeUint64Impl(n, offset, endian, setUint32);
      }
    }
  }

  void _writeUint64Impl(int n, int offset, Endian endian,
      void Function(int byteOffset, int value, Endian endian) setUint32) {
    checkSafeInteger(n);

    // Right shift operator (>>) will cast to 32 bits in JS:
    int n1;
    if (n.isNegative) {
      // Negative numbers division should round in the other direction:
      var d = (n / 0x100000000);
      var dN = d.toInt();
      var dF = d - dN;
      if (dF != 0) {
        --dN;
      }

      n1 = (dN & 0xFFFFFFFF);
    } else {
      n1 = ((n ~/ 0x100000000) & 0xFFFFFFFF);
    }

    var n2 = n & 0xFFFFFFFF;

    if (endian == Endian.big) {
      setUint32(offset, n1, Endian.big);
      setUint32(offset + 4, n2, Endian.big);
    } else {
      setUint32(offset, n2, Endian.little);
      setUint32(offset + 4, n1, Endian.little);
    }
  }

  @override
  int getUint64(ByteData data, [int offset = 0, Endian endian = Endian.big]) =>
      getInt64(data, offset, endian);

  @override
  int getDataTypeHandlerUint64(IntCodec data,
          [int offset = 0, Endian endian = Endian.big]) =>
      getDataTypeHandlerInt64(data, offset, endian);

  @override
  int getInt64(ByteData data, [int offset = 0, Endian endian = Endian.big]) =>
      _readInt64(offset, endian, data.getUint32, data.getInt32);

  @override
  int getDataTypeHandlerInt64(IntCodec data,
          [int offset = 0, Endian endian = Endian.big]) =>
      _readInt64(offset, endian, data.getUint32, data.getInt32);

  int _readInt64(
      int offset,
      Endian endian,
      int Function(int offset, Endian endian) getUint32,
      int Function(int offset, Endian endian) getInt32) {
    int offsetN1, offsetN2;

    if (endian == Endian.big) {
      offsetN1 = offset;
      offsetN2 = offset + 4;
    } else {
      offsetN1 = offset + 4;
      offsetN2 = offset;
    }

    var n1 = getUint32(offsetN1, endian);

    if (n1 == 0) {
      return getUint32(offsetN2, endian);
    } else if (n1 == 0xFFFFFFFF) {
      var n2 = getInt32(offsetN2, endian);
      var n = (-0x800000000 - 1) + ((0x800000001) + n2);

      if (!n.isNegative) {
        var u = -0xFFFFFFFF - 1;
        n = u + n2;
      }

      return n;
    } else if (n1 >= 0x80000000) {
      var n2 = getUint32(offsetN2, endian);
      // var n0 = (n1 * 0x100000000);
      // JS safe:
      var n0 = -((0xFFFFFFFF - n1) + 1) * 0x100000000;
      var n = n0 + n2;
      return n;
    } else {
      var n2 = getUint32(offsetN2, endian);
      var n0 = (n1 * 0x100000000);
      var n = n0 + n2;
      return n;
    }
  }

  @override
  void writeUint64(Uint8List out, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      setInt64(out.asByteData(), n, offset, endian);

  @override
  void writeInt64(Uint8List out, int n,
          [int offset = 0, Endian endian = Endian.big]) =>
      setInt64(out.asByteData(), n, offset, endian);

  @override
  int readUint64(Uint8List out, [int offset = 0, Endian endian = Endian.big]) =>
      getInt64(out.asByteData(), offset, endian);

  @override
  int readInt64(Uint8List out, [int offset = 0, Endian endian = Endian.big]) =>
      getInt64(out.asByteData(), offset, endian);

  @override
  int shiftRightInt(int n, int shift) {
    if (n >= 0) {
      return n >> shift;
    }

    var i = BigInt.from(n);
    i = i >> shift;

    return i.toInt();
  }

  @override
  int shiftLeftInt(int n, int shift) {
    if (n >= 0) {
      return n << shift;
    }

    var i = BigInt.from(n);
    i = i << shift;

    return i.toInt();
  }
}

DataSerializerPlatform createPlatformInstance() =>
    DataSerializerPlatformGeneric();
