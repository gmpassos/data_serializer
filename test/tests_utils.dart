import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:path/path.dart' as pack_path;

Directory createTempDirectory() =>
    Directory.systemTemp.createTempSync('data_serializer-tests-temp');

final Random _random = Random();

File createTempFile(Directory dir, int capacity) {
  var n = _random.nextInt(999999999);

  for (var i = 0; i < 1000; ++i) {
    var f = File(pack_path.join(dir.path, 'test-file-$n-$i.temp'));
    if (!f.existsSync()) {
      f.writeAsBytesSync(Uint8List(capacity), flush: true);
      return f;
    }
  }

  throw StateError("Can't create temporary file at: $dir");
}

void deleteTempDirectory(Directory tempDir) {
  var files = tempDir.listSync().where((f) => f.path.endsWith('.temp'));
  for (var f in files) {
    f.deleteSync();
  }
  tempDir.deleteSync();
}
