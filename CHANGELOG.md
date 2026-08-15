## 1.2.3

Four correctness fixes. The first affects every platform; the other three are
web-only (`dart2js`/`dartdevc`), where an `int` is a JavaScript double and the
bitwise operators are 32-bit.

- `DataSerializerPlatformGeneric` (web):
  - **Fixed `shiftLeftInt` and `shiftRightInt` for non-negative operands.**
    Both took a plain `<<` / `>>` fast path, which is a 32-bit operation here:
    - `shiftLeftInt(127, 28)` returned `4026531840` instead of `34091302912`,
      and **any shift of 32 or more returned `0`**.
    - `shiftRightInt` truncated its operand before shifting, so
      `shiftRightInt(9007199254740991, 7)` returned `33554431` instead of
      `70368744177663`.
    - Both now fall back to [BigInt] outside the range the 32-bit operators
      handle exactly. Negative operands already did.
  - This corrupted LEB128 encoding and decoding on the web for magnitudes past
    2^28.

- `Leb128` / `BytesBufferLeb128Extension` (web):
  - **Fixed the value accumulator, which was truncating at 32 bits.** The
    decoders folded each 7-bit group in with `|=`, and `|` is also a 32-bit
    operation on the web, so any value past 2^32 lost its high bits. The groups
    occupy disjoint bit ranges, so `+` is equivalent and stays exact.
  - **Fixed signed decoding for magnitudes past ~2^49.** A LEB128 negative
    sign-extends into every bit below its terminating byte, so the *unsigned*
    form of a negative value is roughly `2^shift` — far larger than the value
    itself, and past the range a JavaScript double represents exactly, even
    when the value is comfortably inside it. The accumulator is now split at 49
    bits and the halves recombined with [BigInt] only when the value reaches
    that far. `DateTime.microsecondsSinceEpoch` sits in the affected range
    (about 2^50.6), so a pre-1970 timestamp decoded to the wrong number on the
    web while looking entirely ordinary.

- `BytesBufferLeb128Extension`:
  - **Fixed `readLeb128SignedInt`: it decoded almost every signed value
    incorrectly, on every platform.**
    - The sign of a LEB128 value lives in bit 6 of its *terminating* byte, but
      `lastByte` was assigned *after* the `break`, so it only ever held the
      previous continuation byte — or `0` for a single-byte value.
    - Every negative value came back positive: `-1` read as `127`, `-2` as
      `126`, `-64` as `64`.
    - Multi-byte positives were affected in the other direction: `64` encodes as
      `[0xC0, 0x00]`, and reading the sign from `0xC0` turned it into `-16320`;
      `1000` became `-15384`.
    - Values whose terminating and preceding bytes happened to agree on bit 6
      decoded correctly by luck, which is why the existing `-1000000` test
      passed throughout.
    - The static `Leb128.decodeSigned` was never affected — it reads the sign
      from the correct byte — so encoding was always right and only the
      `BytesBuffer` read path was wrong.

- Tests:
  - Added regression tests for `readLeb128SignedInt`: single-byte negatives,
    multi-byte positives, a wide range of magnitudes, interleaved signed and
    unsigned reads in one buffer, and a cross-check pinning the buffer reader to
    `Leb128.decodeSigned` so a fix on one side cannot be undone on the other.
  - Added range tests for signed and unsigned reads from 2^28 up to 2^53-1, and
    a case at microsecond-timestamp magnitudes, which is where the signed
    accumulator went wrong on the web.
  - Added direct tests for `shiftLeftInt` and `shiftRightInt` across and beyond
    the 32-bit boundary, checked against `BigInt`, for positive and negative
    operands.
  - Ranges are built by multiplication rather than `1 << 40`, since a shift is a
    32-bit operation on the web and such a literal is silently `0` there — a
    test written that way does not check what it appears to.

- CI:
  - `.github/workflows/dart.yml`: the Chrome job now collects and uploads
    coverage too. The two platforms run different implementations —
    `platform_generic.dart` is the web one and is never loaded on the VM — so a
    VM-only report left every web-only line permanently unmeasured, whatever
    the tests actually did. That is precisely where three of the four bugs
    above were hiding.
  - Added `data_serializer_edge_cases_test.dart` covering paths the suite had
    not reached: `BytesEmitter`'s rejection of data types it cannot represent,
    `BytesBufferError.toString`, the `BytesIO` transfer defaults, the
    `ByteDataExtension` length-range checks, `DataSerializerPlatform`'s 64-bit
    reads, `BitsBuffer.isAtPadding`/`toString`, `Writable`'s default buffer
    size, and `BytesFileIO`'s public constructor, transfer defaults and capacity
    growth.
  - Coverage: 98.1% → 99.6%.

## 1.2.2

- CI:
  - `.github/workflows/dart.yml`: updated GitHub Actions `actions/checkout` from v3 to v6 and `codecov/codecov-action` from v3 to v6.

- `BytesBuffer`:
  - Added `writeNullable` and `readNullable` methods to write/read nullable objects with a presence boolean flag.
  - Added `writeJSON` and `readJSON` methods to serialize/deserialize JSON-encodable objects as strings.
  - Reformatted constructor parameter formatting for consistency.
  - Minor formatting and whitespace fixes.

- Tests (`data_serializer_bytes_buffer_test_base.dart`):
  - Improved formatting and style consistency.
  - Added comprehensive tests for `writeNullable` / `readNullable` covering null, non-null, custom objects, and sequential values.
  - Added comprehensive tests for `writeJSON` / `readJSON` covering maps, lists, primitives, sequential values, and equivalence to direct JSON encode/decode.
  - Added more explicit expectations and improved test readability.

- `pubspec.yaml`:
  - Updated Dart SDK constraint to `>=3.10.0 <4.0.0`.
  - Updated dependencies:
    - `collection` to `^1.19.1`
    - `lints` to `^5.1.1`
    - `test` to `^1.31.1`
    - `coverage` to `^1.15.0`
    - `path` to `^1.9.1`

## 1.2.1

- Rollback to `collection 1.18.0` for Flutter SDK compatibility.

- collection: ^1.18.0

## 1.2.0

- Remove use of `UnmodifiableUint8ListView` for Dart 3.5.0 compatibility.

- sdk: '>=3.4.0 <4.0.0'

- collection: ^1.19.0
- test: ^1.25.8
- coverage: ^1.9.0

## 1.1.0

Dart `3.3.0` compatibility changes:

- `ListGenericExtension`:
  - Renamed getter `asUnmodifiableView` to method `asUnmodifiableListView`.

- `Uint8ListDataExtension`:
  - Removed getter `asUnmodifiableView` to allow use of `Uint8List.asUnmodifiableView`.
- `Uint32ListDataExtension`:
  - Removed getter `asUnmodifiableView` to allow use of `Uint32List.asUnmodifiableView`.
- `Uint64ListDataExtension`:
  - Removed getter `asUnmodifiableView` to allow use of `Uint64List.asUnmodifiableView`.

- sdk: '>=3.3.0 <4.0.0'

- lints: ^3.0.0
- test: ^1.25.2
- coverage: ^1.7.2
- path: ^1.9.0

## 1.0.12

- New `BitsBuffer`.
- `BytesBuffer`:
  - `writeWritables/readWritables`: new parameter option `leb128`.
  - Added `writeFloat64`, `writeAllFloat64`, `readFloat64` and `readAllFloat64`.
  - Added `writeFloat32`, `writeAllFloat32`, `readFloat32` and `readAllFloat32`.
  - Added `readTo` and `writeFrom`.

- test: ^1.24.8

## 1.0.11

- Added support to `Leb128`.
- New `BytesEmitter`.
- `DataSerializerPlatform`:
  - Added `supportsFullBitsShift`, `shiftRightInt` and `shiftLeftInt`.

- sdk: '>=3.0.0 <4.0.0'
- dependency_validator: ^3.2.3

## 1.0.10

- `data_serializer_io.dart`: `data_serializer.io`

## 1.0.9

- `BytesIO`:
  - Added `flush`, `close`, `isClosed` and `supportsClosing`.
- `BytesBuffer`:
  - Added `flush` and `close`.

## 1.0.8

- New `BytesIO`:
  - Implementations: `BytesFileIO` and `BytesUint8ListIO`.
- Added constructor `BytesBuffer.fromIO`.
- `DataSerializerPlatformGeneric`:
  - Fixed `_writeInt64` and `_readInt64` for JS/Browser platform.

- Dart CI:
  - Tests platforms: vm, exe, chrome. 

- sdk: '>=2.18.4 <4.0.0'
- collection: ^1.18.0
- lints: ^2.0.1
- test: ^1.24.3
- dependency_validator: ^3.2.2
- coverage: ^1.6.3

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
