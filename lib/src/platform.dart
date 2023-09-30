import 'dart:typed_data';

import 'int_codec.dart';
import 'platform_generic.dart' if (dart.library.io) 'platform_io.dart';

/// `data_serializer` platform dependent functions.
/// The implementation resolve special cases for each platform.
abstract class DataSerializerPlatform {
  /// Singleton instance of current [DataSerializerPlatform] implementation.
  static final DataSerializerPlatform instance = createPlatformInstance();

  /// Returns [instance] singleton.
  factory DataSerializerPlatform() => instance;

  late final BigInt _maxSafeBigInt;

  late final BigInt _minSafeBigInt;

  DataSerializerPlatform.base() {
    _maxSafeBigInt = BigInt.from(maxSafeInt);
    _minSafeBigInt = BigInt.from(minSafeInt);
  }

  /// The maximum safe `int` int the current platform.
  int get maxSafeInt;

  /// The minimum safe `int` int the current platform.
  int get minSafeInt;

  /// The maximum safe `int` int the current platform as [BigInt].
  BigInt get maxSafeIntAsBigInt => _maxSafeBigInt;

  /// The minimum safe `int` int the current platform as [BigInt].
  BigInt get minSafeIntAsBigInt => _minSafeBigInt;

  /// The maximum safe `int` int the current platform as [Uint8List].
  Uint8List get maxSafeIntBytes;

  /// The minimum safe `int` int the current platform as [Uint8List].
  Uint8List get minSafeIntBytes;

  /// The amount of bits of a safe integer.
  int get safeIntBits;

  /// Returns `true` if the platform fully supports 64 bits integers.
  bool get supportsFullInt64;

  /// Returns `true` if the platform fully supports bits shift.
  bool get supportsFullBitsShift;

  /// Returns `true` if [n] is a safe `int`.
  bool isSafeInteger(int n);

  /// Checks if [n] is a safe `int`. Throws [StateError] if is not a safe `int`.
  void checkSafeInteger(int n) {
    if (!isSafeInteger(n)) {
      throw StateError(_sageErrorMessage(n));
    }
  }

  /// Returns `true` if [n] is a safe `int`.
  bool isSafeIntegerByBigInt(BigInt n) {
    return n <= _maxSafeBigInt && n >= _minSafeBigInt;
  }

  /// Checks if [n] is a safe `int`. Throws [StateError] if is not a safe `int`.
  void checkSafeIntegerByBigInt(BigInt n) {
    if (!isSafeIntegerByBigInt(n)) {
      throw StateError(_sageErrorMessage(n));
    }
  }

  String _sageErrorMessage(Object n) {
    var type = n is BigInt ? 'BigInt' : 'int';
    return '$type out of safe `int` range (platform with $safeIntBits bits precision): minSafe:$minSafeInt < n:$n < maxSafe:$maxSafeInt';
  }

  /// Sets [data] bytes from [offset] with [n] as `Uint64` in [endian] order.
  void setUint64(ByteData data, int n,
      [int offset = 0, Endian endian = Endian.big]);

  /// Sets [data] bytes from [offset] with [n] as `Int64` in [endian] order.
  void setInt64(ByteData data, int n,
      [int offset = 0, Endian endian = Endian.big]);

  /// Sets [data] bytes from [offset] with [n] as `Uint64` in [endian] order.
  void setDataTypeHandlerUint64(IntCodec data, int n,
      [int offset = 0, Endian endian = Endian.big]);

  /// Sets [data] bytes from [offset] with [n] as `Int64` in [endian] order.
  void setDataTypeHandlerInt64(IntCodec data, int n,
      [int offset = 0, Endian endian = Endian.big]);

  /// Gets a `Uint64` from [data] at [offset] in [endian] order.
  int getUint64(ByteData data, [int offset = 0, Endian endian = Endian.big]);

  /// Gets a `Int64` from [data] at [offset] in [endian] order.
  int getInt64(ByteData data, [int offset = 0, Endian endian = Endian.big]);

  /// Gets a `Uint64` from [data] at [offset] in [endian] order.
  int getDataTypeHandlerUint64(IntCodec data,
      [int offset = 0, Endian endian = Endian.big]);

  /// Gets a `Int64` from [data] at [offset] in [endian] order.
  int getDataTypeHandlerInt64(IntCodec data,
      [int offset = 0, Endian endian = Endian.big]);

  /// Writes [n] as `Uint64` to [out] at [offset] in [endian] order.
  void writeUint64(Uint8List out, int n,
      [int offset = 0, Endian endian = Endian.big]);

  /// Writes [n] as `Int64` to [out] at [offset] in [endian] order.
  void writeInt64(Uint8List out, int n,
      [int offset = 0, Endian endian = Endian.big]);

  /// Reads a `Uint64` from [out] at [offset] in [endian] order.
  int readUint64(Uint8List out, [int offset = 0, Endian endian = Endian.big]);

  /// Reads a `Int64` from [out] at [offset] in [endian] order.
  int readInt64(Uint8List out, [int offset = 0, Endian endian = Endian.big]);

  /// Performs a right bit shift (`>>`).
  int shiftRightInt(int n, int shift);

  /// Performs a left bit shift (`<<`).
  int shiftLeftInt(int n, int shift);
}
