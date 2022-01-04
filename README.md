# data_serializer

[![pub package](https://img.shields.io/pub/v/data_serializer.svg?logo=dart&logoColor=00b9fc)](https://pub.dev/packages/data_serializer)
[![Null Safety](https://img.shields.io/badge/null-safety-brightgreen)](https://dart.dev/null-safety)
[![Codecov](https://img.shields.io/codecov/c/github/gmpassos/data_serializer)](https://app.codecov.io/gh/gmpassos/data_serializer)
[![CI](https://img.shields.io/github/workflow/status/gmpassos/data_serializer/Dart%20CI/master?logo=github-actions&logoColor=white)](https://github.com/gmpassos/data_serializer/actions)
[![GitHub Tag](https://img.shields.io/github/v/tag/gmpassos/data_serializer?logo=git&logoColor=white)](https://github.com/gmpassos/data_serializer/releases)
[![New Commits](https://img.shields.io/github/commits-since/gmpassos/data_serializer/latest?logo=git&logoColor=white)](https://github.com/gmpassos/data_serializer/network)
[![Last Commits](https://img.shields.io/github/last-commit/gmpassos/data_serializer?logo=git&logoColor=white)](https://github.com/gmpassos/data_serializer/commits/master)
[![Pull Requests](https://img.shields.io/github/issues-pr/gmpassos/data_serializer?logo=github&logoColor=white)](https://github.com/gmpassos/data_serializer/pulls)
[![Code size](https://img.shields.io/github/languages/code-size/gmpassos/data_serializer?logo=github&logoColor=white)](https://github.com/gmpassos/data_serializer)
[![License](https://img.shields.io/github/license/gmpassos/data_serializer?logo=open-source-initiative&logoColor=green)](https://github.com/gmpassos/data_serializer/blob/master/LICENSE)

Portable Dart package to handle data serialization/deserialization efficiently,
including a dynamic `BytesBuffer` to read/write data.

## API Documentation

See the [API Documentation][api_doc] for a full list of functions, classes and extension.

[api_doc]: https://pub.dev/documentation/data_serializer/latest/

## Usage

### Numeric extension:

```dart
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
```

OUTPUT:

```text
length: 34
n32: 0x10203040
s: Hello!
n64: 9223372036854775807
position: 22
dataBlock2: [110, 120, 130, 140, 150, 160]
position: 32
tailBytes: [210, 220]
```

## Test Coverage

[![Codecov](https://img.shields.io/codecov/c/github/gmpassos/data_serializer)](https://app.codecov.io/gh/gmpassos/data_serializer)

This package aims to always have a high test coverage percentage, over 95%.
With that the package can be a reliable tool to support your important projects.

## Source

The official source code is [hosted @ GitHub][github_async_field]:

- https://github.com/gmpassos/data_serializer

[github_async_field]: https://github.com/gmpassos/data_serializer

# Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

# Contribution

Any help from the open-source community is always welcome and needed:

- Found an issue?
    - Please fill a bug report with details.
- Wish a feature?
    - Open a feature request with use cases.
- Are you using and liking the project?
    - Promote the project: create an article, do a post or make a donation.
- Are you a developer?
    - Fix a bug and send a pull request.
    - Implement a new feature.
    - Improve the Unit Tests.
- Have you already helped in any way?
    - **Many thanks from me, the contributors and everybody that uses this project!**

*If you donate 1 hour of your time, you can contribute a lot,
because others will do the same, just be part and start with your 1 hour.*

[tracker]: https://github.com/gmpassos/data_serializer/issues

# Author

Graciliano M. Passos: [gmpassos@GitHub][github].

[github]: https://github.com/gmpassos

## License

[Apache License - Version 2.0][apache_license]

[apache_license]: https://www.apache.org/licenses/LICENSE-2.0.txt
