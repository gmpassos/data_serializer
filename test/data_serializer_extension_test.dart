import 'dart:collection';
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('extension', () {
    setUp(() {});

    test('StringExtension', () {
      expect('abc'.encodeLatin1Bytes(), equals([97, 98, 99]));
      expect('€'.encodeUTF8Bytes(), equals([226, 130, 172]));
    });

    test('EndianExtension', () {
      expect(Endian.big.isBigEndian, isTrue);
      expect(Endian.big.isLittleEndian, isFalse);

      expect(Endian.little.isLittleEndian, isTrue);
      expect(Endian.little.isBigEndian, isFalse);
    });

    test('ListGenericExtension', () {
      var l1 = [1, 2, 3, 4, 5, 6, 7, 8];
      var l2 = [10, 20, 30, 40, 50, 60, 70, 80];

      expect(l1.reversedList(), equals([8, 7, 6, 5, 4, 3, 2, 1]));

      expect(l1.asUnmodifiableListView(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<UnmodifiableListView>()));

      expect(l1.asUnmodifiableListView().asUnmodifiableListView(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<UnmodifiableListView>()));

      l2.copyTo(2, l1, 2, 3);
      expect(l1, equals([1, 2, 30, 40, 50, 6, 7, 8]));

      l2.copyTo(2, l1, 2, 4);
      expect(l1, equals([1, 2, 30, 40, 50, 60, 7, 8]));

      l2.copyTo(2, l1, 1, 5);
      expect(l1, equals([1, 30, 40, 50, 60, 70, 7, 8]));

      // ignore: unnecessary_cast
      expect((l2.toUint8List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Uint8List>()));

      // ignore: unnecessary_cast
      expect((l2.toInt8List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Int8List>()));

      // ignore: unnecessary_cast
      expect((l2.toUint16List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Uint16List>()));

      // ignore: unnecessary_cast
      expect((l2.toInt16List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Int16List>()));

      // ignore: unnecessary_cast
      expect((l2.toUint32List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Uint32List>()));

      // ignore: unnecessary_cast
      expect((l2.toInt32List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Int32List>()));

      expect(l2.reverseChunks(2), equals([20, 10, 40, 30, 60, 50, 80, 70]));

      expect(l2.reverseChunks(4), equals([40, 30, 20, 10, 80, 70, 60, 50]));

      expect(l2.reverseChunks(1), equals([10, 20, 30, 40, 50, 60, 70, 80]));

      expect(l2.toUint8List().reverseChunks(1),
          equals([10, 20, 30, 40, 50, 60, 70, 80]));
      expect(l2.toUint8List().reverseChunks(1), isA<Uint8List>());

      l2.copyTo(0, l1, 0, 8);
      expect(l1, equals([10, 20, 30, 40, 50, 60, 70, 80]));
    });

    test('ListIntDataExtension', () {
      var l1 = [1, 2, 3, 4, 5, 6, 7, 8];

      expect(l1.toUint8List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint8List>()));

      expect(l1.asUint8List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint8List>()));
      expect(l1.toUint8List().asUint8List, isA<Uint8List>());

      expect(l1.toInt8List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int8List>()));

      expect(l1.asInt8List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int8List>()));
      expect(l1.toUint8List().asInt8List, isA<Int8List>());

      expect(l1.toUint16List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint16List>()));

      expect(l1.asUint16List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint16List>()));
      expect(l1.toUint16List().asUint16List, isA<Uint16List>());

      expect(l1.toInt16List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int16List>()));

      expect(l1.asInt16List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int16List>()));
      expect(l1.toUint16List().asInt16List, isA<Int16List>());

      expect(l1.toUint32List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint32List>()));

      expect(l1.asUint32List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint32List>()));
      expect(l1.toUint32List().asUint32List, isA<Uint32List>());

      expect(l1.toInt32List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int32List>()));

      expect(l1.asInt32List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int32List>()));
      expect(l1.toUint32List().asInt32List, isA<Int32List>());

      expect(l1.toUint8List().convertToUint16List(),
          allOf(equals([0x0102, 0x0304, 0x0506, 0x0708]), isA<Uint16List>()));

      expect(l1.toUint8List().convertToUint16List(Endian.little),
          allOf(equals([0x0201, 0x0403, 0x0605, 0x0807]), isA<Uint16List>()));

      expect(l1.toUint8List().convertToUint32List(),
          allOf(equals([0x01020304, 0x05060708]), isA<Uint32List>()));
    });

    test('Uint32ListDataExtension', () {
      var bytes = [1, 2, 3, 4, 5, 6, 7, 8].toUint8List();

      var ns32 = bytes.convertToUint32List();

      expect(ns32, equals([0x01020304, 0x05060708]));

      expect(ns32.copy(), equals([0x01020304, 0x05060708]));

      expect(ns32.copyAsUnmodifiable(), equals([0x01020304, 0x05060708]));

      expect(ns32.asUnmodifiableView(), equals([0x01020304, 0x05060708]));

      expect(ns32.reversedList(), equals([0x05060708, 0x01020304]));

      expect(ns32.toHex32(), equals('01020304 05060708'));

      expect(
          ns32.toBits32(),
          equals('00000001000000100000001100000100 '
              '00000101000001100000011100001000'));

      // Force a JS safe integer:
      var bytes2 = [0, 2, 3, 4, 5, 6, 7, 8].toUint8List();
      var ns32b = bytes2.convertToUint32List();

      expect(ns32b, equals([0x020304, 0x05060708]));
      expect(ns32b.toHex32(), equals('00020304 05060708'));

      expect(ns32b.convertToUint16List(),
          equals([0x0002, 0x0304, 0x0506, 0x0708]));
      expect(ns32b.convertToUint16List(Endian.big),
          equals([0x0002, 0x0304, 0x0506, 0x0708]));
      expect(ns32b.convertToUint16List(Endian.little),
          equals([0x0200, 0x0403, 0x0605, 0x0807]));

      expect(ns32b.convertToUint8List(),
          equals([0x00, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]));
      expect(ns32b.convertToUint8List(Endian.big),
          equals([0x00, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08]));
      expect(ns32b.convertToUint8List(Endian.little),
          equals([0x04, 0x03, 0x02, 0x00, 0x08, 0x07, 0x06, 0x05]));
    });

    test('Uint8ListDataExtension', () {
      var bytes = [1, 2, 3, 4, 5, 6, 7, 8].toUint8List();

      expect(bytes, equals([1, 2, 3, 4, 5, 6, 7, 8]));

      expect(bytes.reverseBytes(), equals([8, 7, 6, 5, 4, 3, 2, 1]));

      expect(bytes.convertToUint32List(), equals([16909060, 84281096]));

      expect(bytes.readBytes(0, 4), equals([1, 2, 3, 4]));
      expect(bytes.readBytes(1, 4), equals([2, 3, 4, 5]));
      expect(bytes.readBytes(5), equals([6, 7, 8]));

      var buffer = bytes.toBytesBuffer();

      expect(buffer.readUint32(), equals(0x01020304));
      expect(buffer.readUint32(), equals(0x05060708));

      expect(bytes.tail(4), equals([5, 6, 7, 8]));

      expect((bytes & [16, 16, 16, 16, 16, 16, 16, 16].toUint8List()),
          equals([0, 0, 0, 0, 0, 0, 0, 0]));
      expect((bytes & [1, 1, 1, 1, 1, 1, 1, 1].toUint8List()),
          equals([1, 0, 1, 0, 1, 0, 1, 0]));

      expect((bytes | [16, 16, 16, 16, 16, 16, 16, 16].toUint8List()),
          equals([17, 18, 19, 20, 21, 22, 23, 24]));
      expect((bytes | [1, 1, 1, 1, 1, 1, 1, 1].toUint8List()),
          equals([1, 3, 3, 5, 5, 7, 7, 9]));

      expect((bytes ^ [15, 15, 15, 15, 15, 15, 15, 15].toUint8List()),
          equals([14, 13, 12, 11, 10, 9, 8, 7]));

      expect([10, 20].toUint8List().group([30, 40].toUint8List()),
          equals([10, 20, 30, 40]));

      buffer.seek(0);

      buffer.writeBlock16([10, 20, 30].toUint8List());
      buffer.writeBlock32([40, 50, 60, 70].toUint8List());

      var bytes2 = buffer.asUint8List();

      expect(bytes2.readBlock16(0), equals([10, 20, 30]));
      expect(bytes2.readBlock32(2 + 3), equals([40, 50, 60, 70]));
    });

    test('BigInt', () {
      var n1 = BigInt.from(123456);
      var bs1 = n1.toBytes();
      expect(bs1.readBigInt().value, equals(n1));

      var n2 = BigInt.parse('1234567890123456789012345678901234567890');
      var bs2 = n2.toBytes();
      expect(bs2.readBigInt().value, equals(n2));
    });

    test('DateTime', () {
      var d1 = DateTime(2021, 10, 11, 12, 13, 14).toUtc();
      var bs = d1.toBytes();
      expect(bs.readDateTime(), equals(d1));
    });
  });
}
