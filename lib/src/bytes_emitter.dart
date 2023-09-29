import 'dart:typed_data';

import 'package:collection/collection.dart';

import 'extension.dart';
import 'leb128.dart';

/// An emitter for bytes where each [write] operation can have an optional
/// [description] that will be displayed by [toString]. The complete list of
/// bytes is emitted through [output]."
///
/// See [Leb128].
class BytesEmitter {
  /// Optional description of this bytes instance.
  final String? description;

  /// Creates a new [BytesEmitter].
  /// - [description]: optional description of this bytes instance.
  /// - [data]: optional initial data. See [add].
  BytesEmitter({this.description, Object? data}) {
    _addImpl(data);
  }

  final List<Object> _data = [];

  void _addImpl(Object? data) {
    if (data == null) return;

    if (data is List<int>) {
      _data.add(data.asUint8List);
    } else if (data is BytesEmitter) {
      _data.add(data);
    } else if (data is List<List<int>>) {
      for (var bs in data) {
        _data.addAll(bs.asUint8List);
      }
    } else if (data is List<BytesEmitter>) {
      _data.addAll(data);
    } else if (data is int) {
      _data.add(data);
    } else {
      throw StateError("Can't handle data type: ${data.runtimeType}");
    }
  }

  /// Adds [data] to this bytes instance.
  /// - [data] can be an [int], `List<int>`, [Uint8List] or a [BytesEmitter].
  void add(Object? data, {String? description}) {
    if (data == null) return;

    if (data is List<int>) {
      write(data, description: description);
    } else if (data is BytesEmitter) {
      writeBytes(data, description: description);
    } else if (data is int) {
      writeByte(data, description: description);
    } else {
      throw StateError("Can't handle data type: ${data.runtimeType}");
    }
  }

  /// Writes all [data] to this bytes instance.
  void writeAll(Iterable<List<int>> data, {String? description}) {
    if (description != null) {
      _data.add(BytesEmitter(data: data, description: description));
      return;
    }

    for (var e in data) {
      write(e);
    }
  }

  /// Writes [data] to this bytes instance.
  void write(List<int> data, {String? description}) {
    if (data.isEmpty) {
      return;
    }

    if (description != null) {
      _data.add(BytesEmitter(data: data, description: description));
      return;
    }

    if (data.length == 1) {
      _data.add(data[0]);
    } else {
      _data.add(data.asUint8List);
    }
  }

  /// Writes a byte [b] to this bytes instance.
  void writeByte(int b, {String? description}) {
    if (description != null) {
      _data.add(BytesEmitter(data: b, description: description));
      return;
    }

    _data.add(b);
  }

  /// Writes [bytes] to this bytes instance.
  void writeBytes(BytesEmitter bytes, {String? description}) {
    if (description != null) {
      _data.add(BytesEmitter(data: bytes, description: description));
      return;
    }

    _data.add(bytes);
  }

  /// Writes all the [bytes] to this bytes instance.
  void writeAllBytes(Iterable<BytesEmitter> bytes, {String? description}) {
    if (description != null) {
      _data.add(BytesEmitter(data: bytes, description: description));
      return;
    }

    for (var bs in bytes) {
      writeBytes(bs);
    }
  }

  /// Writes a [Leb128] [block] to this bytes instance.
  void writeLeb128Block(List<List<int>> block, {String? description}) {
    var blockSize = Leb128.encodeUnsigned(block.expandedLength);
    _data.add(BytesEmitter(data: blockSize, description: "Bytes block length"));

    if (description != null) {
      _data.add(BytesEmitter(data: block, description: description));
    } else {
      writeAll(block);
    }
  }

  /// Writes a [Leb128] [block] to this bytes instance.
  void writeBytesLeb128Block(List<BytesEmitter> block, {String? description}) {
    var blockSize = Leb128.encodeUnsigned(block.expandedLength);
    _data.add(BytesEmitter(data: blockSize, description: "Bytes block length"));

    if (description != null) {
      _data.add(BytesEmitter(data: block, description: description));
    } else {
      writeAllBytes(block);
    }
  }

  /// The length of bytes to [output].
  int get length => _data.map((e) {
        if (e is Uint8List) {
          return e.length;
        } else if (e is BytesEmitter) {
          return e.length;
        } else if (e is int) {
          return 1;
        } else {
          throw StateError("Can't handle type: $e");
        }
      }).sum;

  /// Outputs/emits all the written bytes.
  Uint8List output() {
    final length = this.length;

    var all = Uint8List(length);
    var offset = 0;

    for (var e in _data) {
      Uint8List bs;

      if (e is int) {
        all[offset] = e;
        ++offset;
      } else {
        if (e is BytesEmitter) {
          bs = e.output();
        } else if (e is Uint8List) {
          bs = e;
        } else {
          throw StateError("Can't handle type: $e");
        }

        var lng = bs.length;
        all.setRange(offset, offset + lng, bs);

        offset += lng;
      }
    }

    return all;
  }

  static final _lineTail = RegExp(r'(?:[ \t]*\n)+');

  /// Show bytes [description] if defined.
  @override
  String toString({String indent = '', bool hex = false}) {
    var s = StringBuffer();

    for (var e in _data) {
      if (e is BytesEmitter) {
        s.write(e.toString(indent: '  ', hex: hex));
      } else if (e is List<int>) {
        if (hex) {
          var h = e.map((e) => e.toHex()).join(' ');
          s.write('[$h]\n');
        } else {
          s.write('$e\n');
        }
      } else if (e is int) {
        if (hex) {
          var h = e.toHex();
          s.write('[$h] ');
        } else {
          s.write('$e ');
        }
      } else {
        var n = hex ? e : e;
        s.write('$n ');
      }
    }

    var lines = s.toString().split('\n').map((l) => '$indent$l');

    var allLines = lines.join('\n').replaceAll(_lineTail, '\n').trimRight();

    final description = this.description;
    if (description != null && description.isNotEmpty) {
      return '$indent## $description:\n$allLines\n';
    } else {
      return '$allLines\n';
    }
  }
}

extension _IntExtension on int {
  String toHex() => toRadixString(16).padLeft(2, '0');
}

extension IterableBytesEmitterExtension on Iterable<BytesEmitter> {
  int get expandedLength => map((e) => e.length).sum;
}
