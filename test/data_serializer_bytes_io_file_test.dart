@TestOn('vm')
@Tags(['bytes', 'file'])
import 'dart:io';

import 'package:data_serializer/src/bytes_io_file.dart';
import 'package:test/test.dart';

import 'data_serializer_bytes_io_test_base.dart';
import 'tests_utils.dart';

void main() {
  group('BytesIO', () {
    final tempDir = createTempDirectory();

    tearDownAll(() {
      deleteTempDirectory(tempDir);
    });

    test('capacity/length BytesFileIO(0)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 0)));
    test('capacity/length BytesFileIO(1)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 1)));
    test('capacity/length BytesFileIO(2)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 2)));
    test('capacity/length BytesFileIO(3)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 3)));
    test('capacity/length BytesFileIO(4)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 4)));
    test('capacity/length BytesFileIO(5)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 5)));
    test('capacity/length BytesFileIO(6)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 6)));
    test('capacity/length BytesFileIO(7)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 7)));
    test('capacity/length BytesFileIO(8)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 8)));
    test('capacity/length BytesFileIO(11)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 11)));
    test('capacity/length BytesFileIO(16)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 16)));
    test('capacity/length BytesFileIO(17)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 17)));
    test('capacity/length BytesFileIO(32)',
        () => doBytesIOTests(_newBytesFileIO(tempDir, 32)));
    test('capacity/length BytesFileIO(33)',
        () async => doBytesIOTests(await _newBytesFileIOAsync(tempDir, 33)));
  });
}

BytesFileIO _newBytesFileIO(Directory tempDir, int capacity) {
  var tempFile = createTempFile(tempDir, capacity);
  var io = BytesFileIO.fromFile(tempFile, length: 0);
  expect(io.capacity, equals(io.randomAccessFile.lengthSync()));
  return io;
}

Future<BytesFileIO> _newBytesFileIOAsync(
    Directory tempDir, int capacity) async {
  var tempFile = createTempFile(tempDir, capacity);
  var io = await BytesFileIO.fromFileAsync(tempFile, length: 0);
  expect(io.capacity, equals(io.randomAccessFile.lengthSync()));
  return io;
}
