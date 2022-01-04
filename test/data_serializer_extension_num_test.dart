@Tags(['num'])
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('int', () {
    setUp(() {});

    test('bits', () {
      expect(123.bits, equals('1111011'));
      expect(123.bits8, equals('01111011'));
      expect(123.bitsPadded(11), equals('00001111011'));
      expect(123.bits16, equals('0000000001111011'));
      expect(123.bits32, equals('00000000000000000000000001111011'));
      expect(
          123.bits64,
          equals(
              '0000000000000000000000000000000000000000000000000000000001111011'));
    });

    test('toUint8List32/64', () {
      expect(123.toUint8List32(), equals(Uint8List.fromList([0, 0, 0, 123])));
      expect((-123).toUint8List32(),
          equals(Uint8List.fromList([255, 255, 255, 133])));

      expect(123.toUint8List32Reversed(),
          equals(Uint8List.fromList([123, 0, 0, 0])));
      expect((-123).toUint8List32Reversed(),
          equals(Uint8List.fromList([133, 255, 255, 255])));

      expect(0xFF01.uInt16ToBytes(), equals(Uint8List.fromList([255, 1])));
      expect(0xFF01FF01.uInt32ToBytes(),
          equals(Uint8List.fromList([255, 1, 255, 1])));
      expect(0x01FF01FF01FF01.uInt64ToBytes(),
          equals(Uint8List.fromList([0, 1, 255, 1, 255, 1, 255, 1])));

      expect(0xFF01.int16ToBytes(), equals(Uint8List.fromList([255, 1])));
      expect(0xFF01FF01.int32ToBytes(),
          equals(Uint8List.fromList([255, 1, 255, 1])));
      expect(0x01FF01FF01FF01.int64ToBytes(),
          equals(Uint8List.fromList([0, 1, 255, 1, 255, 1, 255, 1])));

      expect((0xFFFFFFFF), equals(4294967295));

      expect((0xFFFFFFFF).toUint8List32(),
          equals(Uint8List.fromList([255, 255, 255, 255])));

      expect((-123).toUint8List64(),
          equals(Uint8List.fromList([255, 255, 255, 255, 255, 255, 255, 133])));

      expect((-123).toUint8List64Reversed(),
          equals(Uint8List.fromList([133, 255, 255, 255, 255, 255, 255, 255])));

      expect(int.parse('000000FDFCFBFAF9', radix: 16).toUint8List64(),
          equals(Uint8List.fromList([0, 0, 0, 253, 252, 251, 250, 249])));

      expect(int.parse('0000FEFDFCFBFAF9', radix: 16).toUint8List64(),
          equals(Uint8List.fromList([0, 0, 254, 253, 252, 251, 250, 249])));
    });

    test('toHex32', () {
      expect(1.toHex32(), equals('00000001'));
      expect((-1).toHex32(), equals('FFFFFFFF'));

      expect(123.toHex32(), equals('0000007B'));
      expect((-123).toHex32(), equals('FFFFFF85'));
    });

    test('toHex64', () {
      expect(123.toHex64(), equals('000000000000007B'));
      expect((-123).toHex64(), equals('FFFFFFFFFFFFFF85'));
    });

    test('toStringPadded', () {
      expect(123.toStringPadded(4), equals('0123'));
      expect(123.toStringPadded(1), equals('123'));
      expect(123.toStringPadded(6), equals('000123'));
      expect((-123).toStringPadded(6), equals('-000123'));
    });
  });

  group('BigInt', () {
    setUp(() {});

    test('to...()', () {
      var bigInt1 = BigInt.from(1);
      var bigIntN1 = BigInt.from(-1);
      var bigInt123 = BigInt.from(123);
      var bigIntN123 = BigInt.from(-123);

      expect(bigInt1, equals(BigInt.from(1)));
      expect(bigIntN1, equals(BigInt.from(-1)));

      expect(bigInt123, equals(BigInt.from(123)));
      expect(bigIntN123, equals(BigInt.from(-123)));

      expect(bigInt1.toHex(), equals('1'));
      expect(bigIntN1.toHex(), equals('-1'));
      expect(bigInt1.toHex(width: 2), equals('01'));
      expect(bigIntN1.toHex(width: 2), equals('-01'));

      expect(bigInt123.toHex(), equals('7B'));
      expect(bigIntN123.toHex(), equals('-7B'));
      expect(bigInt123.toHex(width: 4), equals('007B'));
      expect(bigIntN123.toHex(width: 4), equals('-007B'));

      expect(bigInt1.toHexUnsigned(), equals('1'));
      expect(bigIntN1.toHexUnsigned(), equals('FF'));
      expect(bigInt1.toHexUnsigned(width: 2), equals('01'));
      expect(bigIntN1.toHexUnsigned(width: 2), equals('FF'));

      expect(bigInt123.toHexUnsigned(), equals('7B'));
      expect(bigIntN123.toHexUnsigned(), equals('85'));
      expect(bigInt123.toHexUnsigned(width: 4), equals('007B'));
      expect(bigIntN123.toHexUnsigned(width: 4), equals('FF85'));

      expect(bigInt1.toHex32(), equals('00000001'));
      expect(bigIntN1.toHex32(), equals('FFFFFFFF'));

      expect(bigInt123.toHex32(), equals('0000007B'));
      expect(bigIntN123.toHex32(), equals('FFFFFF85'));

      expect(bigInt123.toHex64(), equals('000000000000007B'));
      expect(bigIntN123.toHex64(), equals('FFFFFFFFFFFFFF85'));

      expect(bigInt1.toUint8List32(), equals([0, 0, 0, 1]));
      expect(bigIntN1.toUint8List32(), equals([255, 255, 255, 255]));

      expect(bigInt123.toUint8List32(), equals([0, 0, 0, 123]));
      expect(bigIntN123.toUint8List32(), equals([255, 255, 255, 133]));

      expect(bigInt1.toUint8List64(), equals([0, 0, 0, 0, 0, 0, 0, 1]));
      expect(bigIntN1.toUint8List64(),
          equals([255, 255, 255, 255, 255, 255, 255, 255]));

      expect(bigInt123.toUint8List64(), equals([0, 0, 0, 0, 0, 0, 0, 123]));
      expect(bigIntN123.toUint8List64(),
          equals([255, 255, 255, 255, 255, 255, 255, 133]));
    });
  });

  group('double', () {
    setUp(() {});
  });

  group('num', () {
    setUp(() {});
  });

  group('Numeric String', () {
    setUp(() {});

    test('to...()', () {
      expect('01'.toBigIntFromHex(), equals(BigInt.from(1)));
      expect('FF'.toBigIntFromHex(), equals(BigInt.from(255)));

      expect('000001'.toBigIntFromHex(), equals(BigInt.from(1)));
      expect('0000FF'.toBigIntFromHex(), equals(BigInt.from(255)));

      expect('0102'.toBigIntFromHex(), equals(BigInt.from(258)));
      expect('FFFF'.toBigIntFromHex(), equals(BigInt.from(65535)));

      expect('FFFFFFFF'.toBigIntFromHex(), equals(BigInt.from(4294967295)));

      expect('FFFFFFFFFFFFFFFF'.toBigIntFromHex(),
          equals(BigInt.parse('18446744073709551615')));

      expect('FFFFFFFFFFFFFFFFFFFF'.toBigIntFromHex(),
          equals(BigInt.parse('1208925819614629174706175')));

      expect('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'.toBigIntFromHex(),
          equals(BigInt.parse('340282366920938463463374607431768211455')));
    });
  });

  group('Numeric Uint8List', () {
    setUp(() {});

    test('basic', () {
      expect(
          Uint8List.fromList([0, 0, 0, 123])
              .equals(Uint8List.fromList([0, 0, 0, 123])),
          isTrue);

      expect(
          Uint8List.fromList([1, 10, 20, 30]).copy(), equals([1, 10, 20, 30]));

      expect(Uint8List.fromList([1, 10, 20, 30]).copyAsUnmodifiable(),
          equals([1, 10, 20, 30]));

      expect(() => Uint8List.fromList([1, 2, 3]).copy()..[0] = 10,
          returnsNormally);

      expect(() => Uint8List.fromList([1, 2, 3]).copyAsUnmodifiable()..[0] = 10,
          throwsA(isA<Error>()));

      expect(() => Uint8List.fromList([1, 2, 3]).asUnmodifiableView..[0] = 10,
          throwsA(isA<Error>()));

      expect(Uint8List.fromList([1, 10, 20, 30]).bytesHashCode(),
          equals(1176475097));

      {
        expect(Uint8List.fromList([10]).reverseBytes(), equals([10]));

        expect(Uint8List.fromList([10, 20]).reverseBytes(), equals([20, 10]));

        expect(Uint8List.fromList([10, 20, 30]).reverseBytes(),
            equals([30, 20, 10]));

        expect(Uint8List.fromList([10, 20, 30, 40]).reverseBytes(),
            equals([40, 30, 20, 10]));

        expect(Uint8List.fromList([10, 20, 30, 40, 50]).reverseBytes(),
            equals([50, 40, 30, 20, 10]));

        expect(Uint8List.fromList([10, 20, 30, 40, 50, 60]).reverseBytes(),
            equals([60, 50, 40, 30, 20, 10]));

        expect(Uint8List.fromList([10, 20, 30, 40, 50, 60, 70]).reverseBytes(),
            equals([70, 60, 50, 40, 30, 20, 10]));

        expect(
            Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80]).reverseBytes(),
            equals([80, 70, 60, 50, 40, 30, 20, 10]));

        expect(
            Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80, 90])
                .reverseBytes(),
            equals([90, 80, 70, 60, 50, 40, 30, 20, 10]));

        expect(
            Uint8List.fromList([10, 20, 30, 40, 50, 60, 70, 80, 90, 100])
                .reverseBytes(),
            equals([100, 90, 80, 70, 60, 50, 40, 30, 20, 10]));
      }

      expect(Uint8List.fromList([65, 66, 67, 68]).toStringLatin1(),
          equals('ABCD'));

      expect(Uint8List.fromList([226, 130, 172]).toStringUTF8(), equals('€'));

      expect(
          Uint8List.fromList([0, 0, 0, 123])
              .equals(Uint8List.fromList([0, 0, 1, 123])),
          isFalse);

      expect(Uint8List.fromList([0, 0, 0, 123, 0, 0, 0, 123]).subView(2, 4),
          equals([0, 123, 0, 0]));

      expect(Uint8List.fromList([0, 0, 0, 123, 0, 0, 0, 123]).subView(3),
          equals([123, 0, 0, 0, 123]));

      expect(Uint8List.fromList([0, 0, 0, 123, 0, 1, 2, 3, 4]).subViewTail(4),
          equals([1, 2, 3, 4]));

      expect(Uint8List.fromList([0, 0, 0, 123]).toHexBigEndian(),
          equals('0000007B'));

      expect(Uint8List.fromList([0, 0, 0, 123]).toHexLittleEndian(),
          equals('7B000000'));

      expect(Uint8List.fromList([0, 0, 0, 123]).toBigInt(),
          equals(BigInt.parse('123')));

      expect(Uint8List.fromList([0, 0, 0, 123]).toBigInt(endian: Endian.little),
          equals(BigInt.parse('2063597568')));

      expect(Uint8List.fromList([255, 255, 255, 255]).toBigInt(),
          equals(BigInt.parse('4294967295')));

      expect(Uint8List.fromList([32, 64]).bits, equals('0010000001000000'));

      expect(Uint8List.fromList([32, 64, 128, 255]).bits,
          equals('00100000010000001000000011111111'));

      expect(Uint8List.fromList([125]).bits8, equals('01111101'));

      expect(Uint8List.fromList([255, 128]).bits16, equals('1111111110000000'));

      expect(Uint8List.fromList([255, 128]).bits32,
          equals('00000000000000001111111110000000'));

      expect(
          Uint8List.fromList([255, 128]).bits64,
          equals(
              '0000000000000000000000000000000000000000000000001111111110000000'));

      expect(
          Uint8List.fromList([255, 255, 255, 255])
              .toBigInt(endian: Endian.little),
          equals(BigInt.parse('4294967295')));

      expect(
          Uint8List.fromList([255, 255, 255, 255, 255, 255, 255, 255])
              .toBigInt(),
          equals(BigInt.parse('18446744073709551615')));

      expect(Uint8List.fromList([255, 0, 0, 0, 0, 0, 0, 0]).toBigInt(),
          equals(BigInt.parse('18374686479671623680')));

      //

      expect(Uint8List.fromList([1, 2, 3, 4]).getUint8(0), equals(1));
      expect(Uint8List.fromList([1, 2, 3, 4]).getUint8(1), equals(2));
      expect(Uint8List.fromList([1, 2, 3, 4]).getUint8(2), equals(3));

      expect(Uint8List.fromList([1, 2, 3, 4]).getUint16(0), equals(258));
      expect(Uint8List.fromList([1, 2, 3, 4]).getUint16(1), equals(515));

      expect(Uint8List.fromList([1, 2, 3, 4]).getUint32(0), equals(16909060));
      expect(
          Uint8List.fromList([1, 2, 3, 4, 0]).getUint32(1), equals(33752064));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7])
              .getUint64(0)
              .toString(),
          equals('1108152157446'));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8])
              .getUint64(1)
              .toString(),
          equals('283686952306183'));

      //

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8])
              .getInt8(4)
              .toString(),
          equals('3'));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8])
              .getInt16(4)
              .toString(),
          equals('772'));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8])
              .getInt32(4)
              .toString(),
          equals('50595078'));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8])
              .getInt64(1)
              .toString(),
          equals('283686952306183'));

      //

      expect(Uint8List.fromList([1, 2, 3, 4])..setUint8(20, 1),
          equals([1, 20, 3, 4]));

      expect(Uint8List.fromList([1, 2, 3, 4])..setUint16(258, 1),
          equals([1, 1, 2, 4]));

      expect(Uint8List.fromList([1, 2, 3, 4, 5])..setUint32(0xFFFEFDFC, 1),
          equals([1, 255, 254, 253, 252]));

      expect(
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9])
            ..setUint64(0x1FFDFCFBFAF9F8, 1),
          equals([1, 0, 31, 253, 252, 251, 250, 249, 248]));

      //

      expect(Uint8List.fromList([1, 2, 3, 4])..setInt8(20, 1),
          equals([1, 20, 3, 4]));

      expect(Uint8List.fromList([1, 2, 3, 4])..setInt16(258, 1),
          equals([1, 1, 2, 4]));

      expect(Uint8List.fromList([1, 2, 3, 4, 5])..setInt32(0xFFFEFDFC, 1),
          equals([1, 255, 254, 253, 252]));

      expect(
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9])
            ..setInt64(0x1FFDFCFBFAF9F8, 1),
          equals([1, 0, 31, 253, 252, 251, 250, 249, 248]));

      //

      expect(Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfUint8(),
          equals([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfUint16(),
          equals([0, 258, 772, 1286, 1800]));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfUint32(),
          equals([258, 50595078]));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfUint64(),
          equals([1108152157446]));

      //

      expect(Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfInt8(),
          equals([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]));

      expect(Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfInt16(),
          equals([0, 258, 772, 1286, 1800]));

      expect(Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfInt32(),
          equals([258, 50595078]));

      expect(Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toListOfInt64(),
          equals([1108152157446]));

      //

      expect(Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).toUint8List(),
          equals([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]));

      {
        var ns = [0, 0, 1, 2, 3, 4, 5, 6, 7, 8];
        var bs = Uint8List.fromList(ns);

        expect(bs.asUint8List, equals(bs));
        expect(bs.toUint8List(), equals(bs));

        expect(identical(bs.asUint8List, bs), isTrue);
        expect(identical(bs.toUint8List(), bs), isFalse);
      }

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).encodeUint8List(),
          equals([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]));

      expect(
          Uint8List.fromList([0, 0, 1, 2, 3, 4, 5, 6, 7, 8]).encodeUint16List(),
          equals([0, 0, 0, 0, 0, 1, 0, 2, 0, 3, 0, 4, 0, 5, 0, 6, 0, 7, 0, 8]));

      expect(Uint8List.fromList([0, 1, 2]).encodeUint32List(),
          equals([0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 2]));

      expect(
          Uint8List.fromList([0, 1, 2]).encodeUint64List(),
          equals([
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            2
          ]));
    });
  });
}
