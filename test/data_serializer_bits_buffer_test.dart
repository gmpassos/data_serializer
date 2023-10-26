import 'package:data_serializer/src/bits_buffer.dart';
import 'package:test/test.dart';

void main() {
  group('BitsBuffer', () {
    test('writeBits: 0xFF @ 1...', () {
      var buffer = BitsBuffer();

      expect(buffer.bytesBuffer.position, equals(0));
      expect(buffer.bytesBuffer.length, equals(0));
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.length, equals(0));

      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.bytesBuffer.position, equals(0));
      expect(buffer.bytesBuffer.length, equals(0));
      expect(buffer.unflushedBitsLength, equals(1));
      expect(buffer.length, equals(0));

      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(2));
      expect(buffer.bytesBuffer.position, equals(0));
      expect(buffer.bytesBuffer.length, equals(0));
      expect(buffer.length, equals(0));

      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(3));
      expect(buffer.bytesBuffer.position, equals(0));
      expect(buffer.bytesBuffer.length, equals(0));
      expect(buffer.length, equals(0));

      expect(buffer.writeBit(true), equals(1));
      expect(buffer.unflushedBitsLength, equals(4));
      expect(buffer.bytesBuffer.position, equals(0));
      expect(buffer.bytesBuffer.length, equals(0));
      expect(buffer.length, equals(0));

      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(5));
      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(6));
      expect(buffer.length, equals(0));

      expect(buffer.writeBit(true), equals(1));
      expect(buffer.unflushedBitsLength, equals(7));
      expect(buffer.bytesBuffer.position, equals(0));
      expect(buffer.bytesBuffer.length, equals(0));
      expect(buffer.length, equals(0));
      expect(buffer.length, equals(0));

      expect(buffer.writeBits(1, 1), equals(1));
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.bytesBuffer.position, equals(1));
      expect(buffer.bytesBuffer.length, equals(1));
      expect(buffer.length, equals(1));

      expect(buffer.toBytes(), equals([0xFF]));

      buffer.writeByte(0x02);

      expect(buffer.toBytes(), equals([0xFF, 0x02]));

      buffer.writeBytes([0x03, 0x04]);

      expect(buffer.toBytes(), equals([0xFF, 0x02, 0x03, 0x04]));
      expect(buffer.hasUnflushedBits, isFalse);

      expect(buffer.writeBits(0x05, 3), equals(3));
      expect(buffer.hasUnflushedBits, isTrue);

      expect(buffer.writePadding(), 5);
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.toBytes(), equals([0xFF, 0x02, 0x03, 0x04, 0xB0]));

      buffer.seek(0);

      var paddingPos = buffer.length - 1;

      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBit(), equals(1));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.position, equals(1));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBits(2), equals(0x03));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.position, equals(1));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBits(5), equals(0x1F));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.position, equals(1));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBits(8), equals(0x02));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.position, equals(2));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readByte(), equals(0x03));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.position, equals(3));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readByte(), equals(0x04));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.position, equals(4));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBit(), equals(1));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.position, equals(5));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBit(), equals(0));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.position, equals(5));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isFalse);

      expect(buffer.readBit(), equals(1));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.position, equals(5));
      expect(buffer.isAtPadding(paddingPosition: paddingPos), isTrue);
      expect(buffer.hasUnflushedBits, isFalse);
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

    test('fromBytes', () {
      var buffer = BitsBuffer.fromBytes([0xA5, 0x5A]);

      expect(buffer.toBytes(), equals([0xA5, 0x5A]));

      expect(buffer.readBits(8), equals(0xA5));
      expect(buffer.readBits(8), equals(0x5A));

      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.unflushedBitsLength, equals(0));

      expect(buffer.writeBits(0x02, 2), equals(2));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(2));

      expect(() => buffer.checkUnflushedBits(), throwsA(isA<StateError>()));

      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(2));

      expect(buffer.writeBits(0x02, 5), equals(5));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(7));

      expect(() => buffer.checkUnflushedBits(), throwsA(isA<StateError>()));

      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(7));

      expect(buffer.writeBits(0x01, 1), equals(1));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.unflushedBitsLength, equals(0));

      buffer.checkUnflushedBits();

      expect(buffer.hasUnflushedBits, isFalse);

      var lng = buffer.length;

      expect(buffer.writeBits(0x01, 1), equals(1));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(1));
      expect(buffer.length, equals(lng));

      expect(buffer.writeByte(0xff), equals(1));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(1));
      expect(buffer.length, equals(lng + 1));

      lng = buffer.length;

      expect(buffer.writeBytes([0xfe, 0xfd]), equals(2));
      expect(buffer.hasUnflushedBits, isTrue);
      expect(buffer.unflushedBitsLength, equals(1));
      expect(buffer.length, equals(lng + 2));

      expect(buffer.writeBits(0xFF, 7), equals(7));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.length, equals(lng + 3));

      expect(buffer.writeBits(0xA5, 8), equals(8));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.length, equals(lng + 4));

      expect(buffer.writePadding(), equals(8));
      expect(buffer.hasUnflushedBits, isFalse);
      expect(buffer.unflushedBitsLength, equals(0));
      expect(buffer.length, equals(lng + 5));
    });
  });
}
