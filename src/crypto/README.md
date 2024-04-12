# Crypto

## SHA256

```motoko
import SHA256 "mo:core/crypto/SHA256";
import { sum } = "mo:core/crypto/SHA256";
```

### Interface

```motoko
module {
  type SHA256 = {
    blockSize : () -> Nat;
    checkSum : () -> [Nat8];
    reset : () -> ();
    size : () -> Nat;
    sum : [Nat8] -> [Nat8];
    write : [Nat8] -> ();
  };
  SHA256 : () -> SHA256;
  sum : [Nat8] -> [Nat8];
};
```