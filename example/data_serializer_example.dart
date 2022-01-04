import 'package:data_serializer/data_serializer.dart';

void main() {
  // Dynamic bytes buffer with initial capacity of 16 bytes.
  var buffer = BytesBuffer(16);

  // Write a unsigned int of 32 bits:
  buffer.writeInt32(0x10203040);

  // Write a `String` encoded using UTF-8:
  buffer.writeString('Hello!');

  // Write a unsigned int of 64 bits:
  buffer.writeUint64(9223372036854775807);

  // Write a data block (prefixed by 4 bytes for he data length).
  var dataBlock = [110, 120, 130, 140, 150, 160].toUint8List();
  buffer.writeBlock32(dataBlock);

  // Write all bytes:
  buffer.writeAll([210, 220]);

  // The current length of the buffer, expanded automatically:
  print('length: ${buffer.length}');

  // Change the current position cursor to `0`:
  buffer.seek(0);

  // Read a 32 bits int:
  var n32 = buffer.readUint32();
  print('n32: 0x${n32.toHex32()}');

  // Reads a `String` decoding from UTF-8:
  var s = buffer.readString();
  print('s: $s');

  // Read a 64 bits int:
  var n64 = buffer.readUint64();
  print('n64: $n64');

  // The current buffer position:
  print('position: ${buffer.position}');

  // Read a data block:
  var dataBlock2 = buffer.readBlock32();
  print('dataBlock2: $dataBlock2');

  // The position after read the data block:
  print('position: ${buffer.position}');

  // The remaining bytes in the buffer:
  var tailBytes = buffer.readRemainingBytes();
  print('tailBytes: $tailBytes');
}

//////////////////////////////////
// OUTPUT:
//////////////////////////////////
// length: 34
// n32: 0x10203040
// s: Hello!
// n64: 9223372036854775807
// position: 22
// dataBlock2: [110, 120, 130, 140, 150, 160]
// position: 32
// tailBytes: [210, 220]
//
