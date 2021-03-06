## 1.0.7

- `ListIntDataExtension`:
  - Added `toInt8List`, `toUint16List`, `toInt16List`,
    `toUint32List`, `toInt32List`,`toUint64List`, `toInt64List`.
  - Added `asInt8List``asUint16List`, `asInt16List`,
    `asUint32List`, `asInt32List`, `asUint64List`, `asInt64List`.
- New `ListGenericExtension`:
  - `reversedList`, `copyTo`, `copy`, `asUnmodifiableView`, `reverseChunks`
- - `Uint8ListDataExtension`: added `toUint32List`.
- New `ByteDataExtension`, `Uint32ListDataExtension` and `Uint64ListDataExtension`.
- Improved tests.

## 1.0.6

- `DataSerializerPlatform`, and `Uint8ListDataExtension`:
  - `getInt16/32/64` and `getUint16/32/64`:
    - Added parameter `endian` to allow `Endian.little`.

## 1.0.5

- Added `BytesBuffer.indexOf`.

## 1.0.4

- `BytesBuffer.bytesTo` now returns `R`.

## 1.0.3

- Fix some documentation references.

## 1.0.2

- Organize extensions names.
- Clean code.
- Improve tests.

## 1.0.1

- Fix `BigInt` serialization.
- Improve tests.
- Improve documentation.

## 1.0.0

- Initial version.
- Moved some code from package `statistics`.
- Added support for browser/js.
- base_codecs: ^1.0.1
- collection: ^1.15.0
