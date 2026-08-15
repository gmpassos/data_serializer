@TestOn('vm')
@Tags(['bytes', 'file'])
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:data_serializer/data_serializer_io.dart';
import 'package:test/test.dart';

void main() {
  group('BytesFileIO', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('data_serializer_file_edge');
    });

    tearDown(() {
      if (tmp.existsSync()) tmp.deleteSync(recursive: true);
    });

    BytesFileIO openFile(String name, List<int> bytes) {
      var file = File('${tmp.path}/$name')..writeAsBytesSync(bytes);
      return BytesFileIO(file.openSync(mode: FileMode.append));
    }

    test('the public constructor takes the length from the file', () {
      var io = openFile('a.bin', [1, 2, 3, 4, 5]);
      addTearDown(io.close);

      expect(io.length, equals(5));
    });

    test('a declared length larger than the file grows its capacity', () {
      var file = File('${tmp.path}/grow.bin')..writeAsBytesSync([1, 2]);
      var io = BytesFileIO(file.openSync(mode: FileMode.append), length: 64);
      addTearDown(io.close);

      expect(io.length, equals(64));
      expect(io.capacity, greaterThanOrEqualTo(64));
    });

    test('readTo with no explicit length moves what remains', () {
      var io = openFile('b.bin', [1, 2, 3, 4]);
      addTearDown(io.close);

      io.seek(1);
      var dst = BytesBuffer();

      expect(io.readTo(dst.bytesIO), equals(3));
      expect(dst.toBytes(), equals([2, 3, 4]));
    });

    test('writeFrom with no explicit length takes what remains', () {
      var io = openFile('c.bin', []);
      addTearDown(io.close);

      var src = BytesBuffer.from(Uint8List.fromList([7, 8, 9]));

      expect(io.writeFrom(src.bytesIO), equals(3));
      expect(io.length, equals(3));
    });

    test('its int codec identifies itself', () {
      var io = openFile('d.bin', [0, 0, 0, 0]);
      addTearDown(io.close);

      expect(io.bytesData.toString(), contains('FileDataIntCodec'));
    });
  });
}
