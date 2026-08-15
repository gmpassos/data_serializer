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
        equals(Leb128.encodeUnsigned(1000000) + Leb128.encodeSigned(-1000000)),
      );

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
        ]),
      );

      expect(bs.position, equals(bs.toBytes().length));

      bs.seek(0);
      expect(bs.position, equals(0));

      expect(bs.readLeb128UnsignedInt(), equals(1000000));
      expect(bs.readLeb128SignedInt(), equals(-1000000));

      expect(bs.readLeb128Block(), equals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0]));

      expect(bs.readLeb128String(), equals("Foooooooooooooooooooooooooooooo"));
    });

    /// Reads back a value written with [BytesBuffer.writeLeb128SignedInt].
    int roundTripSigned(int n) {
      var bs = BytesBuffer()..writeLeb128SignedInt(n);
      bs.seek(0);
      return bs.readLeb128SignedInt();
    }

    test('readLeb128SignedInt sign-extends single-byte negatives', () {
      // A single-byte value has no continuation byte at all, so the sign has to
      // come from the terminating byte. Reading it from the *previous* byte
      // left every one of these positive: `-2` came back as `126`.
      for (var n in [-1, -2, -3, -32, -63, -64]) {
        expect(roundTripSigned(n), equals(n), reason: 'signed $n');
      }
    });

    test('readLeb128SignedInt does not sign-extend positives', () {
      // The mirror failure: `64` encodes as `[0xC0, 0x00]`, and reading the
      // sign from the first byte (`0xC0 & 0x40` set) turned it into `-16320`.
      for (var n in [64, 65, 127, 128, 1000, 8192, 1 << 20]) {
        expect(roundTripSigned(n), equals(n), reason: 'signed $n');
      }
    });

    test('readLeb128SignedInt agrees with Leb128.decodeSigned', () {
      // The static decoder was always correct; the buffer one is what drifted.
      // Pinning them together is what keeps a fix on one side from being
      // undone on the other.
      for (var n = -100000; n <= 100000; n += 7) {
        var bytes = Leb128.encodeSigned(n);
        var viaBuffer = roundTripSigned(n);

        expect(viaBuffer, equals(n), reason: 'signed $n');
        expect(
          viaBuffer,
          equals(Leb128.decodeSigned(bytes)),
          reason: 'buffer and static decoder disagree for $n',
        );
      }
    });

    test('readLeb128SignedInt over a wide range', () {
      // Built by multiplication, not `1 << 40`: a shift is a 32-bit operation
      // on the web, so the literal would silently be `0` there and the case
      // would not test what it claims to.
      const pow2_28 = 268435456;
      const pow2_31 = 2147483648;
      const pow2_35 = 34359738368;
      const pow2_45 = 35184372088832;

      for (var n in [
        0,
        1,
        -1,
        63,
        -63,
        64,
        -64,
        8191,
        -8191,
        8192,
        -8192,
        pow2_28,
        -pow2_28,
        pow2_31,
        -pow2_31,
        pow2_35,
        -pow2_35,
        pow2_45,
        -pow2_45,
        // The largest magnitude a JavaScript double represents exactly.
        9007199254740991,
        -9007199254740991,
      ]) {
        expect(roundTripSigned(n), equals(n), reason: 'signed $n');
      }
    });

    test('readLeb128SignedInt at microsecond-timestamp magnitudes', () {
      // Not a curiosity: a LEB128 negative sign-extends into every bit below
      // its terminating byte, so the *unsigned* form of a negative is about
      // `2^shift` — which left the exact range of a JavaScript double once the
      // magnitude passed roughly 2^49. `DateTime.microsecondsSinceEpoch` sits
      // right there, around 2^50.6, so a pre-1970 timestamp was corrupted on
      // the web while looking perfectly ordinary.
      const microsPerYear = 31557600000000;

      for (var years = 1; years <= 55; years += 6) {
        var micros = microsPerYear * years;

        expect(roundTripSigned(micros), equals(micros));
        expect(roundTripSigned(-micros), equals(-micros));
      }

      // The boundary itself, from just below the split to the exact-integer
      // limit.
      for (var n in [
        562949953421311, // 2^49 - 1
        562949953421312, // 2^49
        1125899906842624, // 2^50
        2251799813685248, // 2^51
        4503599627370496, // 2^52
        9007199254740991, // 2^53 - 1
      ]) {
        expect(roundTripSigned(n), equals(n), reason: 'signed $n');
        expect(roundTripSigned(-n), equals(-n), reason: 'signed ${-n}');
      }
    });

    test('readLeb128UnsignedInt over a wide range', () {
      // The unsigned reader shares the same accumulator, which was where values
      // past 2^32 were being truncated on the web.
      const cases = [
        0,
        1,
        127,
        128,
        16383,
        16384,
        268435456, // 2^28
        4294967295, // 2^32 - 1
        4294967296, // 2^32
        35184372088832, // 2^45
        9007199254740991, // 2^53 - 1
      ];

      for (var n in cases) {
        var bs = BytesBuffer()..writeLeb128UnsignedInt(n);
        bs.seek(0);
        expect(bs.readLeb128UnsignedInt(), equals(n), reason: 'unsigned $n');

        expect(
          Leb128.decodeUnsigned(Leb128.encodeUnsigned(n)),
          equals(n),
          reason: 'static unsigned $n',
        );
      }
    });

    test('Leb128.decodeSigned over a wide range', () {
      // The static pair is what the buffer readers are pinned to, so it is
      // checked across the same range.
      const pow2_35 = 34359738368;
      const pow2_45 = 35184372088832;

      for (var n in [
        268435456,
        -268435456,
        pow2_35,
        -pow2_35,
        pow2_45,
        -pow2_45,
        9007199254740991,
        -9007199254740991,
      ]) {
        expect(
          Leb128.decodeSigned(Leb128.encodeSigned(n)),
          equals(n),
          reason: 'static signed $n',
        );
      }
    });

    test('signed and unsigned reads stay independent in one buffer', () {
      var bs = BytesBuffer();
      bs.writeLeb128SignedInt(-2);
      bs.writeLeb128UnsignedInt(64);
      bs.writeLeb128SignedInt(64);
      bs.writeLeb128SignedInt(-1000);

      bs.seek(0);
      expect(bs.readLeb128SignedInt(), equals(-2));
      expect(bs.readLeb128UnsignedInt(), equals(64));
      expect(bs.readLeb128SignedInt(), equals(64));
      expect(bs.readLeb128SignedInt(), equals(-1000));
    });

    test('basic 3', () {
      var bs = BytesBuffer();

      bs.writeLeb128Block([1, 2, 3, 4, 5, 6, 7, 8, 9, 0]);
      bs.writeLeb128Block([10, 20, 30]);

      expect(bs.length, equals(1 + 10 + 1 + 3));

      expect(
        bs.toBytes(),
        equals([10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 3, 10, 20, 30]),
      );

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

      expect(
        bs.toBytes(),
        equals([10, 1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 3, 10, 20, 30]),
      );

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
