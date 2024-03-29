import 'package:data_serializer/data_serializer_io.dart';
import 'package:test/test.dart';

const integerRange = 1000000;

void main() {
  group('Leb128', () {
    const specialCases = [
      0,
      1,
      2,
      3,
      4,
      5,
      11,
      32,
      64,
      128,
      1000000,
      10000000,
      100000000,
      120000000,
    ];

    test('encodeUnsigned/decodeUnsigned', () {
      for (var n in specialCases) {
        for (var i = -3; i <= 3; ++i) {
          var n2 = n + i;
          if (n2 < 0) continue;

          var bs = Leb128.encodeUnsigned(n2);
          expect(Leb128.decodeUnsigned(bs), equals(n2));
        }
      }
    });

    test('encodeSigned/decodeSigned', () {
      for (var n in specialCases) {
        var n2 = -n;

        var bs = Leb128.encodeSigned(n);
        expect(Leb128.decodeSigned(bs), equals(n));

        var bs2 = Leb128.encodeSigned(n2);
        expect(Leb128.decodeSigned(bs2), equals(n2));

        for (var i = -3; i <= 3; ++i) {
          var n3 = n + i;

          var bs3 = Leb128.encodeSigned(n3);
          expect(Leb128.decodeSigned(bs3), equals(n3));
        }

        for (var i = -3; i <= 3; ++i) {
          var n3 = n2 + i;

          var bs3 = Leb128.encodeSigned(n3);
          expect(Leb128.decodeSigned(bs3), equals(n3));
        }
      }

      for (var n = -1000000; n <= 1000000; n += 11) {
        for (var i = -3; i <= 3; ++i) {
          var n3 = n + i;

          var bs3 = Leb128.encodeSigned(n3);
          expect(Leb128.decodeSigned(bs3), equals(n3));
        }
      }

      for (var n = -10000000; n <= 10000000; n += 211) {
        for (var i = -3; i <= 3; ++i) {
          var n3 = n + i;

          var bs3 = Leb128.encodeSigned(n3);
          expect(Leb128.decodeSigned(bs3), equals(n3));
        }
      }

      var max = (1 << 36);
      var min = -max;

      for (var n = min; n <= max; n += 999983) {
        for (var i = -3; i <= 3; ++i) {
          var n3 = n + i;

          var bs3 = Leb128.encodeSigned(n3);
          expect(Leb128.decodeSigned(bs3), equals(n3));
        }
      }
    });

    test('encodeUnsigned/decodeUnsigned', () {
      for (var i = -integerRange; i < integerRange; ++i) {
        var bs = Leb128.encodeUnsigned(i);
        var n = Leb128.decodeUnsigned(bs);
        expect(n, equals(i.abs()));
      }
    });

    test('encodeSigned/decodeSigned', () {
      for (var i = -integerRange; i < integerRange; ++i) {
        var bs = Leb128.encodeSigned(i);
        var n = Leb128.decodeSigned(bs);
        expect(n, equals(i));
      }
    });

    test('encodeVarInt7/decodeVarInt7', () {
      for (var i = -64; i <= 63; ++i) {
        var b = Leb128.encodeVarInt7(i);
        var n = Leb128.decodeVarInt7(b);
        expect(n, equals(i));
      }

      expect(() => Leb128.encodeVarInt7(-65), throwsArgumentError);
      expect(() => Leb128.encodeVarInt7(64), throwsArgumentError);
    });

    test('encodeVarUInt7/decodeVarUInt7', () {
      for (var i = 0; i <= 127; ++i) {
        var b = Leb128.encodeVarUInt7(i);
        var n = Leb128.decodeVarUInt7(b);
        expect(n, equals(i));
      }

      expect(() => Leb128.encodeVarUInt7(-1), throwsArgumentError);
      expect(() => Leb128.encodeVarUInt7(128), throwsArgumentError);
    });
  });

  group('BytesBufferLeb128Extension', () {
    test('basic 1', () {
      var bs = BytesBuffer();

      bs.writeLeb128UnsignedInt(1000000);

      var p0 = bs.position;
      expect(bs.position, equals(bs.length));

      bs.writeLeb128SignedInt(-1000000);
      var p1 = bs.position;
      expect(bs.position, equals(bs.length));

      expect(bs.toBytes(), equals([192, 132, 61, 192, 251, 66]));

      expect(
          bs.toBytes(),
          equals(
              Leb128.encodeUnsigned(1000000) + Leb128.encodeSigned(-1000000)));

      expect(bs.position, equals(bs.length));
      expect(bs.position, equals(bs.toBytes().length));

      bs.seek(0);
      expect(bs.position, equals(0));

      expect(bs.readLeb128UnsignedInt(), equals(1000000));
      expect(bs.position, equals(p0));

      expect(bs.readLeb128SignedInt(), equals(-1000000));
      expect(bs.position, equals(p1));
    });

    test('basic 2', () {
      var bs = BytesBuffer();

      bs.writeLeb128UnsignedInt(1000000);

      bs.writeLeb128SignedInt(-1000000);

      bs.writeLeb128Block([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);

      bs.writeLeb128String("Foooooooooooooooooooooooooooooo");

      expect(
          bs.toBytes(),
          equals([
            192,
            132,
            61,
            192,
            251,
            66,
            11,
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            0,
            31,
            70,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
            111,
          ]));

      expect(bs.position, equals(bs.toBytes().length));

      bs.seek(0);
      expect(bs.position, equals(0));

      expect(bs.readLeb128UnsignedInt(), equals(1000000));
      expect(bs.readLeb128SignedInt(), equals(-1000000));

      expect(bs.readLeb128Block(), equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));

      expect(bs.readLeb128String(), equals("Foooooooooooooooooooooooooooooo"));
    });

    test('basic 3', () {
      var bs = BytesBuffer();

      bs.writeLeb128Block([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
      bs.writeLeb128Block([10, 20, 30]);

      expect(bs.length, equals(1 + 10 + 1 + 3));

      expect(bs.toBytes(),
          equals([10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 3, 10, 20, 30]));

      bs.seek(0);

      expect(bs.readLeb128Block(), equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));

      expect(bs.readLeb128Block(), equals([10, 20, 30]));
    });

    test('basic 4', () {
      var bs = BytesBuffer();

      {
        var blk = BytesBuffer.from([1, 2, 3, 4, 5, 6, 7, 8, 9, 0].asUint8List);
        bs.writeLeb128BlockFrom(blk);
      }

      {
        var blk = BytesBuffer.from([10, 20, 30].asUint8List);
        bs.writeLeb128BlockFrom(blk);
      }

      expect(bs.length, equals(1 + 10 + 1 + 3));

      expect(bs.toBytes(),
          equals([10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 3, 10, 20, 30]));

      bs.seek(0);

      {
        var blk = BytesBuffer();
        bs.readLeb128BlockTo(blk);

        expect(blk.toBytes(), equals([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));
      }

      {
        var blk = BytesBuffer();
        bs.readLeb128BlockTo(blk);

        expect(blk.toBytes(), equals([10, 20, 30]));
      }
    });
  });
}
