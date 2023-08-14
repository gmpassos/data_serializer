@TestOn('vm')
@Tags(['bytes'])
import 'package:data_serializer/data_serializer.dart';
import 'package:data_serializer/src/bytes_io_file.dart';
import 'package:test/test.dart';

import 'data_serializer_bytes_buffer_test_base.dart';
import 'tests_utils.dart';

void main() {
  group('BytesBuffer (file)', () {
    final tempDir = createTempDirectory();

    tearDownAll(() {
      deleteTempDirectory(tempDir);
    });

    doBytesBufferTests(
      ([lng]) {
        lng ??= 0;
        var tempFile = createTempFile(tempDir, lng);
        var io = BytesFileIO.fromFile(tempFile, length: 0);
        return BytesBuffer.fromIO(io);
      },
      (bs, off, lng) {
        lng ??= bs.length - off;

        var tempFile = createTempFile(tempDir, lng);
        var bytes = bs.sublist(off, off + lng);
        tempFile.writeAsBytesSync(bytes, flush: true);

        var io = BytesFileIO.fromFile(tempFile);
        return BytesBuffer.fromIO(io);
      },
    );
  });
}
