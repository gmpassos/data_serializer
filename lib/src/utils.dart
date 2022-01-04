import "dart:convert";
import 'dart:typed_data';

import 'package:base_codecs/base_codecs.dart';

import 'bytes_buffer.dart';

/// An instance of the default implementation of the [HexCodec].
const hex = HexCodec();

/// A codec for encoding and decoding byte arrays to and from
/// hexadecimal strings.
class HexCodec extends Codec<Uint8List, String> {
  const HexCodec();

  @override
  Converter<Uint8List, String> get encoder => base16.encoder;

  @override
  Converter<String, Uint8List> get decoder => base16.decoder;
}

/// Interface for a class that can be written to a [BytesBuffer].
abstract class Writable {
  int writeTo(BytesBuffer out);

  int get serializeBufferLength => 512;

  static Uint8List doSerialize(Writable writable) {
    var buffer = BytesBuffer(writable.serializeBufferLength);
    writable.writeTo(buffer);
    return buffer.toUint8List();
  }

  Uint8List serialize() => doSerialize(this);
}
