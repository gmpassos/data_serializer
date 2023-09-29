import 'package:data_serializer/data_serializer_io.dart';
import 'package:test/test.dart';

const integerRange = 1000000;

void main() {
  group('Leb128', () {
    test('encodeUnsigned/decodeUnsigned', () {
      for (var i = -integerRange; i < integerRange; ++i) {
        var bs = Leb128.encodeUnsigned(i);
        var n = Leb128.decodeUnsigned(bs);
        expect(n, equals(i.abs()));
      }
    });

    test('encodeSigned/decodeSigned', () {
      for (var i = -integerRange; i < integerRange; ++i) {
        var bs = Leb128.encodeSigned(i);
        var n = Leb128.decodeSigned(bs);
        expect(n, equals(i));
      }
    });

    test('encodeVarInt7/decodeVarInt7', () {
      for (var i = -64; i <= 63; ++i) {
        var b = Leb128.encodeVarInt7(i);
        var n = Leb128.decodeVarInt7(b);
        expect(n, equals(i));
      }

      expect(() => Leb128.encodeVarInt7(-65), throwsArgumentError);
      expect(() => Leb128.encodeVarInt7(64), throwsArgumentError);
    });

    test('encodeVarUInt7/decodeVarUInt7', () {
      for (var i = 0; i <= 127; ++i) {
        var b = Leb128.encodeVarUInt7(i);
        var n = Leb128.decodeVarUInt7(b);
        expect(n, equals(i));
      }

      expect(() => Leb128.encodeVarUInt7(-1), throwsArgumentError);
      expect(() => Leb128.encodeVarUInt7(128), throwsArgumentError);
    });
  });
}
