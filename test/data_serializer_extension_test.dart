import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('extension', () {
    setUp(() {});

    test('StringExtension', () {
      expect('abc'.encodeLatin1Bytes(), equals([97, 98, 99]));
      expect('€'.encodeUTF8Bytes(), equals([226, 130, 172]));
    });

    test('Uint8ListDataExtension', () {
      var bytes = [1, 2, 3, 4, 5, 6, 7, 8].toUint8List();

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
  });
}
