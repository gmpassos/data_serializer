import 'package:data_serializer/data_serializer.dart';
import 'package:test/test.dart';
import 'dart:typed_data';

const integerRange = 1000000;

void main() {
  group('BytesEmitter', () {
    test('basic', () {
      var bs = BytesEmitter(data: [0, 1, 2, 3]);

      bs.write([1, 1, 1, 1]);

      bs.writeBytes(BytesEmitter(data: [2, 2]));

      bs.writeAll([
        [3, 3, 3],
        [4, 4, 10, 11]
      ]);

      bs.writeByte(101);

      bs.add(Uint8List.fromList([200, 210, 220, 230]));
      bs.add(BytesEmitter(data: [100, 110, 120, 130]));
      bs.add(50);
      bs.add(60);
      bs.add(70);

      var s = bs.toString();
      print(s);

      var sh = bs.toString(hex: true);
      print(sh);

      print(bs.output());

      expect(
          bs.output(),
          equals([
            0,
            1,
            2,
            3,
            1,
            1,
            1,
            1,
            2,
            2,
            3,
            3,
            3,
            4,
            4,
            10,
            11,
            101,
            200,
            210,
            220,
            230,
            100,
            110,
            120,
            130,
            50,
            60,
            70
          ]));

      expect(
          s,
          equals(''
              '[0 1 2 3]\n'
              '[1 1 1 1]\n'
              '  [2 2]\n'
              '[3 3 3]\n'
              '[4 4 10 11]\n'
              '[101 200 210 220 230]\n'
              '  [100 110 120 130]\n'
              '[50 60 70]\n'
              ''));

      expect(
          sh,
          equals(''
              '[00 01 02 03]\n'
              '[01 01 01 01]\n'
              '  [02 02]\n'
              '[03 03 03]\n'
              '[04 04 0a 0b]\n'
              '[65 c8 d2 dc e6]\n'
              '  [64 6e 78 82]\n'
              '[32 3c 46]\n'
              ''));
    });
    test('basic +description', () {
      var bs = BytesEmitter(data: [0, 1, 2, 3], description: "root magic");

      bs.write([1, 1, 1, 1], description: "part 0");

      bs.writeBytes(BytesEmitter(data: [2, 2], description: 'part 1'),
          description: "part 1.1");

      bs.writeAll([
        [3, 3, 3],
        [4, 4, 10, 11]
      ], description: 'part 2');

      bs.writeByte(101, description: "single byte");

      var s = bs.toString();
      print(s);

      var sh = bs.toString(hex: true);
      print(sh);

      expect(bs.output(),
          equals([0, 1, 2, 3, 1, 1, 1, 1, 2, 2, 3, 3, 3, 4, 4, 10, 11, 101]));

      expect(
          s,
          equals(''
              '## root magic:\n'
              '[0 1 2 3]\n'
              '  ## part 0:\n'
              '  [1 1 1 1]\n'
              '  ## part 1.1:\n'
              '    ## part 1:\n'
              '    [2 2]\n'
              '  ## part 2:\n'
              '  [3 3 3 4 4 10 11]\n'
              '  ## single byte:\n'
              '  [101]\n'
              ''));

      expect(
          sh,
          equals(''
              '## root magic:\n'
              '[00 01 02 03]\n'
              '  ## part 0:\n'
              '  [01 01 01 01]\n'
              '  ## part 1.1:\n'
              '    ## part 1:\n'
              '    [02 02]\n'
              '  ## part 2:\n'
              '  [03 03 03 04 04 0a 0b]\n'
              '  ## single byte:\n'
              '  [65]\n'
              ''));
    });

    test('blocks', () {
      var bs = BytesEmitter(data: [0, 1, 2, 3]);

      bs.writeLeb128Block([
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      ]);

      bs.writeBytesLeb128Block([
        BytesEmitter(data: [10, 20, 30, 40, 50])
      ]);

      bs.writeAllBytes([
        BytesEmitter(data: [1, 10, 100]),
        BytesEmitter(data: [2, 20, 200])
      ]);

      var s = bs.toString();
      print(s);

      var sh = bs.toString(hex: true);
      print(sh);

      print(bs.output());

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
            50,
            1,
            10,
            100,
            2,
            20,
            200
          ]));

      expect(
          s,
          equals(''
              '[0 1 2 3]\n'
              '  ## Bytes block length:\n'
              '  [10]\n'
              '[0 1 2 3 4 5 6 7 8 9]\n'
              '  ## Bytes block length:\n'
              '  [5]\n'
              '  [10 20 30 40 50]\n'
              '  [1 10 100]\n'
              '  [2 20 200]\n'
              ''));

      expect(
          sh,
          equals(''
              '[00 01 02 03]\n'
              '  ## Bytes block length:\n'
              '  [0a]\n'
              '[00 01 02 03 04 05 06 07 08 09]\n'
              '  ## Bytes block length:\n'
              '  [05]\n'
              '  [0a 14 1e 28 32]\n'
              '  [01 0a 64]\n'
              '  [02 14 c8]\n'
              ''));
    });

    test('blocks +description', () {
      var bs = BytesEmitter(data: [0, 1, 2, 3], description: "root magic");

      bs.writeLeb128Block([
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
      ], description: "block 0");

      bs.writeBytesLeb128Block([
        BytesEmitter(data: [10, 20, 30, 40, 50], description: "block data")
      ], description: "block 1");

      bs.writeAllBytes([
        BytesEmitter(data: [1, 10, 100], description: "block 1"),
        BytesEmitter(data: [2, 20, 200], description: "block 2")
      ], description: "blocks");

      var s = bs.toString();
      print(s);

      var sh = bs.toString(hex: true);
      print(sh);

      print(bs.output());

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
            50,
            1,
            10,
            100,
            2,
            20,
            200
          ]));

      expect(
          s,
          equals(''
              '## root magic:\n'
              '[0 1 2 3]\n'
              '  ## Bytes block length:\n'
              '  [10]\n'
              '  ## block 0:\n'
              '  [0 1 2 3 4 5 6 7 8 9]\n'
              '  ## Bytes block length:\n'
              '  [5]\n'
              '  ## block 1:\n'
              '    ## block data:\n'
              '    [10 20 30 40 50]\n'
              '  ## blocks:\n'
              '    ## block 1:\n'
              '    [1 10 100]\n'
              '    ## block 2:\n'
              '    [2 20 200]\n'
              ''));

      expect(
          sh,
          equals(''
              '## root magic:\n'
              '[00 01 02 03]\n'
              '  ## Bytes block length:\n'
              '  [0a]\n'
              '  ## block 0:\n'
              '  [00 01 02 03 04 05 06 07 08 09]\n'
              '  ## Bytes block length:\n'
              '  [05]\n'
              '  ## block 1:\n'
              '    ## block data:\n'
              '    [0a 14 1e 28 32]\n'
              '  ## blocks:\n'
              '    ## block 1:\n'
              '    [01 0a 64]\n'
              '    ## block 2:\n'
              '    [02 14 c8]\n'
              ''));
    });
  });
}
