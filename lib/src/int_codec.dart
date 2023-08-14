import 'dart:typed_data';

/// Interface to encode/decode `int` and `Uint` (16 and 32 bits).
abstract class IntCodec {
  /// Same as [ByteData.getUint16].
  int getUint16(int position, Endian endian);

  /// Same as [ByteData.setUint16].
  void setUint16(int position, int n, Endian endian);

  /// Same as [ByteData.getInt16].
  int getInt16(int position, Endian endian);

  /// Same as [ByteData.setInt16].
  void setInt16(int position, int n, Endian endian);

  /// Same as [ByteData.getUint32].
  int getUint32(int position, Endian endian);

  /// Same as [ByteData.setUint32].
  void setUint32(int position, int n, Endian endian);

  /// Same as [ByteData.getInt32].
  int getInt32(int position, Endian endian);

  /// Same as [ByteData.setInt32].
  void setInt32(int position, int n, Endian endian);
}

/// [IntCodec] implementation for [ByteData].
class ByteDataIntCodec extends IntCodec {
  final ByteData byteData;

  ByteDataIntCodec(this.byteData);

  @override
  int getInt16(int position, Endian endian) =>
      byteData.getInt16(position, endian);

  @override
  void setInt16(int position, int n, Endian endian) =>
      byteData.setInt16(position, n, endian);

  @override
  int getInt32(int position, Endian endian) =>
      byteData.getInt32(position, endian);

  @override
  void setInt32(int position, int n, Endian endian) =>
      byteData.setInt32(position, n, endian);

  @override
  int getUint16(int position, Endian endian) =>
      byteData.getUint16(position, endian);

  @override
  void setUint16(int position, int n, Endian endian) =>
      byteData.setUint16(position, n, endian);

  @override
  getUint32(int position, Endian endian) =>
      byteData.getUint32(position, endian);

  @override
  void setUint32(int position, int n, Endian endian) =>
      byteData.setUint32(position, n, endian);
}
