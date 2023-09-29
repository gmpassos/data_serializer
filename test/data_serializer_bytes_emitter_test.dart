import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';

const integerRange = 1000000;

void main() {
  group('BytesEmitter', () {
    test('basic', () {
      var bs = BytesEmitter(data: [0, 1, 2, 3], description: "root magic");

      bs.write([1, 1, 1, 1], description: "part 0");

      bs.writeBytes(BytesEmitter(data: [2, 2], description: 'part 1'),
          description: "part 1.1");

      bs.writeAll([
        [3, 3, 3],
        [4, 4, 4, 4]
      ], description: 'part 2');

      bs.writeByte(101, description: "single byte");

      var s = bs.toString();
      print(s);

      expect(bs.output(),
          equals([0, 1, 2, 3, 1, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 4, 4, 101]));

      expect(
          s,
          equals(''
              '## root magic:\n'
              '[0, 1, 2, 3]\n'
              '  ## part 0:\n'
              '  [1, 1, 1, 1]\n'
              '  ## part 1.1:\n'
              '    ## part 1:\n'
              '    [2, 2]\n'
              '  ## part 2:\n'
              '  3 3 3 4 4 4 4\n'
              '  ## single byte:\n'
              '  101\n'
              ''));
    });

    test('blocks', () {
      var bs = BytesEmitter(data: [0, 1, 2, 3], description: "root magic");

      bs.writeLeb128Block([
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      ], description: "block 0");

      bs.writeBytesLeb128Block([
        BytesEmitter(data: [10, 20, 30, 40, 50], description: "block data")
      ], description: "block 1");

      var s = bs.toString();
      print(s);

      expect(
          bs.output(),
          equals([
            0,
            1,
            2,
            3,
            10,
            0,
            1,
            2,
            3,
            4,
            5,
            6,
            7,
            8,
            9,
            5,
            10,
            20,
            30,
            40,
            50
          ]));

      expect(
          s,
          equals(''
              '## root magic:\n'
              '[0, 1, 2, 3]\n'
              '  ## Bytes block length:\n'
              '  [10]\n'
              '  ## block 0:\n'
              '  0 1 2 3 4 5 6 7 8 9\n'
              '  ## Bytes block length:\n'
              '  [5]\n'
              '  ## block 1:\n'
              '    ## block data:\n'
              '    [10, 20, 30, 40, 50]\n'
              ''));
    });
  });
}
