@Tags(['bytes'])
import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

import 'data_serializer_bytes_buffer_test_base.dart';

void main() {
  group('BytesBuffer', () {
    doBytesBufferTests(
      ([lng]) => BytesBuffer(lng ?? 32),
      (bs, off, lng) =>
          BytesBuffer.from(bs, offset: off, length: lng, copyBuffer: true),
    );
  });
}
