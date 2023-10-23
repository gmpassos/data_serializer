import 'package:data_serializer/src/bits_buffer.dart';
import 'package:test/test.dart';

void main() {
  group('BitsBuffer', () {
    test('writeBits: 0xFF @ 1...', () {
      var buffer = BitsBuffer();

      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(1));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(2));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(3));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(4));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(5));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(6));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(7));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.toBytes(), equals([0xFF]));
    });

    test('writeBits: 0xFF @ 2 3...', () {
      var buffer = BitsBuffer();
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.writeBits(0x3, 2), equals(2));
      expect(buffer.unflushedBitsLength, equals(2));

      expect(buffer.writeBits(0x7, 3), equals(3));
      expect(buffer.unflushedBitsLength, equals(5));

      expect(buffer.writeBits(0x7, 3), equals(3));
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.toBytes(), equals([0xFF]));
    });

    test('writeBits: 0xD3 @ 1...', () {
      var buffer = BitsBuffer();
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(1));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(2));
      expect(buffer.writeBits(0, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(3));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(4));
      expect(buffer.writeBits(0, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(5));
      expect(buffer.writeBits(0, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(6));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(7));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.toBytes(), equals([0xD3]));
    });

    test('writeBits: 0xD3 @ 2...', () {
      var buffer = BitsBuffer();
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.writeBits(0x3, 2), equals(2));
      expect(buffer.unflushedBitsLength, equals(2));

      expect(buffer.writeBits(0x1, 2), equals(2));
      expect(buffer.unflushedBitsLength, equals(4));

      expect(buffer.writeBits(0, 2), equals(2));
      expect(buffer.unflushedBitsLength, equals(6));

      expect(buffer.writeBits(0x3, 2), equals(2));
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.toBytes(), equals([0xD3]));
    });

    test('writeBits: 0xD3 @ 7 2 7 ; readBits: 1 7', () {
      var buffer = BitsBuffer();
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.writeBits(0xFF, 7), equals(7));
      expect(buffer.unflushedBitsLength, equals(7));

      expect(buffer.writeBits(0x1, 2), equals(2));
      expect(buffer.unflushedBitsLength, equals(1));

      expect(buffer.writeBits(0xFF, 7), equals(7));
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.toBytes(), [0xFE, 0xFF]);

      expect(buffer.position, equals(2));

      buffer.seek(0);

      expect(buffer.position, equals(0));
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.readBits(1), equals(1));
      expect(buffer.position, equals(1));
      expect(buffer.unflushedBitsLength, equals(7));

      expect(buffer.readBits(7), equals(0x7E));
      expect(buffer.position, equals(1));
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.remaining, equals(1));

      expect(buffer.readBits(8), equals(0xFF));
      expect(buffer.position, equals(2));
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.remaining, equals(0));
    });
  });
}
