@Tags(['num', 'platform'])
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

const testSafeNumbers = {
  1: '00000000 00000001',
  -1: 'FFFFFFFF FFFFFFFF',
  2: '00000000 00000002',
  -2: 'FFFFFFFF FFFFFFFE',
  123: '00000000 0000007B',
  -123: 'FFFFFFFF FFFFFF85',
  70123: '00000000 000111EB',
  268435455: '00000000 0FFFFFFF',
  -268435455: 'FFFFFFFF F0000001',
  267324344: '00000000 0FEF0BB8',
  -267324344: 'FFFFFFFF F010F448',
  4294967296: '00000001 00000000',
  -4294967296: 'FFFFFFFF 00000000',
  4294967295: '00000000 FFFFFFFF',
  -4294967295: 'FFFFFFFF 00000001',
  4294967294: '00000000 FFFFFFFE',
  -4294967294: 'FFFFFFFF 00000002',
  4294967293: '00000000 FFFFFFFD',
  -4294967293: 'FFFFFFFF 00000003',
  4264967294: '00000000 FE363C7E',
  -4264967294: 'FFFFFFFF 01C9C382',
  4294665294: '00000000 FFFB644E',
  -4294665294: 'FFFFFFFF 00049BB2',
  68719476735: '0000000F FFFFFFFF',
  -68719476735: 'FFFFFFF0 00000001',
  1099511627775: '000000FF FFFFFFFF',
  -1099511627775: 'FFFFFF00 00000001',
  17592186044415: '00000FFF FFFFFFFF',
  -17592186044415: 'FFFFF000 00000001',
  281474976710655: '0000FFFF FFFFFFFF',
  -281474976710655: 'FFFF0000 00000001',
  4503599627370495: '000FFFFF FFFFFFFF',
  -4503599627370495: 'FFF00000 00000001',
  9007199254740991: '001FFFFF FFFFFFFF',
  -9007199254740991: 'FFE00000 00000001',
};

final p = DataSerializerPlatform();

void _testNumber(int n, String result) {
  print('---> $n > ${(n >> 32).toHex32()} + ${n.toHex32()}');

  var r64 = result.replaceAll(RegExp(r'\s'), '').decodeHex();
  expect(r64.length, equals(8));

  var bs1 = Uint8List(8);
  var bs2 = Uint8List(8);

  p.writeUint64(bs1, n);
  p.writeInt64(bs2, n);

  expect(bs1, equals(r64));
  expect(bs2, equals(r64));

  print('   > $n > ${n.toHex64()}');

  int nRead1 = p.readUint64(bs1);
  int nRead2 = p.readInt64(bs2);

  expect(nRead1, equals(n),
      reason: 'n: $n > ${n.toHex64()} != $nRead1 > ${nRead1.toHex64()}');
  expect(nRead2, equals(n));

  expect(p.isSafeInteger(n), isTrue,
      reason: 'Not safe number($n) for platform: $p');

  p.checkSafeInteger(n);
}

void main() {
  group('DataSerializerPlatform', () {
    setUp(() {});

    test('53 bits Limits', () {
      expect(p.isSafeInteger(9007199254740991), isTrue);
      expect(p.isSafeInteger(-9007199254740991), isTrue);

      p.checkSafeInteger(9007199254740991);
      p.checkSafeInteger(-9007199254740991);

      expect(p.isSafeIntegerByBigInt(BigInt.from(9007199254740991)), isTrue);
      expect(p.isSafeIntegerByBigInt(BigInt.from(-9007199254740991)), isTrue);

      p.checkSafeIntegerByBigInt(BigInt.from(9007199254740991));
      p.checkSafeIntegerByBigInt(BigInt.from(-9007199254740991));

      expect(9007199254740991.isSafeInteger, isTrue);
      9007199254740991.checkSafeInteger();

      expect(BigInt.from(9007199254740991).isSafeInteger, isTrue);
      BigInt.from(9007199254740991).checkSafeInteger();
    });

    test('64 bits Limits', () {
      var max64 = BigInt.parse('9223372036854775807');
      var min64 = BigInt.parse('-9223372036854775808');

      var outUpper64 = max64 + BigInt.from(1024);
      var outLower64 = min64 - BigInt.from(1024);

      if (p.supportsFullInt64) {
        expect(p.isSafeIntegerByBigInt(max64), isTrue);
        expect(p.isSafeIntegerByBigInt(min64), isTrue);

        p.checkSafeIntegerByBigInt(max64);
        p.checkSafeIntegerByBigInt(min64);
      } else {
        expect(p.isSafeIntegerByBigInt(max64), isFalse);
        expect(p.isSafeIntegerByBigInt(min64), isFalse);

        expect(() => p.checkSafeIntegerByBigInt(max64), throwsStateError);
        expect(() => p.checkSafeIntegerByBigInt(min64), throwsStateError);
      }

      expect(p.isSafeIntegerByBigInt(outUpper64), isFalse);
      expect(p.isSafeIntegerByBigInt(outLower64), isFalse);

      expect(() => p.checkSafeIntegerByBigInt(outUpper64), throwsStateError);
      expect(() => p.checkSafeIntegerByBigInt(outLower64), throwsStateError);
    });

    test(
      'testSafeNumbers',
      () {
        print('** Testing testSafeNumbers: ${testSafeNumbers.length}');

        for (var e in testSafeNumbers.entries) {
          _testNumber(e.key, e.value);
        }
      },
      //skip: true,
    );

    test(
      'test sequence',
      () {
        for (var endian in [Endian.big, Endian.little]) {
          print(
              '** Testing numbers sequence (${endian == Endian.big ? 'BE' : 'LE'})...');

          var total = 0;
          for (var n = 0xAA; n < 0xFFFFFFFFFF; n += (255 * 255 * 3)) {
            var bs1 = Uint8List(8);
            var bs2 = Uint8List(8);

            p.writeUint64(bs1, n, 0, endian);
            p.writeInt64(bs2, n, 0, endian);

            var nRead1 = p.readUint64(bs1, 0, endian);
            var nRead2 = p.readUint64(bs1, 0, endian);

            expect(nRead1, equals(n));
            expect(nRead2, equals(n));
            total++;
          }

          print('-- Tested $total numbers.');
        }
      },
      //skip: true,
    );

    test(
      'test sequence',
      () {
        for (var endian in [Endian.big, Endian.little]) {
          print(
              '** Testing numbers sequence (${endian == Endian.big ? 'BE' : 'LE'})...');

          var total = 0;
          for (var n = 0xAA; n < 0xFFFFFFFFFF; n += (255 * 255 * 3)) {
            var bs1a = Uint8List(8);
            var bs2a = Uint8List(8);
            var bsh1a = ByteDataIntCodec(bs1a.asByteData());
            var bsh2a = ByteDataIntCodec(bs2a.asByteData());

            var bs1b = Uint8List(8);
            var bs2b = Uint8List(8);
            var bsh1b = bs1b.asByteData();
            var bsh2b = bs2b.asByteData();

            p.setDataTypeHandlerUint64(bsh1a, n, 0, endian);
            p.setUint64(bsh1b, n, 0, endian);

            p.setDataTypeHandlerInt64(bsh2a, n, 0, endian);
            p.setInt64(bsh2b, n, 0, endian);

            final endianName = endian.isBigEndian ? 'big' : 'little';

            expect(bs1a, equals(bs1b), reason: "endian: $endianName");
            expect(bs2a, equals(bs2b), reason: "endian: $endianName");

            var nRead1a = p.getDataTypeHandlerUint64(bsh1a, 0, endian);
            var nRead1b = p.getUint64(bsh1b, 0, endian);

            expect(nRead1a, equals(nRead1b), reason: "endian: $endianName");

            var nRead2a = p.getDataTypeHandlerUint64(bsh2a, 0, endian);
            var nRead2b = p.getUint64(bsh2b, 0, endian);

            expect(nRead2a, equals(nRead2b), reason: "endian: $endianName");

            expect(nRead1a, equals(n));
            expect(nRead2a, equals(n));
            total++;
          }

          print('-- Tested $total numbers.');
        }
      },
    );
  });
}
