import 'dart:typed_data';

import 'extension.dart';
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
  void setUint64(ByteData data, int n, [int offset = 0]) =>
      setInt64(data, n, offset);

  @override
  void setInt64(ByteData data, int n, [int offset = 0]) {
    if (n.isNegative) {
      if (n >= -0x80000000) {
        data.setUint32(offset, 0xFFFFFFFF);
        data.setUint32(offset + 4, n);
      } else {
        _writeUint64Impl(data, n, offset);
      }
    } else {
      if (n <= 0xFFFFFFFF) {
        data.setUint32(offset, 0);
        data.setUint32(offset + 4, n);
      } else {
        _writeUint64Impl(data, n, offset);
      }
    }
  }

  void _writeUint64Impl(ByteData data, int n, int offset) {
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

    data.setUint32(offset, n1, Endian.big);
    data.setUint32(offset + 4, n2, Endian.big);
  }

  @override
  int getUint64(ByteData data, [int offset = 0]) => getInt64(data, offset);

  @override
  int getInt64(ByteData data, [int offset = 0]) {
    var offsetN2 = offset + 4;

    var n1 = data.getUint32(offset);

    if (n1 == 0) {
      return data.getUint32(offsetN2);
    } else if (n1 == 0xFFFFFFFF) {
      var n2 = data.getInt32(offsetN2);
      var n = (-0x800000000 - 1) + ((0x800000001) + n2);

      if (!n.isNegative) {
        var u = -0xFFFFFFFF - 1;
        n = u + n2;
      }

      return n;
    } else if (n1 >= 0x80000000) {
      n1 = data.getInt32(offset);
      var n2 = data.getUint32(offsetN2);
      var n = (n1 * 0x100000000) + n2;
      return n;
    } else {
      var n2 = data.getUint32(offsetN2);
      var n = (n1 * 0x100000000) + n2;
      return n;
    }
  }

  @override
  void writeUint64(Uint8List out, int n, [int offset = 0]) =>
      setInt64(out.asByteData(), n, offset);

  @override
  void writeInt64(Uint8List out, int n, [int offset = 0]) =>
      setInt64(out.asByteData(), n, offset);

  @override
  int readUint64(Uint8List out, [int offset = 0]) =>
      getInt64(out.asByteData(), offset);

  @override
  int readInt64(Uint8List out, [int offset = 0]) =>
      getInt64(out.asByteData(), offset);
}

DataSerializerPlatform createPlatformInstance() =>
    DataSerializerPlatformGeneric();
