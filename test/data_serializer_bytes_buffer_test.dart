@Tags(['bytes'])
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

enum FooEnum { a, b, c }

void main() {
  group('BytesBuffer', () {
    test('basic 1', () {
      var buffer = BytesBuffer(16);

      expect(buffer.length, equals(0));
      expect(buffer.isEmpty, isTrue);
      expect(buffer.isNotEmpty, isFalse);
      expect(buffer.position, equals(0));
      expect(buffer.capacity, equals(16));

      expect(buffer.writeByte(123), equals(1));
      expect(buffer.toUint8List(), equals([123]));

      expect(buffer.length, equals(1));
      expect(buffer.isEmpty, isFalse);
      expect(buffer.isNotEmpty, isTrue);
      expect(buffer.position, equals(1));
      expect(buffer.capacity, equals(16));

      expect(buffer.writeInt32(0x01020304), equals(4));
      expect(buffer.toUint8List(), equals([123, 1, 2, 3, 4]));
      expect(buffer.length, equals(1 + 4));
      expect(buffer.position, equals(1 + 4));
      expect(buffer.capacity, equals(16));

      buffer.seek(1);
      expect(buffer.writeInt32(0x04030201), equals(4));
      expect(buffer.toUint8List(), equals([123, 4, 3, 2, 1]));
      expect(buffer.length, equals(1 + 4));
      expect(buffer.position, equals(1 + 4));
      expect(buffer.capacity, equals(16));

      expect(buffer.toUint8List(1), equals([4, 3, 2, 1]));
      expect(buffer.toUint8List(1, 2), equals([4, 3]));

      expect(buffer.writeInt64(0x08070605040302), equals(8));
      expect(buffer.toUint8List(),
          equals([123, 4, 3, 2, 1, 0, 8, 7, 6, 5, 4, 3, 2]));
      expect(buffer.length, equals(1 + 4 + 8));
      expect(buffer.position, equals(1 + 4 + 8));
      expect(buffer.capacity, equals(16));

      expect(buffer.writeInt64(0x02030405060708), equals(8));
      expect(
          buffer.toUint8List(),
          equals([
            123,
            4,
            3,
            2,
            1,
            0,
            8,
            7,
            6,
            5,
            4,
            3,
            2,
            0,
            2,
            3,
            4,
            5,
            6,
            7,
            8
          ]));
      expect(buffer.length, equals(1 + 4 + 8 + 8));
      expect(buffer.position, equals(1 + 4 + 8 + 8));
      expect(buffer.capacity, greaterThan(1 + 4 + 8 + 8));

      var buffer2 = BytesBuffer.from(buffer.toUint8List(),
          offset: 1, length: 4, copyBuffer: true);

      expect(buffer2.toUint8List(), equals([4, 3, 2, 1]));
      expect(buffer2.length, equals(4));
      expect(buffer2.position, equals(0));
      expect(buffer2.capacity, equals(4));

      expect(buffer2.writeInt64(0x08070605040302), equals(8));
      expect(buffer2.toUint8List(), equals([0, 8, 7, 6, 5, 4, 3, 2]));
      expect(buffer2.length, equals(8));
      expect(buffer2.position, equals(8));
      expect(buffer2.capacity, equals(8));

      buffer2.seek(0);
      expect(buffer2.readByte(), equals(0));
      expect(buffer2.position, equals(1));
      expect(buffer2.readInt32(), equals(0x08070605));
      expect(buffer2.position, equals(5));

      expect(buffer2.readRemainingBytes(), equals([4, 3, 2]));

      var time = DateTime.utc(2020, 1, 2, 3, 13, 14, 15, 0);
      expect(time.isUtc, isTrue);
      var timeMs = time.millisecondsSinceEpoch;

      expect(buffer2.writeDateTime(time), equals(8));
      buffer2.seek(buffer2.position - 8);

      var time2 = buffer2.readDateTime();
      expect(time2, equals(time));
      expect(time2.millisecondsSinceEpoch, equals(timeMs));
      expect(buffer2.position, equals(16));
    });

    test('writeBoolean/readBoolean/readUint16/readUint32', () {
      var buffer = BytesBuffer(16);

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
      var buffer = BytesBuffer(2);

      buffer.write([10, 20, 30, 40, 50], 1, 2);
      expect(buffer.length, equals(2));
      expect(buffer.position, equals(2));

      buffer.seek(0);
      expect(buffer.position, equals(0));

      expect(buffer.readBytes(2), equals([20, 30]));
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
      var buffer = BytesBuffer();

      var maxSafeInt = DataSerializerPlatform.instance.maxSafeInt;
      buffer.writeUint64(maxSafeInt);
      expect(buffer.length, equals(8));
      expect(buffer.position, equals(8));

      expect(buffer.toUint8List(),
          equals(DataSerializerPlatform.instance.maxSafeIntBytes));

      buffer.seek(0);

      expect(buffer.readUint64(), equals(maxSafeInt));
      expect(buffer.length, equals(8));
      expect(buffer.position, equals(8));

      buffer.seek(0);

      expect(buffer.readUint32(), equals(maxSafeInt ~/ 0xFFFFFFFF - 1));
      expect(buffer.readUint32(), equals(maxSafeInt & 0xFFFFFFFF));

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
      var buffer = BytesBuffer();

      var minSafeInt = DataSerializerPlatform.instance.minSafeInt;
      var minSafeIntBytes = DataSerializerPlatform.instance.minSafeIntBytes;

      buffer.writeUint64(minSafeInt);
      expect(buffer.length, equals(8));
      expect(buffer.position, equals(8));

      expect(buffer.toUint8List(), equals(minSafeIntBytes));

      buffer.seek(0);

      expect(buffer.readUint64(), equals(minSafeInt));
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
      var buffer = BytesBuffer();

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

    test('writeUint64/readUint64/readUint32', () {
      var buffer = BytesBuffer();

      buffer.writeString('abcd');

      buffer.seek(0);

      expect(buffer.readString(), equals('abcd'));
    });
  });
}
