import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void main() {
  group('tools', () {
    setUp(() {});

    test('hex', () {
      var h = hex.encode('ABCD'.encodeLatin1());
      expect(h, equals('41424344'));

      expect(hex.decode('41424344'), equals([65, 66, 67, 68]));
    });
  });
}
