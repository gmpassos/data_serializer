import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('extension', () {
    setUp(() {});

    test('StringExtension', () {
      expect('abc'.encodeLatin1Bytes(), equals([97, 98, 99]));
      expect('€'.encodeUTF8Bytes(), equals([226, 130, 172]));
    });
  });
}
