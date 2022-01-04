import 'dart:convert' as dart_convert;
import 'dart:math';
import 'dart:typed_data';

import 'package:base_codecs/base_codecs.dart';
import 'package:collection/collection.dart';

import 'bytes_buffer.dart';
import 'platform.dart';
import 'utils.dart';

final DataSerializerPlatform _platform = DataSerializerPlatform.instance;

/// extension for `int`.
extension IntExtension on int {
  /// Returns `true` if this `int` is safe for the current platform ([StatisticsPlatform]).
  bool get isSafeInteger => _platform.isSafeInteger(this);

  /// Checks if this `int` is safe for the current platform ([StatisticsPlatform]).
  void checkSafeInteger() {
    _platform.checkSafeInteger(this);
  }

  /// Returns this `int` as a bits [String].
  String get bits => toRadixString(2);

  /// Returns this `int` as a bits [String] of minimal length [width].
  String bitsPadded(int width) => bits.numericalPadLeft(width);

  /// Returns this `int` as a 8 bits [String].
  String get bits8 => bitsPadded(8);

  /// Returns this `int` as a 16 bits [String].
  String get bits16 => bitsPadded(16);

  /// Returns this `int` as a 32 bits [String].
  String get bits32 => bitsPadded(32);

  /// Returns this `int` as a 64 bits [String].
  String get bits64 => bitsPadded(64);

  /// Converts this 32 bits `int` to 4 bytes.
  Uint8List toUint8List32() {
    var bs = Uint8List(4);
    var data = bs.asByteData();
    data.setUint32(0, this);
    return bs;
  }

  /// Converts this 64 bits `int` to 8 bytes.
  Uint8List toUint8List64() {
    var bs = Uint8List(8);
    _platform.writeUint64(bs, this);
    return bs;
  }

  /// Same as [toUint8List32], but with bytes in reversed order.
  Uint8List toUint8List32Reversed() {
    var bs = Uint8List(4);
    var data = bs.asByteData();
    data.setUint32(0, this, Endian.little);
    return bs;
  }

  /// Same as [toUint8List64], but with bytes in reversed order.
  Uint8List toUint8List64Reversed() => toUint8List64().reverseBytes();

  /// Converts this 32 bits `int` to HEX.
  String toHex32() => toUint8List32().toHex();

  /// Converts this 64 bits `int` to HEX.
  String toHex64() => toUint8List64().toHex();

  /// Converts to a [String] of [width] and left padded with `0`.
  String toStringPadded(int width) {
    var s = toString();
    return s.numericalPadLeft(width);
  }

  /// Converts `this` as a `Int16` to bytes ([Uint8List]).
  Uint8List int16ToBytes() =>
      Uint8List(2)..asByteData().setInt16(0, this, Endian.big);

  /// Converts `this` as a `Uint16` to bytes ([Uint8List]).
  Uint8List uInt16ToBytes() =>
      Uint8List(2)..asByteData().setUint16(0, this, Endian.big);

  /// Converts `this` as a `Int32` to bytes ([Uint8List]).
  Uint8List int32ToBytes() =>
      Uint8List(4)..asByteData().setInt32(0, this, Endian.big);

  /// Converts `this` as a `Uint32` to bytes ([Uint8List]).
  Uint8List uInt32ToBytes() =>
      Uint8List(4)..asByteData().setUint32(0, this, Endian.big);

  /// Converts `this` as a `Int64` to bytes ([Uint8List]).
  Uint8List int64ToBytes() => Uint8List(8)..setInt64(this);

  /// Converts `this` as a `Uint64` to bytes ([Uint8List]).
  Uint8List uInt64ToBytes() => Uint8List(8)..setUint64(this);
}

/// extension for [BigInt].
extension BigIntExtension on BigInt {
  /// Returns `true` if this as `int` is safe for the current platform ([StatisticsPlatform]).
  bool get isSafeInteger => _platform.isSafeIntegerByBigInt(this);

  /// Checks if this as `int` is safe for the current platform ([StatisticsPlatform]).
  void checkSafeInteger() {
    _platform.checkSafeIntegerByBigInt(this);
  }

  /// Converts this [BigInt] to a HEX string.
  ///
  /// - [width] of the HEX string. Will left-pad with zeroes if needed.
  String toHex({int width = 0}) {
    var hex = toRadixString(16).toUpperCase();
    if (width > 0) {
      if (isNegative) {
        hex = hex.substring(1);
        return '-' + hex.padLeft(width, '0');
      } else {
        return hex.padLeft(width, '0');
      }
    }
    return hex;
  }

  /// Same as [toHex], but will ensure that the HEX string is unsigned,
  /// converting the HEX bits to a signed integer, like a [Uint32].
  String toHexUnsigned({int width = 0}) {
    if (isNegative) {
      var hex = toHex();
      if (hex.startsWith('-')) {
        hex = hex.substring(1);
      }

      if (hex.length % 2 != 0) {
        hex = '0' + hex;
      }

      var bs = hex.decodeHex();
      var bs2 = Uint8List.fromList(bs.map((e) => 256 - e).toList());

      var hex2 = bs2.toHex();
      if (width > 0) {
        hex2 = hex2.padLeft(width, 'F');
      }
      return hex2;
    } else {
      var hex = toHex();
      if (width > 0) {
        hex = hex.padLeft(width, '0');
      }
      return hex;
    }
  }

  /// Same as [toHexUnsigned], but ensure a width of 4 bytes (8 HEX width).
  String toHex32() {
    if (isNegative) {
      return toHexUnsigned(width: 8);
    } else {
      return toHex(width: 8);
    }
  }

  /// Same as [toHexUnsigned], but ensure a width of 8 bytes (16 HEX width).
  String toHex64() {
    if (isNegative) {
      return toHexUnsigned(width: 16);
    } else {
      return toHex(width: 16);
    }
  }

  /// Converts this [BigInt] to a [Uint8List] of 4 bytes (32 bits).
  Uint8List toUint8List32() => toInt().toUint8List32();

  /// Converts this [BigInt] to a [Uint8List] of 8 bytes (64 bits).
  Uint8List toUint8List64() => toInt().toUint8List64();

  /// Serializes this [BigInt] to bytes ([Uint8List]). The serialized
  /// data is prefixed with the size of the bytes that contains the big-integer.
  ///
  /// - If [bitLength] is `< 32` it will encode as a [Int32].
  /// - If [bitLength] is `> 32` it will encode using a `LATIN-1` encoded [String].
  Uint8List toBytes() {
    if (bitLength > 32) {
      var latin1 = toString().encodeLatin1Bytes();

      var bs = Uint8List(4 + latin1.length);
      var byteData = bs.asByteData();

      byteData.setInt32(0, -latin1.length);
      bs.setAll(4, latin1);

      return bs;
    } else {
      var bs = Uint8List(1 + 4);
      bs[0] = 0;
      bs.asByteData().setInt32(1, toInt());
      return bs;
    }
  }

  /// Writes this [BigInt] to [out]. See [toBytes] for encoding description.
  int writeTo(BytesBuffer out) {
    if (bitLength > 32) {
      var bs = toString().encodeLatin1Bytes();
      assert(bs.isNotEmpty);

      out.writeInt32(-bs.length);
      out.writeBytes(bs);

      return 4 + bs.length;
    } else {
      var bs = toInt().int32ToBytes();
      assert(bs.length == 4);

      out.writeByte(0);
      out.writeAllBytes(bs);
      return 1 + 4;
    }
  }
}

/// Numeric extension for [String].
extension StringExtension on String {
  /// Same as [padLeft] with `0`, but respects the numerical signal.
  String numericalPadLeft(int width) {
    var s = this;
    if (s.startsWith('-')) {
      var n = s.substring(1);
      return '-' + n.padLeft(width, '0');
    } else {
      return s.padLeft(width, '0');
    }
  }

  /// Converts this [String] to a [BigInt] parsing as a HEX sequence.
  BigInt toBigIntFromHex() => BigInt.parse(this, radix: 16);

  /// Decodes this [String] as an `HEX` sequence of bytes ([Uint8List]).
  Uint8List decodeHex() => base16.decode(this);

  /// Encodes this [String] to `LATIN-1`.
  Uint8List encodeLatin1() => dart_convert.latin1.encode(this);

  /// Encodes this [String] to `LATIN-1` bytes.
  Uint8List encodeLatin1Bytes() => encodeLatin1();

  /// Encodes this [String] to `UTF-8` bytes.
  List<int> encodeUTF8() => dart_convert.utf8.encode(this);

  /// Encodes this [String] to `UTF-8` bytes.
  Uint8List encodeUTF8Bytes() => Uint8List.fromList(encodeUTF8());
}

/// Extension for [Uint8List].
extension Uint8ListExtension on Uint8List {
  /// Returns this bytes as [String] of bits of length [width].
  String bitsPadded(int width) =>
      map((e) => e.bits8).join().numericalPadLeft(width);

  /// Returns this bytes as [String] of bits.
  String get bits => map((e) => e.bits8).join();

  /// Returns this bytes as 8 bits [String].
  String get bits8 => bitsPadded(8);

  /// Returns this bytes as 16 bits [String].
  String get bits16 => bitsPadded(16);

  /// Returns this bytes as 32 bits [String].
  String get bits32 => bitsPadded(32);

  /// Returns this bytes as 64 bits [String].
  String get bits64 => bitsPadded(64);

  static final ListEquality<int> _listIntEquality = ListEquality<int>();

  /// Returns `true` of [other] elements are equals.
  bool equals(Uint8List other) => _listIntEquality.equals(this, other);

  /// Returns a hashcode of this bytes.
  int bytesHashCode() => _listIntEquality.hash(this);

  /// A sub `Uint8List` view of regeion.
  Uint8List subView([int offset = 0, int? length]) {
    length ??= this.length - offset;
    return buffer.asUint8List(offset, length);
  }

  /// A sub `Uint8List` view of the tail.
  Uint8List subViewTail(int tailLength) {
    var length = this.length;
    var offset = length - tailLength;
    var lng = length - offset;
    return subView(offset, lng);
  }

  /// Returns a [ByteData] of `this` [buffer] with the respective offset and length.
  ByteData asByteData() => buffer.asByteData(offsetInBytes, lengthInBytes);

  /// Returns a copy of `this` instance.
  Uint8List copy() => Uint8List.fromList(this);

  /// Returns an unmodifiable copy of `this` instance.
  Uint8List copyAsUnmodifiable() => UnmodifiableUint8ListView(copy());

  /// Returns an unmodifiable view of `this` instance.
  ///
  /// - Will just cast if is already an [UnmodifiableUint8ListView].
  UnmodifiableUint8ListView get asUnmodifiableView {
    var self = this;
    return self is UnmodifiableUint8ListView
        ? self
        : UnmodifiableUint8ListView(self);
  }

  /// Decodes `this` bytes as a `LATIN-1` [String].
  String toStringLatin1() => dart_convert.latin1.decode(this);

  /// Decodes `this` bytes as a `UTF-8` [String].
  String toStringUTF8() => dart_convert.utf8.decode(this);

  /// Returns `this` instance in a reversed order.
  Uint8List reverseBytes() {
    switch (length) {
      case 1:
        {
          var bs = Uint8List(1);
          bs[0] = this[0];
          return bs;
        }
      case 2:
        {
          var bs = Uint8List(2);
          bs[0] = this[1];
          bs[1] = this[0];
          return bs;
        }
      case 3:
        {
          var bs = Uint8List(3);
          bs[0] = this[2];
          bs[1] = this[1];
          bs[2] = this[0];
          return bs;
        }
      case 4:
        {
          var bs = Uint8List(4);
          bs[0] = this[3];
          bs[1] = this[2];
          bs[2] = this[1];
          bs[3] = this[0];
          return bs;
        }
      case 5:
        {
          var bs = Uint8List(5);
          bs[0] = this[4];
          bs[1] = this[3];
          bs[2] = this[2];
          bs[3] = this[1];
          bs[4] = this[0];
          return bs;
        }
      case 6:
        {
          var bs = Uint8List(6);
          bs[0] = this[5];
          bs[1] = this[4];
          bs[2] = this[3];
          bs[3] = this[2];
          bs[4] = this[1];
          bs[5] = this[0];
          return bs;
        }
      case 7:
        {
          var bs = Uint8List(7);
          bs[0] = this[6];
          bs[1] = this[5];
          bs[2] = this[4];
          bs[3] = this[3];
          bs[4] = this[2];
          bs[5] = this[1];
          bs[6] = this[0];
          return bs;
        }
      case 8:
        {
          var bs = Uint8List(8);
          bs[0] = this[7];
          bs[1] = this[6];
          bs[2] = this[5];
          bs[3] = this[4];
          bs[4] = this[3];
          bs[5] = this[2];
          bs[6] = this[1];
          bs[7] = this[0];
          return bs;
        }
      default:
        {
          return Uint8List.fromList(reversed.toList());
        }
    }
  }

  /// Converts `this` bytes to HEX.
  String toHex({Endian endian = Endian.big}) {
    return endian == Endian.big ? toHexBigEndian() : toHexLittleEndian();
  }

  /// Converts `this` bytes to HEX (big-endian).
  String toHexBigEndian() => base16.encode(this);

  /// Converts `this` bytes to HEX (little-endian).
  String toHexLittleEndian() => base16.encode(reverseBytes());

  /// Converts `this` bytes to a [BigInt] (through [toHex]).
  BigInt toBigInt({Endian endian = Endian.big}) =>
      toHex(endian: endian).toBigIntFromHex();

  /// Returns a `Uint8` at [byteOffset] of this bytes buffer (reads 1 byte).
  int getUint8([int byteOffset = 0]) => asByteData().getUint8(byteOffset);

  /// Returns a `Uint16` at [byteOffset] of this bytes buffer (reads 2 bytes).
  int getUint16([int byteOffset = 0]) => asByteData().getUint16(byteOffset);

  /// Returns a `Uint32` at [byteOffset] of this bytes buffer (reads 4 bytes).
  int getUint32([int byteOffset = 0]) => asByteData().getUint32(byteOffset);

  /// Returns a `Uint64` at [byteOffset] of this bytes buffer (reads 8 bytes).
  int getUint64([int byteOffset = 0]) {
    return _platform.readUint64(this, byteOffset);
  }

  /// Returns a `Int8` at [byteOffset] of this bytes buffer (reads 1 byte).
  int getInt8([int byteOffset = 0]) => asByteData().getInt8(byteOffset);

  /// Returns a `Int16` at [byteOffset] of this bytes buffer (reads 2 bytes).
  int getInt16([int byteOffset = 0]) => asByteData().getInt16(byteOffset);

  /// Returns a `Int32` at [byteOffset] of this bytes buffer (reads 4 bytes).
  int getInt32([int byteOffset = 0]) => asByteData().getInt32(byteOffset);

  /// Returns a `Int64` at [byteOffset] of this bytes buffer (reads 8 bytes).
  int getInt64([int byteOffset = 0]) => _platform.readInt64(this, byteOffset);

  /// Sets [n] as a `Uint8` at [byteOffset].
  void setUint8(int n, [int byteOffset = 0]) =>
      asByteData().setUint8(byteOffset, n);

  /// Sets [n] as a `Uint16` at [byteOffset].
  void setUint16(int n, [int byteOffset = 0]) =>
      asByteData().setUint16(byteOffset, n);

  /// Sets [n] as a `Uint32` at [byteOffset].
  void setUint32(int n, [int byteOffset = 0]) =>
      asByteData().setUint32(byteOffset, n);

  /// Sets [n] as a `Uint64` at [byteOffset].
  void setUint64(int n, [int byteOffset = 0]) =>
      _platform.writeUint64(this, n, byteOffset);

  /// Sets [n] as a `Int8` at [byteOffset].
  void setInt8(int n, [int byteOffset = 0]) =>
      asByteData().setInt8(byteOffset, n);

  /// Sets [n] as a `Int16` at [byteOffset].
  void setInt16(int n, [int byteOffset = 0]) =>
      asByteData().setInt16(byteOffset, n);

  /// Sets [n] as a `Int32` at [byteOffset].
  void setInt32(int n, [int byteOffset = 0]) =>
      asByteData().setInt32(byteOffset, n);

  /// Sets [n] as a `Int64` at [byteOffset].
  void setInt64(int n, [int byteOffset = 0]) =>
      _platform.writeInt64(this, n, byteOffset);

  /// Converts this bytes to a [List] of `Uint8`.
  List<int> toListOfUint8() => List<int>.from(this);

  /// Converts this bytes to a [List] of `Uint16`.
  List<int> toListOfUint16() {
    final byteData = asByteData();
    return List<int>.generate(length ~/ 2, (i) => byteData.getUint16(i * 2));
  }

  /// Converts this bytes to a [List] of `Uint32`.
  List<int> toListOfUint32() {
    final byteData = asByteData();
    return List<int>.generate(length ~/ 4, (i) => byteData.getUint32(i * 4));
  }

  /// Converts this bytes to a [List] of `Uint64`.
  List<int> toListOfUint64() {
    return List<int>.generate(
        length ~/ 8, (i) => _platform.readUint64(this, i * 8));
  }

  /// Converts this bytes to a [List] of `Int8`.
  List<int> toListOfInt8() {
    final byteData = asByteData();
    return List<int>.generate(length, (i) => byteData.getInt8(i));
  }

  /// Converts this bytes to a [List] of `Int16`.
  List<int> toListOfInt16() {
    final byteData = asByteData();
    return List<int>.generate(length ~/ 2, (i) => byteData.getInt16(i * 2));
  }

  /// Converts this bytes to a [List] of `Int32`.
  List<int> toListOfInt32() {
    final byteData = asByteData();
    return List<int>.generate(length ~/ 4, (i) => byteData.getInt32(i * 4));
  }

  /// Converts this bytes to a [List] of `Int64`.
  List<int> toListOfInt64() {
    return List<int>.generate(
        length ~/ 8, (i) => _platform.readInt64(this, i * 8));
  }
}

extension ListIntExtension on List<int> {
  /// Same as [encodeUint8List].
  Uint8List toUint8List() => encodeUint8List();

  /// Ensures that this [List] is a [Uint8List].
  ///
  /// Calls [encodeUint8List] if needed, or just cast to [Uint8List].
  Uint8List get asUint8List =>
      this is Uint8List ? (this as Uint8List) : encodeUint8List();

  /// Encodes this [List] to a [Uint8List] of `Uint8`.
  Uint8List encodeUint8List() => Uint8List.fromList(this);

  /// Encodes this [List] to a [Uint8List] of `Uint16`.
  Uint8List encodeUint16List() {
    final length = this.length;

    final bs = Uint8List(length * 2);
    final byteData = bs.asByteData();
    var byteDataOffset = 0;

    for (var i = 0; i < length; ++i) {
      var n = this[i];
      byteData.setUint16(byteDataOffset, n);
      byteDataOffset += 2;
    }

    return bs;
  }

  /// Encodes this [List] to a [Uint8List] of `Uint32`.
  Uint8List encodeUint32List() {
    final length = this.length;

    final bs = Uint8List(length * 4);
    final byteData = bs.asByteData();
    var byteDataOffset = 0;

    for (var i = 0; i < length; ++i) {
      var n = this[i];
      byteData.setUint32(byteDataOffset, n);
      byteDataOffset += 4;
    }

    return bs;
  }

  /// Encodes this [List] to a [Uint8List] of `Uint64`.
  Uint8List encodeUint64List() {
    final p = _platform;

    final length = this.length;
    final bs = Uint8List(length * 8);

    var byteDataOffset = 0;

    for (var i = 0; i < length; ++i) {
      var n = this[i];

      p.writeUint64(bs, n, byteDataOffset);

      byteDataOffset += 8;
    }

    return bs;
  }
}

/// Data extension for [Uint8List].
extension Uint8ListDataExtension on Uint8List {
  /// Reads bytes ([Uint8List]) of [length] at [offset].
  Uint8List readBytes([int offset = 0, int? length]) {
    length ??= this.length - offset;
    var bs = sublist(offset, offset + length);
    return bs;
  }

  /// Reads a bytes block, using a [Uint32] prefix (4 bytes of length prefix).
  Uint8List readBlock32([int offset = 0]) {
    var sz = getUint32(offset);
    var bs = readBytes(offset + 4, sz);
    return bs;
  }

  /// Reads a bytes block, using a [Uint16] prefix (2 bytes of length prefix).
  Uint8List readBlock16([int offset = 0]) {
    var sz = getUint16(offset);
    var bs = readBytes(offset + 2, sz);
    return bs;
  }

  /// Reads a [BigInt] at [offset]. See [BigIntExtension.toBytes] for encoding description.
  MapEntry<int, BigInt> readBigInt([int offset = 0]) {
    var byteData = asByteData();
    if (this[offset] == 0) {
      var n = byteData.getInt32(offset + 1);
      var bigInt = BigInt.from(n);
      return MapEntry(1 + 4, bigInt);
    } else {
      var sz = -byteData.getInt32(offset);
      var bs = readBytes(offset + 4, sz);
      var s = dart_convert.latin1.decode(bs);
      var bigInt = BigInt.parse(s);
      return MapEntry(4 + bs.length, bigInt);
    }
  }

  /// Reads a [DateTime] at [offset]. It's encoded as a [Uint64] of [DateTime.millisecondsSinceEpoch].
  DateTime readDateTime([int offset = 0]) {
    var t = getInt64(offset);
    return DateTime.fromMillisecondsSinceEpoch(t, isUtc: true);
  }

  /// Instantiates a [BytesBuffer] from this [Uint8List] instance.
  BytesBuffer toBytesBuffer(
          {int offset = 0,
          int? length,
          int? bufferLength,
          bool copyBuffer = false}) =>
      BytesBuffer.from(this,
          offset: offset,
          length: length,
          bufferLength: bufferLength,
          copyBuffer: copyBuffer);

  /// Merges `this` instance with [other] using the `AND` logical operator.
  Uint8List operator &(Uint8List other) => merge(other, (a, b, i) => a & b);

  /// Merges `this` instance with [other] using the `OR` logical operator.
  Uint8List operator |(Uint8List other) => merge(other, (a, b, i) => a | b);

  /// Merges `this` instance with [other] using the `XOR` logical operator.
  Uint8List operator ^(Uint8List other) => merge(other, (a, b, i) => a ^ b);

  /// Merges `this` instance with [other] using the [merger] [Function] for each byte.
  Uint8List merge(
      Uint8List other, int Function(int a, int b, int index) merger) {
    var length = min(this.length, other.length);
    var out = Uint8List(length);

    for (var i = 0; i < length; ++i) {
      var b = merger(this[i], other[i], i);
      out[i] = b;
    }

    return out;
  }

  /// Groups `this` instance with [other].
  Uint8List group(Uint8List other) {
    var group = Uint8List(length + other.length);
    group.setAll(0, this);
    group.setAll(length, other);
    return group;
  }

  /// The tail of this [Uint8List] instance.
  Uint8List tail(int length) {
    var myLength = this.length;
    if (myLength == length) {
      return this;
    } else if (length > myLength) {
      length = myLength;
    }

    return sublist(myLength - length, myLength);
  }
}

/// Data extension for a [List] of [Writable].
extension ListWritableExtension on List<Writable> {
  int get serializeBufferLength => 4 + (length * 128);

  int writeTo(BytesBuffer out) {
    return out.writeWritables(this);
  }

  Uint8List serialize() {
    var buffer = BytesBuffer(serializeBufferLength);
    writeTo(buffer);
    return buffer.toUint8List();
  }
}

List<W> deserializeWritables<W extends Writable>(
    BytesBuffer input, W Function(BytesBuffer input) reader) {
  return input.readWritables(reader);
}

/// Data extension for [DateTime].
extension DateTimeDataExtension on DateTime {
  int writeTo(BytesBuffer out) {
    var t = toUtc().millisecondsSinceEpoch;
    return out.writeInt64(t);
  }

  Uint8List toBytes() => toUtc().millisecondsSinceEpoch.int64ToBytes();
}
