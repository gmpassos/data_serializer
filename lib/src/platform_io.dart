import 'dart:typed_data';

import 'extension.dart';
import 'platform.dart';

class DataSerializerPlatformIO extends DataSerializerPlatform {
  DataSerializerPlatformIO() : super.base();

  static final int _maxSafeInt = 9223372036854775807;

  static final int _minSafeInt = -9223372036854775808;

  static final Uint8List _maxSafeIntBytes =
      _maxSafeInt.toUint8List64().asUnmodifiableView;

  static final Uint8List _minSafeIntBytes =
      _minSafeInt.toUint8List64().asUnmodifiableView;

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
  bool get supportsFullInt64 => true;

  @override
  bool isSafeInteger(int n) => true;

  @override
  void setUint64(ByteData data, int n, [int offset = 0]) =>
      data.setUint64(offset, n, Endian.big);

  @override
  void setInt64(ByteData data, int n, [int offset = 0]) =>
      data.setInt64(offset, n, Endian.big);

  @override
  int getUint64(ByteData data, [int offset = 0]) => data.getUint64(offset);

  @override
  int getInt64(ByteData data, [int offset = 0]) => data.getInt64(offset);

  @override
  void writeUint64(Uint8List out, int n, [int offset = 0]) {
    out.asByteData().setUint64(offset, n, Endian.big);
  }

  @override
  void writeInt64(Uint8List out, int n, [int offset = 0]) {
    out.asByteData().setInt64(offset, n, Endian.big);
  }

  @override
  int readUint64(Uint8List out, [int offset = 0]) {
    return out.asByteData().getUint64(offset, Endian.big);
  }

  @override
  int readInt64(Uint8List out, [int offset = 0]) {
    return out.asByteData().getInt64(offset, Endian.big);
  }
}

DataSerializerPlatform createPlatformInstance() => DataSerializerPlatformIO();
