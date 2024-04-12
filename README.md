# Core Libraries for Motoko

The `core` library is a curated collection of libraries designed to enhance and
extend the functionality of the Motoko programming language. This repository
aims to provide robust and efficient tools that are essential for building
various applications in Motoko.

## Content Table

- [CBOR](#cbor-concise-binary-object-representation)
- [Crypto](#crypto)
  - [SHA256](#sha256)
- [Encoding](#encoding)
  - [Binary](#binary)
  - [Hex](#hex)

## Current Libraries

### **CBOR** (Concise Binary Object Representation)
  The CBOR library provides functions to encode and decode data in CBOR format,
  which is a compact data format designed for efficient data exchange.

```motoko
import CBOR "mo:core/cbor/CBOR";

let value = encode(#TextString("Hello world!"));
// "\6C\48\65\6C\6C\6F\20\77\6F\72\6C\64\21"
```

[Read more...](./src/cbor/README.md)

### Crypto

The Crypto library offers a collection of cryptographic functions and utilities,
enabling secure data handling and operations within Motoko applications.

[Read more...](./src/crypto/README.md)

#### SHA256

The SHA256 submodule provides a robust SHA-256 hashing function, crucial for
creating secure digital fingerprints of data.

```motoko
import SHA256 "mo:core/crypto/SHA256";

let hash = SHA256.sum(Blob.toArray(Text.encodeUtf8("Hello, world!")));
```

### Encoding

The Encoding library includes various encoding schemes necessary for data
manipulation and storage within Motoko applications.

[Read more...](./src/encoding/README.md)

#### Binary

The Binary submodule allows for straightforward encoding and decoding of binary
data, facilitating binary data handling in a variety of applications.

#### Hex

The Hex submodule provides functionalities to encode data into hexadecimal
format and decode it back, which is useful for debugging and logging.
