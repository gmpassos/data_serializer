import 'dart:typed_data';

import 'int_codec.dart';

/// Bytes input and output interface.
abstract class BytesIO {
  /// The internal [ByteData] to write integers and doubles.
  IntCodec get bytesData;

  /// Returns the size of the internal bytes buffer ([Uint8List]).
  int get capacity;

  /// The length of bytes in this buffer.
  int get length;

  /// The current read/write cursor position in the bytes buffer.
  int get position;

  /// Returns `true` if `this` instance is empty.
  bool get isEmpty => length == 0;

  /// Returns `true` if `this` instance is NOT empty.
  bool get isNotEmpty => !isEmpty;

  /// The remaining bytes to read from [position] to the end of the buffer.
  int get remaining => length - position;

  /// Ensures that [capacity] can store the [needed] bytes.
  void ensureCapacity(int needed);

  /// Returns `true` if at the current [position] it's possible to read [length] bytes.
  bool canRead(int length) => position + length <= this.length;

  /// Checks if at the current [position] it's possible to read [length] bytes.
  void checkCanRead(int length) {
    if (!canRead(length)) {
      throw BytesBufferEOF();
    }
  }

  /// Changes the read/write cursor [position].
  int seek(int position);

  /// Increments [position] in [n] bytes.
  /// - This will affect real storage only on write or read.
  void incrementPosition(int n);

  /// Sets the [length] of this buffer. Increases internal bytes buffer [capacity] if needed.
  void setLength(int length);

  /// Resets this buffer. Sets the [length] and [position] to `0`.
  void reset();

  /// Compact the internal bytes [capacity] to [length].
  bool compact();

  /// Writes 1 byte. Increments [position] by 1.
  int writeByte(int b);

  /// Reads 1 byte. Increments [position] by 1.
  int readByte();

  /// Writes the `int` at [list] as bytes, respecting [offset] and [length] parameters.
  int write(List<int> list, [int offset = 0, int? length]);

  /// Reads an [Uint8List] of [length].
  Uint8List readBytes(int length);

  /// Writes the [bytes] into this buffer, respecting [offset] and [length] parameters.
  int writeBytes(Uint8List bs, [int offset = 0, int? length]);

  /// Writes all the [bytes] into this buffer.
  int writeAllBytes(Uint8List bytes);

  /// Writes all the `int` at [list] as bytes.
  int writeAll(List<int> list);

  /// Returns `this` instance as a [Uint8List]. Returns the internal `bytes`
  /// buffer if the [length] and [capacity] is the same, otherwise creates a
  /// copy with the exact [length].
  Uint8List asUint8List([int offset = 0, int? length]);

  /// Returns a copy of the internal bytes ([Uint8List]) of `this` instance.
  Uint8List toBytes([int offset = 0, int? length]);

  /// Calls the function [output] with the internal bytes of this instance.
  R bytesTo<R>(R Function(Uint8List bytes, int offset, int length) output,
      [int offset = 0, int? length]);

  /// Returns the index of [byte] inf [offset] and [length] range.
  int indexOf(int byte, [int offset = 0, int? length]);

  @override
  String toString();
}

class BytesBufferError extends Error {
  final String message;

  BytesBufferError(this.message);

  @override
  String toString() => "BytesBuffer error: $message";
}

class BytesBufferEOF extends BytesBufferError {
  BytesBufferEOF() : super('End of buffer');
}
