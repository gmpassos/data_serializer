import 'dart:math' as math;

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

void doBytesIOTests(BytesIO bsIO) {
  final initialCapacity = bsIO.capacity;

  expect(bsIO.position, equals(0));
  expect(bsIO.length, equals(0));
  expect(bsIO.capacity, equals(initialCapacity));

  expect(bsIO.toBytes(), equals([]));

  expect(bsIO.writeByte(1), equals(1));
  expect(bsIO.position, equals(1));
  expect(bsIO.length, equals(1));
  expect(bsIO.capacity, equals(math.max(initialCapacity, 1)));

  expect(bsIO.toBytes(), equals([1]));
  expect(bsIO.bytesTo((bs, off, lng) => bs.sublist(off, off + lng).toString()),
      equals('[1]'));

  expect(bsIO.seek(3), equals(1));

  expect(bsIO.writeByte(2), equals(1));
  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(2));
  expect(bsIO.capacity, equals(math.max(initialCapacity, 2)));

  bsIO.compact();
  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(2));
  expect(bsIO.capacity, equals(2));

  expect(bsIO.toBytes(), equals([1, 2]));

  expect(bsIO.toBytes(0, 1), equals([1]));
  expect(bsIO.toBytes(1, 1), equals([2]));
  expect(bsIO.toBytes(0), equals([1, 2]));
  expect(bsIO.toBytes(1), equals([2]));
  expect(bsIO.toBytes(2), equals([]));

  expect(bsIO.bytesTo((bs, off, lng) => '${bs.sublist(off, off + lng)}'),
      equals('[1, 2]'));
  expect(bsIO.bytesTo((bs, off, lng) => '${bs.sublist(off, off + lng)}', 0, 1),
      equals('[1]'));
  expect(bsIO.bytesTo((bs, off, lng) => '${bs.sublist(off, off + lng)}', 1, 1),
      equals('[2]'));

  expect(bsIO.indexOf(1), equals(0));
  expect(bsIO.indexOf(2), equals(1));
  expect(bsIO.indexOf(2, 0, 10), equals(1));
  expect(bsIO.indexOf(1, 1), equals(-1));

  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(2));
  bsIO.setLength(128);
  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(128));
  expect(bsIO.capacity, equals(128));

  bsIO.compact();
  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(128));
  expect(bsIO.capacity, equals(128));

  bsIO.ensureCapacity(1024 * 64);
  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(128));
  expect(bsIO.capacity, equals(1024 * 64));

  bsIO.compact();
  expect(bsIO.position, equals(2));
  expect(bsIO.length, equals(128));
  expect(bsIO.capacity, equals(128));

  expect(bsIO.toString(), startsWith('${bsIO.runtimeType}{'));
}
