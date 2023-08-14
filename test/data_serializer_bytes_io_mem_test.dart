@Tags(['bytes'])
import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

import 'data_serializer_bytes_io_test_base.dart';

void main() {
  group('BytesIO', () {
    test('capacity/length BytesUint8ListIO(0)',
        () => doBytesIOTests(BytesUint8ListIO(0)));
    test('capacity/length BytesUint8ListIO(1)',
        () => doBytesIOTests(BytesUint8ListIO(1)));
    test('capacity/length BytesUint8ListIO(2)',
        () => doBytesIOTests(BytesUint8ListIO(2)));
    test('capacity/length BytesUint8ListIO(3)',
        () => doBytesIOTests(BytesUint8ListIO(3)));
    test('capacity/length BytesUint8ListIO(4)',
        () => doBytesIOTests(BytesUint8ListIO(4)));
    test('capacity/length BytesUint8ListIO(5)',
        () => doBytesIOTests(BytesUint8ListIO(5)));
    test('capacity/length BytesUint8ListIO(6)',
        () => doBytesIOTests(BytesUint8ListIO(6)));
    test('capacity/length BytesUint8ListIO(7)',
        () => doBytesIOTests(BytesUint8ListIO(7)));
    test('capacity/length BytesUint8ListIO(8)',
        () => doBytesIOTests(BytesUint8ListIO(8)));
    test('capacity/length BytesUint8ListIO(11)',
        () => doBytesIOTests(BytesUint8ListIO(11)));
    test('capacity/length BytesUint8ListIO(16)',
        () => doBytesIOTests(BytesUint8ListIO(16)));
    test('capacity/length BytesUint8ListIO(17)',
        () => doBytesIOTests(BytesUint8ListIO(17)));
    test('capacity/length BytesUint8ListIO(32)',
        () => doBytesIOTests(BytesUint8ListIO(32)));
    test('capacity/length BytesUint8ListIO(33)',
        () => doBytesIOTests(BytesUint8ListIO(33)));
  });
}
