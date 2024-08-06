@TestOn('vm')
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('extension', () {
    setUp(() {});

    test('ListGenericExtension', () {
      var l2 = [10, 20, 30, 40, 50, 60, 70, 80];

      // ignore: unnecessary_cast
      expect((l2.toUint64List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Uint64List>()));

      // ignore: unnecessary_cast
      expect((l2.toInt64List() as List<int>).copy(),
          allOf(equals([10, 20, 30, 40, 50, 60, 70, 80]), isA<Int64List>()));
    });

    test('ListIntDataExtension', () {
      var l1 = [1, 2, 3, 4, 5, 6, 7, 8];

      expect(l1.toUint64List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint64List>()));

      expect(l1.asUint64List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Uint64List>()));
      expect(l1.toUint64List().asUint64List, isA<Uint64List>());

      expect(l1.toInt64List(),
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int64List>()));

      expect(l1.asInt64List,
          allOf(equals([1, 2, 3, 4, 5, 6, 7, 8]), isA<Int64List>()));
      expect(l1.toUint64List().asInt64List, isA<Int64List>());
    });

    test('Uint32ListDataExtension', () {
      // Force a JS safe integer:
      var bytes2 = [0, 2, 3, 4, 5, 6, 7, 8].toUint8List();
      var ns32b = bytes2.convertToUint32List();

      expect(ns32b.convertToUint64List(), equals([0x02030405060708]));
      expect(ns32b.convertToUint64List(Endian.big), equals([0x02030405060708]));
      expect(ns32b.convertToUint64List(Endian.little),
          equals([0x0807060504030200]));
    });

    test('Uint64ListDataExtension', () {
      // Force a JS safe integer:
      var bytes =
          [0, 2, 3, 4, 5, 6, 7, 8, 0, 3, 4, 5, 6, 7, 8, 9].toUint8List();

      var ns64 = bytes.convertToUint64List();
      expect(ns64, equals([0x02030405060708, 0x03040506070809]));

      expect(ns64.reversedList(), equals([0x03040506070809, 0x02030405060708]));

      expect(ns64.copy(), equals([0x02030405060708, 0x03040506070809]));

      expect(ns64.copyAsUnmodifiable(),
          equals([0x02030405060708, 0x03040506070809]));

      expect(ns64.asUnmodifiableView(),
          equals([0x02030405060708, 0x03040506070809]));

      expect(ns64.toHex64(), equals('0002030405060708 0003040506070809'));
      expect(
          ns64.toBits64(),
          equals(
              '0000000000000010000000110000010000000101000001100000011100001000 '
              '0000000000000011000001000000010100000110000001110000100000001001'));

      expect(ns64.convertToUint8List(),
          equals([0, 2, 3, 4, 5, 6, 7, 8, 0, 3, 4, 5, 6, 7, 8, 9]));

      expect(ns64.convertToUint8List(Endian.big),
          equals([0, 2, 3, 4, 5, 6, 7, 8, 0, 3, 4, 5, 6, 7, 8, 9]));

      expect(ns64.convertToUint8List(Endian.little),
          equals([8, 7, 6, 5, 4, 3, 2, 0, 9, 8, 7, 6, 5, 4, 3, 0]));

      expect(
          ns64.convertToUint16List(),
          equals([
            0x0002,
            0x0304,
            0x0506,
            0x0708,
            0x0003,
            0x0405,
            0x0607,
            0x0809
          ]));

      expect(
          ns64.convertToUint16List(Endian.big),
          equals([
            0x0002,
            0x0304,
            0x0506,
            0x0708,
            0x0003,
            0x0405,
            0x0607,
            0x0809
          ]));

      expect(
          ns64.convertToUint16List(Endian.little),
          equals([
            0x0200,
            0x0403,
            0x0605,
            0x0807,
            0x0300,
            0x0504,
            0x0706,
            0x0908
          ]));

      expect(ns64.convertToUint32List(),
          equals([0x0020304, 0x05060708, 0x00030405, 0x06070809]));

      expect(ns64.convertToUint32List(Endian.big),
          equals([0x0020304, 0x05060708, 0x00030405, 0x06070809]));

      expect(ns64.convertToUint32List(Endian.little),
          equals([0x04030200, 0x08070605, 0x05040300, 0x09080706]));
    });
  });
}
