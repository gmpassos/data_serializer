// No `dart:io` here: this suite also runs under `--platform chrome`. The
// file-backed cases live in `data_serializer_bytes_io_file_edge_cases_test.dart`,
// which is `@TestOn('vm')`.
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

/// A [Writable] that does not override [Writable.serializeBufferLength], so the
/// default is what sizes its buffer.
class _DefaultSizedWritable extends Writable {
  final List<int> bytes;

  _DefaultSizedWritable(this.bytes);

  @override
  int writeTo(BytesBuffer out) => out.writeAll(bytes);
}

void main() {
  group('BytesEmitter rejects data it cannot represent', () {
    test('at construction', () {
      expect(
        () => BytesEmitter(data: 'not bytes'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('String'),
          ),
        ),
      );
    });

    test('when added later', () {
      var emitter = BytesEmitter();
      expect(
        () => emitter.add(DateTime.utc(2020)),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('DateTime'),
          ),
        ),
      );
    });

    test('a null addition is a no-op', () {
      var emitter = BytesEmitter()..add(null);
      expect(emitter.length, equals(0));
      expect(emitter.output(), isEmpty);
    });

    test('the shapes it does accept', () {
      // The other side of the same guard, so the rejection above is not
      // mistaken for over-strictness.
      expect(BytesEmitter(data: 7).output(), equals([7]));
      expect(BytesEmitter(data: [1, 2]).output(), equals([1, 2]));
      expect(BytesEmitter(data: BytesEmitter(data: [3])).output(), equals([3]));
      expect(
        BytesEmitter(
          data: <BytesEmitter>[
            BytesEmitter(data: [4]),
            BytesEmitter(data: [5]),
          ],
        ).output(),
        equals([4, 5]),
      );
    });
  });

  group('BytesBufferError', () {
    test('reads usefully', () {
      // A diagnostic that is never exercised is what breaks when it is needed.
      var e = BytesBufferError('something went wrong');
      expect(e.message, equals('something went wrong'));
      expect(e.toString(), contains('BytesBuffer error'));
      expect(e.toString(), contains('something went wrong'));
    });

    test('an EOF is a BytesBufferError', () {
      var buffer = BytesBuffer.from(Uint8List.fromList([1]));
      buffer.seek(1);

      expect(() => buffer.readByte(), throwsA(isA<BytesBufferError>()));
    });
  });

  group('BytesUint8ListIO transfers default to what remains', () {
    test('readTo with no explicit length', () {
      var src = BytesBuffer.from(Uint8List.fromList([1, 2, 3, 4]));
      var dst = BytesBuffer();

      var moved = src.readTo(dst);

      expect(moved, equals(4));
      expect(dst.toBytes(), equals([1, 2, 3, 4]));
      expect(src.remaining, equals(0));
    });

    test('readTo from a partially consumed source', () {
      var src = BytesBuffer.from(Uint8List.fromList([1, 2, 3, 4]));
      src.readByte();

      var dst = BytesBuffer();
      expect(src.readTo(dst), equals(3));
      expect(dst.toBytes(), equals([2, 3, 4]));
    });

    test('writeFrom with no explicit length', () {
      var src = BytesBuffer.from(Uint8List.fromList([9, 8, 7]));
      var dst = BytesBuffer();

      expect(dst.writeFrom(src), equals(3));
      expect(dst.toBytes(), equals([9, 8, 7]));
    });

    test('the IO layer itself defaults the length', () {
      // `BytesBuffer` always resolves the length before delegating, so the
      // default inside `BytesUint8ListIO` is only reached by calling it
      // directly — which is a supported entry point.
      var src = BytesUint8ListIO.from(Uint8List.fromList([1, 2, 3]));
      var dst = BytesUint8ListIO(8)..ensureCapacity(3);

      expect(src.readTo(dst), equals(3));
      expect(dst.toBytes(0, 3), equals([1, 2, 3]));

      var src2 = BytesUint8ListIO.from(Uint8List.fromList([4, 5]));
      var dst2 = BytesUint8ListIO(8)..ensureCapacity(2);

      expect(dst2.writeFrom(src2), equals(2));
      expect(dst2.toBytes(0, 2), equals([4, 5]));
    });
  });

  group('ByteDataExtension length checks', () {
    ByteData sample() =>
        Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]).asByteData();

    test('a negative length is rejected', () {
      expect(
        () => sample().convertToUint8List(-1),
        throwsA(
          isA<RangeError>().having(
            (e) => e.toString(),
            'toString',
            contains('Negative length'),
          ),
        ),
      );
    });

    test('a length shorter than the buffer is rejected', () {
      // The buffer is 8 bytes, so asking for 4 would drop half of it.
      expect(() => sample().convertToUint8List(4), throwsRangeError);
    });

    test('the chunked message names the element size', () {
      expect(
        () => sample().convertToUint16List(1),
        throwsA(
          isA<RangeError>().having(
            (e) => e.toString(),
            'toString',
            contains('* 2'),
          ),
        ),
      );
    });

    test('an exact length converts', () {
      expect(sample().convertToUint8List(8), hasLength(8));
      expect(sample().convertToUint16List(4), hasLength(4));
      expect(sample().convertToUint32List(2), hasLength(2));
    });
  });

  group('DataSerializerPlatform shifts stay exact past 32 bits', () {
    // `<<` and `>>` are 32-bit operations where an `int` is a JavaScript
    // double, so the platform has to route around them. These cases are the
    // ones that were silently wrong: `shiftLeftInt(127, 28)` returned
    // `4026531840` instead of `34091302912`, any shift of 32 or more returned
    // `0`, and `shiftRightInt` truncated its operand before shifting.
    final platform = DataSerializerPlatform.instance;

    test('shiftLeftInt', () {
      // Bounded to results a JavaScript double still represents exactly.
      // Past that the platforms legitimately diverge — the VM wraps at 64 bits
      // while `BigInt.toInt()` saturates — and neither is what this guards.
      final maxExact = BigInt.from(9007199254740991);

      for (var n in [0, 1, 127, 255, 4294967295]) {
        for (var shift in [0, 1, 7, 14, 28, 31, 32, 35, 45]) {
          var expected = BigInt.from(n) << shift;
          if (expected > maxExact) continue;

          expect(
            platform.shiftLeftInt(n, shift),
            equals(expected.toInt()),
            reason: '$n << $shift',
          );
        }
      }
    });

    test('shiftLeftInt with a negative operand', () {
      for (var shift in [0, 7, 31, 32, 35]) {
        expect(
          platform.shiftLeftInt(-1, shift),
          equals((BigInt.from(-1) << shift).toInt()),
          reason: '-1 << $shift',
        );
      }
    });

    test('shiftRightInt', () {
      for (var n in [
        0,
        1,
        4294967295,
        4294967296,
        35184372088832,
        9007199254740991,
      ]) {
        for (var shift in [0, 1, 7, 14, 28, 32, 45]) {
          expect(
            platform.shiftRightInt(n, shift),
            equals((BigInt.from(n) >> shift).toInt()),
            reason: '$n >> $shift',
          );
        }
      }
    });

    test('shiftRightInt with a negative operand', () {
      for (var n in [-1, -1024, -4294967296]) {
        for (var shift in [0, 7, 32]) {
          expect(
            platform.shiftRightInt(n, shift),
            equals((BigInt.from(n) >> shift).toInt()),
            reason: '$n >> $shift',
          );
        }
      }
    });
  });

  group('DataSerializerPlatform 64-bit reads', () {
    final platform = DataSerializerPlatform.instance;

    test('getUint64 round trips what setUint64 wrote', () {
      var data = Uint8List(8).asByteData();

      // Distinct in every byte that matters, but still inside the range a
      // JavaScript double represents exactly — this suite also runs on Chrome.
      platform.setUint64(data, 0x0001020304050607);
      expect(platform.getUint64(data), equals(0x0001020304050607));

      platform.setUint64(data, 0, 0, Endian.little);
      expect(platform.getUint64(data, 0, Endian.little), equals(0));
    });

    test('getInt64 round trips a negative value', () {
      var data = Uint8List(8).asByteData();

      platform.setInt64(data, -42);
      expect(platform.getInt64(data), equals(-42));

      platform.setInt64(data, 1 << 40);
      expect(platform.getInt64(data), equals(1 << 40));
    });
  });

  group('BitsBuffer', () {
    test('isAtPadding defaults to the last byte', () {
      var bits = BitsBuffer();
      bits.writeBit(true);
      bits.writeBit(false);
      bits.writePadding();

      bits.seek(0);
      // Called with no argument, so the default padding position applies.
      expect(bits.isAtPadding(), isA<bool>());
    });

    test('toString reports the unflushed state', () {
      var bits = BitsBuffer();
      expect(bits.toString(), contains('unflushedBits'));

      bits.writeBit(true);
      expect(bits.toString(), contains('unflushedBitsLength'));
    });
  });

  group('Writable', () {
    test('uses a default buffer size when none is declared', () {
      var writable = _DefaultSizedWritable([1, 2, 3]);

      expect(writable.serializeBufferLength, equals(512));
      expect(Writable.doSerialize(writable), equals([1, 2, 3]));
    });
  });
}
