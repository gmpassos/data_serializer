@Tags(['bytes'])
import 'dart:typed_data';

import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

class FooWritable implements Writable {
  final int id;
  final String name;

  FooWritable(this.id, this.name);

  factory FooWritable.deserialize(BytesBuffer input) {
    var id = input.readInt32();
    var name = input.readString();
    return FooWritable(id, name);
  }

  @override
  Uint8List serialize() => Writable.doSerialize(this);

  @override
  int get serializeBufferLength => 4 + 4 + name.length;

  @override
  int writeTo(BytesBuffer out) {
    var sz = out.writeInt32(id);
    sz += out.writeString(name);
    return sz;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FooWritable &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

void main() {
  group('Writable', () {
    test('writeWritable/readWritable', () {
      var buffer = BytesBuffer();

      buffer.writeWritable(FooWritable(101, 'FOO'));

      buffer.writeWritables([
        FooWritable(10, 'Foo'),
        FooWritable(11, 'Bar'),
        FooWritable(12, 'Baz'),
      ]);

      [FooWritable(11, 'Bar1'), FooWritable(12, 'Baz2')].writeTo(buffer);

      buffer.seek(0);

      var o = buffer.readWritable((input) => FooWritable.deserialize(input));

      expect(o, equals(FooWritable(101, 'FOO')));

      var list =
          buffer.readWritables((input) => FooWritable.deserialize(input));

      expect(list.length, equals(3));

      expect(list[0], equals(FooWritable(10, 'Foo')));
      expect(list[1], equals(FooWritable(11, 'Bar')));
      expect(list[2], equals(FooWritable(12, 'Baz')));

      var list2 =
          buffer.readWritables((input) => FooWritable.deserialize(input));

      expect(list2.length, equals(2));

      expect(list2[0], equals(FooWritable(11, 'Bar1')));
      expect(list2[1], equals(FooWritable(12, 'Baz2')));
    });

    test('writeWritable/readWritable', () {
      var list = [
        FooWritable(10, 'Foo'),
        FooWritable(11, 'Bar'),
      ];

      var serial = list.serialize();

      var list2 =
          serial.readWritables((input) => FooWritable.deserialize(input));

      expect(list2, equals(list));
    });
  });
}
