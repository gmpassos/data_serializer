import 'dart:math' as math;
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

enum FooEnum { a, b, c }

void doBytesBufferTests(
    BytesBuffer Function([int? capacity]) createBsBuff,
    BytesBuffer Function(Uint8List bytes, int offset, int? length)
        createBsBuffFrom) {
  testBytesBasic(int bsCapacity) {
    var buffer = createBsBuff(bsCapacity);

    expect(buffer.length, equals(0));
    expect(buffer.isEmpty, isTrue);
    expect(buffer.isNotEmpty, isFalse);
    expect(buffer.position, equals(0));
    expect(buffer.capacity, equals(bsCapacity));

    expect(buffer.writeByte(123), equals(1));
    expect(buffer.asUint8List(), equals([123]));

    expect(buffer.length, equals(1));
    expect(buffer.isEmpty, isFalse);
    expect(buffer.isNotEmpty, isTrue);
    expect(buffer.position, equals(1));
    expect(buffer.capacity, equals(math.max(bsCapacity, 1)));

    expect(buffer.writeInt32(0x01020304), equals(4));
    expect(buffer.asUint8List(), equals([123, 1, 2, 3, 4]));
    expect(buffer.length, equals(1 + 4));
    expect(buffer.position, equals(1 + 4));
    expect(
        buffer.capacity,
        equals(math.max(
            (bsCapacity > 1 + 4 ? bsCapacity : bsCapacity * 2), 1 + 4)));

    buffer.seek(1);
    expect(buffer.writeInt32(0x04030201), equals(4));
    expect(buffer.asUint8List(), equals([123, 4, 3, 2, 1]));
    expect(buffer.length, equals(1 + 4));
    expect(buffer.position, equals(1 + 4));
    expect(
        buffer.capacity,
        equals(math.max(
            (bsCapacity > 1 + 4 ? bsCapacity : bsCapacity * 2), 1 + 4)));

    expect(buffer.asUint8List(1), equals([4, 3, 2, 1]));
    expect(buffer.asUint8List(1, 2), equals([4, 3]));

    expect(buffer.writeUint64(0x08070605040302), equals(8));
    expect(buffer.asUint8List(),
        equals([123, 4, 3, 2, 1, 0, 8, 7, 6, 5, 4, 3, 2]));
    expect(buffer.length, equals(1 + 4 + 8));
    expect(buffer.position, equals(1 + 4 + 8));
    expect(
        buffer.capacity,
        equals(math.max((bsCapacity > 1 + 4 + 8 ? bsCapacity : bsCapacity * 2),
            1 + 4 + 8)));

    expect(buffer.indexOf(123), equals(0));
    expect(buffer.indexOf(3), equals(2));
    expect(buffer.indexOf(3, 3), equals(11));
    expect(buffer.indexOf(3, 0, 2), equals(-1));

    expect(buffer.writeUint64(0x02030405060708), equals(8));
    expect(
        buffer.asUint8List(),
        equals(
            [123, 4, 3, 2, 1, 0, 8, 7, 6, 5, 4, 3, 2, 0, 2, 3, 4, 5, 6, 7, 8]));
    expect(buffer.length, equals(1 + 4 + 8 + 8));
    expect(buffer.position, equals(1 + 4 + 8 + 8));
    expect(buffer.capacity, greaterThan(1 + 4 + 8 + 8));

    var buffer2 = createBsBuffFrom(buffer.asUint8List(), 1, 4);

    expect(buffer2.asUint8List(), equals([4, 3, 2, 1]));
    expect(buffer2.length, equals(4));
    expect(buffer2.position, equals(0));
    expect(buffer2.capacity, equals(4));

    buffer.flush();
    buffer2.flush();

    expect(buffer2.writeInt64(0x08070605040302), equals(8));
    expect(buffer2.asUint8List(), equals([0, 8, 7, 6, 5, 4, 3, 2]));
    expect(buffer2.length, equals(8));
    expect(buffer2.position, equals(8));
    expect(buffer2.capacity, equals(8));

    buffer2.seek(0);
    expect(buffer2.readByte(), equals(0));
    expect(buffer2.position, equals(1));
    expect(buffer2.readInt32(), equals(0x08070605));
    expect(buffer2.position, equals(5));

    expect(buffer2.readRemainingBytes(), equals([4, 3, 2]));
    expect(buffer2.position, equals(8));

    var time = DateTime.utc(2020, 1, 2, 3, 13, 14, 15, 0);
    expect(time.isUtc, isTrue);
    var timeMs = time.millisecondsSinceEpoch;

    expect(buffer2.writeDateTime(time), equals(8));
    expect(buffer2.position, equals(16));
    buffer2.seek(buffer2.position - 8);
    expect(buffer2.position, equals(8));

    var time2 = buffer2.readDateTime();
    expect(time2, equals(time));
    expect(time2.millisecondsSinceEpoch, equals(timeMs));
    expect(buffer2.position, equals(16));

    {
      final lengthHalf = buffer.length ~/ 2;
      final remaining = buffer.length - lengthHalf;

      buffer.seek(lengthHalf);
      expect(buffer.remaining, equals(remaining));

      var buffer2Lng = buffer2.length;

      var r = buffer.readTo(buffer2);
      expect(r, equals(remaining));
      expect(buffer2.length, equals(buffer2Lng + remaining));

      var w0 = buffer.writeFrom(buffer2);
      expect(w0, equals(0));

      buffer2.seek(buffer2.length - 2);
      var w2 = buffer.writeFrom(buffer2);
      expect(w2, equals(2));
    }

    {
      final lengthHalf = buffer.length ~/ 2;
      final remaining = buffer.length - lengthHalf;

      buffer.seek(lengthHalf);
      expect(buffer.remaining, equals(remaining));

      var buffer2 = BytesBuffer();

      var buffer2Lng = buffer2.length;

      var r = buffer.readTo(buffer2);
      expect(r, equals(remaining));
      expect(buffer2.length, equals(buffer2Lng + remaining));

      var w0 = buffer.writeFrom(buffer2);
      expect(w0, equals(0));

      buffer2.seek(buffer2.length - 2);
      var w2 = buffer.writeFrom(buffer2);
      expect(w2, equals(2));
    }

    expect(buffer.bytesIO.isClosed, isFalse);
    expect(buffer2.bytesIO.isClosed, isFalse);

    buffer.close();
    buffer2.close();

    expect(buffer.isClosed, buffer.bytesIO.supportsClosing ? isTrue : isFalse);

    expect(
        buffer2.isClosed, buffer2.bytesIO.supportsClosing ? isTrue : isFalse);
  }

  test('basic 0', () => testBytesBasic(0));
  test('basic 1', () => testBytesBasic(1));
  test('basic 3', () => testBytesBasic(3));
  test('basic 16', () => testBytesBasic(16));
  test('basic 11', () => testBytesBasic(11));
  test('basic 32', () => testBytesBasic(32));

  void testBytesIO(BytesIO bsIO) {
    final initialCapacity = bsIO.capacity;

    expect(bsIO.position, equals(0));
    expect(bsIO.length, equals(0));
    expect(bsIO.capacity, equals(initialCapacity));

    expect(bsIO.writeByte(1), equals(1));
    expect(bsIO.position, equals(1));
    expect(bsIO.length, equals(1));
    expect(bsIO.capacity, equals(math.max(initialCapacity, 1)));

    expect(bsIO.seek(3), equals(1));

    expect(bsIO.writeByte(2), equals(1));
    expect(bsIO.position, equals(2));
    expect(bsIO.length, equals(2));
    expect(bsIO.capacity, equals(math.max(initialCapacity, 2)));
  }

  test('capacity/length BytesUint8ListIO(0)',
      () => testBytesIO(BytesUint8ListIO(0)));
  test('capacity/length BytesUint8ListIO(1)',
      () => testBytesIO(BytesUint8ListIO(1)));
  test('capacity/length BytesUint8ListIO(2)',
      () => testBytesIO(BytesUint8ListIO(2)));
  test('capacity/length BytesUint8ListIO(3)',
      () => testBytesIO(BytesUint8ListIO(3)));
  test('capacity/length BytesUint8ListIO(4)',
      () => testBytesIO(BytesUint8ListIO(4)));
  test('capacity/length BytesUint8ListIO(5)',
      () => testBytesIO(BytesUint8ListIO(5)));
  test('capacity/length BytesUint8ListIO(6)',
      () => testBytesIO(BytesUint8ListIO(6)));
  test('capacity/length BytesUint8ListIO(7)',
      () => testBytesIO(BytesUint8ListIO(7)));
  test('capacity/length BytesUint8ListIO(8)',
      () => testBytesIO(BytesUint8ListIO(8)));
  test('capacity/length BytesUint8ListIO(11)',
      () => testBytesIO(BytesUint8ListIO(11)));
  test('capacity/length BytesUint8ListIO(16)',
      () => testBytesIO(BytesUint8ListIO(16)));
  test('capacity/length BytesUint8ListIO(17)',
      () => testBytesIO(BytesUint8ListIO(17)));
  test('capacity/length BytesUint8ListIO(32)',
      () => testBytesIO(BytesUint8ListIO(32)));
  test('capacity/length BytesUint8ListIO(33)',
      () => testBytesIO(BytesUint8ListIO(33)));

  test('writeBoolean/readBoolean/readUint16/readUint32', () {
    var buffer = createBsBuff(16);

    buffer.writeBoolean(true);
    buffer.writeBoolean(false);
    buffer.writeBoolean(true);
    buffer.writeBoolean(false);

    buffer.seek(0);
    expect(buffer.position, equals(0));

    expect(buffer.readBoolean(), equals(true));
    expect(buffer.position, equals(1));
    expect(buffer.readBoolean(), equals(false));
    expect(buffer.position, equals(2));
    expect(buffer.readBoolean(), equals(true));
    expect(buffer.position, equals(3));
    expect(buffer.readBoolean(), equals(false));
    expect(buffer.position, equals(4));

    buffer.seek(0);

    expect(buffer.readUint32(), equals(0x01000100));
    expect(buffer.position, equals(4));

    buffer.seek(0);

    expect(buffer.readUint16(), equals(0x0100));
    expect(buffer.position, equals(2));
    expect(buffer.readUint16(), equals(0x0100));
    expect(buffer.position, equals(4));

    buffer.seek(0);
    buffer.writeUint32(0x10203040);

    buffer.seek(0);
    expect(buffer.readUint32(), equals(0x10203040));

    buffer.seek(0);
    expect(buffer.readUint16(), equals(0x1020));
    expect(buffer.readUint16(), equals(0x3040));

    buffer.writeEnum(FooEnum.a);
    buffer.writeEnum(FooEnum.b);
    buffer.writeEnum(FooEnum.c);

    buffer.seek(4);

    expect(buffer.readEnum(FooEnum.values), equals(FooEnum.a));
    expect(buffer.readEnum(FooEnum.values), equals(FooEnum.b));
    expect(buffer.readEnum(FooEnum.values), equals(FooEnum.c));
  });

  test('readBytes/readByte', () {
    var buffer = createBsBuff(2);

    buffer.write([10, 20, 30, 40, 50], 1, 2);
    expect(buffer.length, equals(2));
    expect(buffer.position, equals(2));

    buffer.seek(0);
    expect(buffer.position, equals(0));

    expect(buffer.readBytes(2), equals([20, 30]));
    expect(buffer.position, equals(2));
    expect(buffer.length, equals(2));

    buffer.seek(0);

    buffer.write([10, 20, 30, 40, 50], 3);
    expect(buffer.length, equals(2));
    expect(buffer.position, equals(2));

    buffer.seek(0);

    expect(buffer.readBytes(2), equals([40, 50]));
    expect(buffer.position, equals(2));
    expect(buffer.length, equals(2));

    buffer.writeAllBytes(Uint8List.fromList([110, 120, 130, 140, 150]));
    expect(buffer.position, equals(7));
    expect(buffer.length, equals(7));

    buffer.seek(2);
    expect(buffer.position, equals(2));

    expect(buffer.readByte(), equals(110));

    expect(buffer.position, equals(3));

    expect(buffer.readRemainingBytes(), equals([120, 130, 140, 150]));

    expect(buffer.position, equals(7));
    expect(buffer.length, equals(7));

    buffer.setLength(5);
    expect(buffer.position, equals(5));
    expect(buffer.length, equals(5));

    buffer.seek(3);
    expect(buffer.readRemainingBytes(), equals([120, 130]));
  });

  test('writeUint64/readUint64/readUint32 +', () {
    final b0 = DataSerializerPlatform.instance.supportsFullInt64 ? 127 : 0;
    final b1 = DataSerializerPlatform.instance.supportsFullInt64 ? 255 : 31;

    var buffer = createBsBuff();

    var maxSafeInt = DataSerializerPlatform.instance.maxSafeInt;
    buffer.writeUint64(maxSafeInt);
    expect(buffer.length, equals(8));
    expect(buffer.position, equals(8));

    expect(buffer.asUint8List(),
        equals(DataSerializerPlatform.instance.maxSafeIntBytes));

    buffer.seek(0);

    expect(buffer.readUint64(), equals(maxSafeInt));
    expect(buffer.length, equals(8));
    expect(buffer.position, equals(8));

    buffer.seek(0);

    expect(buffer.readUint32(), equals(maxSafeInt ~/ 0xFFFFFFFF - 1));
    expect(buffer.readUint32(), equals(maxSafeInt & 0xFFFFFFFF));

    expect(buffer.toBytes(), equals([b0, b1, 255, 255, 255, 255, 255, 255]));
    expect(buffer.toBytes(1), equals([b1, 255, 255, 255, 255, 255, 255]));
    expect(buffer.toBytes(0, 2), equals([b0, b1]));
    expect(buffer.toBytes(1, 2), equals([b1, 255]));

    buffer.bytesTo((bytes, offset, length) {
      expect(
          bytes.sublist(offset, offset + length),
          equals(
              ((maxSafeInt ~/ 0xFFFFFFFF - 1) & 0xFFFFFFFF).toUint8List32()));
    }, 0, 4);

    buffer.bytesTo((bytes, offset, length) {
      expect(
          bytes.sublist(offset, offset + length),
          equals(((maxSafeInt ~/ 0xFFFFFFFF - 1) << 8 & 0xFFFFFFFF | 0xFF)
              .toUint8List32()));
    }, 1, 4);
  });

  test('writeUint64/readUint64/readUint32 -', () {
    var buffer = createBsBuff();

    var minSafeInt = DataSerializerPlatform.instance.minSafeInt;
    var minSafeIntBytes = DataSerializerPlatform.instance.minSafeIntBytes;

    buffer.writeInt64(minSafeInt);
    expect(buffer.length, equals(8));
    expect(buffer.position, equals(8));

    expect(buffer.asUint8List(), equals(minSafeIntBytes));

    buffer.seek(0);

    expect(buffer.readInt64(), equals(minSafeInt));
    expect(buffer.length, equals(8));
    expect(buffer.position, equals(8));

    buffer.seek(0);

    expect(buffer.readUint32().toUint8List32(),
        equals(minSafeIntBytes.sublist(0, 4)));
    expect(buffer.readUint32(), equals(minSafeInt & 0xFFFFFFFF));

    buffer.bytesTo((bytes, offset, length) {
      expect(bytes.sublist(offset, offset + length),
          equals(minSafeIntBytes.sublist(0, 4)));
    }, 0, 4);

    buffer.bytesTo((bytes, offset, length) {
      expect(bytes.sublist(offset, offset + length),
          equals(minSafeIntBytes.sublist(1, 5)));
    }, 1, 4);
  });

  test('writeUint64/readUint64/readUint32', () {
    var buffer = createBsBuff();

    buffer.writeBlock16(Uint8List.fromList([110, 120, 130, 140]));

    expect(buffer.length, equals(2 + 4));
    expect(buffer.position, equals(2 + 4));

    buffer.seek(0);

    expect(buffer.readBlock16(), equals([110, 120, 130, 140]));

    buffer.seek(0);

    buffer.writeBlock32(Uint8List.fromList([110, 120, 130, 140]));

    expect(buffer.length, equals(4 + 4));
    expect(buffer.position, equals(4 + 4));

    buffer.seek(0);

    expect(buffer.readBlock32(), equals([110, 120, 130, 140]));

    buffer.seek(4);

    buffer.writeAll([210, 220, 230, 240]);

    buffer.seek(0);

    expect(buffer.readBlock32(), equals([210, 220, 230, 240]));
  });

  test('writeUint16/readUint16', () {
    var buffer = createBsBuff();

    buffer.writeInt16(0x0102);
    buffer.writeUint16(0x0304, Endian.little);

    buffer.seek(0);

    expect(buffer.readInt16(), equals(0x0102));
    expect(buffer.readUint16(), equals(0x0403));

    buffer.seek(0);

    expect(buffer.readInt16(Endian.little), equals(0x0201));
    expect(buffer.readUint16(Endian.little), equals(0x0304));
  });

  test('writeString/readString', () {
    var buffer = createBsBuff();

    buffer.writeString('abcd');

    buffer.seek(0);

    expect(buffer.readString(), equals('abcd'));
  });

  test('writeString/readString', () {
    var buffer = createBsBuff();

    buffer.writeBigInt(BigInt.from(1234567));
    buffer.writeBigInt(
        BigInt.parse('123456789101112131415161718192021222324252627282930'));

    buffer.seek(0);

    expect(buffer.readBigInt(), equals(BigInt.from(1234567)));
    expect(
        buffer.readBigInt(),
        equals(BigInt.parse(
            '123456789101112131415161718192021222324252627282930')));

    expect(() => buffer.readBigInt(), throwsA(isA<BytesBufferEOF>()));

    buffer.seek(buffer.length - 5);
    expect(() => buffer.readBigInt(), throwsA(isA<BytesBufferEOF>()));
  });

  test('writeBlocks/compact/reset', () {
    var buffer = createBsBuff();
    var initialCapacity = buffer.capacity;

    var w = buffer.writeBlocks([
      [10, 20].toUint8List(),
      [30, 40, 50].toUint8List(),
      [60, 70, 80, 90].toUint8List(),
    ]);

    final blocksLength = 4 + 4 + 2 + 4 + 3 + 4 + 4;
    expect(w, equals(blocksLength));
    expect(buffer.length, equals(blocksLength));

    buffer.seek(0);

    var blocks = buffer.readBlocks();

    expect(blocks.length, equals(3));

    expect(blocks[0], equals([10, 20]));
    expect(blocks[1], equals([30, 40, 50]));
    expect(blocks[2], equals([60, 70, 80, 90]));

    expect(buffer.capacity, equals(math.max(initialCapacity, blocksLength)));
    expect(buffer.length, equals(blocksLength));
    buffer.compact();
    expect(buffer.capacity, equals(blocksLength));
    expect(buffer.length, equals(blocksLength));

    expect(buffer.indexOf(20), equals(4 + 4 + 1));

    buffer.reset();
    expect(buffer.length, equals(0));
    expect(buffer.position, equals(0));

    expect(buffer.indexOf(20), equals(-1));

    expect(() => buffer.readBlocks(), throwsA(isA<BytesBufferEOF>()));
  });

  test('writeFloat64/writeAllFloat64', () {
    var buffer = createBsBuff();

    buffer.writeFloat64(123.456);
    expect(buffer.length, equals(8));

    buffer.writeAllFloat64([10.11, 20.22, 30.33]);
    expect(buffer.length, equals(32));

    buffer.seek(0);

    expect(buffer.readFloat64(), equals(123.456));
    expect(buffer.position, equals(8));

    expect(buffer.readAllFloat64(3), equals([10.11, 20.22, 30.33]));
    expect(buffer.position, equals(32));

    var bs = buffer.toBytes();
    print(bs);
    expect(
        bs,
        equals([
          64,
          94,
          221,
          47,
          26,
          159,
          190,
          119,
          64,
          36,
          56,
          81,
          235,
          133,
          30,
          184,
          64,
          52,
          56,
          81,
          235,
          133,
          30,
          184,
          64,
          62,
          84,
          122,
          225,
          71,
          174,
          20
        ]));
  });

  test('writeFloat32/writeAllFloat32', () {
    var buffer = createBsBuff();

    buffer.writeFloat32(123.456);
    expect(buffer.length, equals(4));

    buffer.writeAllFloat32([10.11, 20.22, 30.33]);
    expect(buffer.length, equals(16));

    buffer.seek(0);

    expect(buffer.readFloat32(), inInclusiveRange(123.456, 123.457));

    expect(buffer.position, equals(4));

    var fs = buffer.readAllFloat32(3);
    expect(fs.length, equals(3));
    expect(fs[0], inInclusiveRange(10.09, 10.12));
    expect(fs[1], inInclusiveRange(20.21, 20.23));
    expect(fs[2], inInclusiveRange(30.32, 30.34));
    expect(buffer.position, equals(16));

    var bs = buffer.toBytes();
    print(bs);
    expect(
        bs,
        equals([
          66,
          246,
          233,
          121,
          65,
          33,
          194,
          143,
          65,
          161,
          194,
          143,
          65,
          242,
          163,
          215
        ]));
  });
}
