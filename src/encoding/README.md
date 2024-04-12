# Encoding

## Binary

```motoko
import { BigEndian; LittleEndian } = "mo:core/encoding/Binary";
```

### Interface

```motoko
module {
  BigEndian : {
    fromNat16 : Nat16 -> [Nat8];
    fromNat32 : Nat32 -> [Nat8];
    fromNat64 : Nat64 -> [Nat8];
    toNat16 : [Nat8] -> Nat16;
    toNat32 : [Nat8] -> Nat32;
    toNat64 : [Nat8] -> Nat64;
  };
  LittleEndian : {
    fromNat16 : Nat16 -> [Nat8];
    fromNat32 : Nat32 -> [Nat8];
    fromNat64 : Nat64 -> [Nat8];
    toNat16 : [Nat8] -> Nat16;
    toNat32 : [Nat8] -> Nat32;
    toNat64 : [Nat8] -> Nat64;
  };
};
```

## Hex

```motoko
import Hex "mo:core/encoding/Hex";
import { decode; encode } = "mo:core/encoding/Hex";
```

### Interface

```motoko
module {
  type Hex = Text;
  decode : Hex -> Result<[Nat8], Text>;
  decodeChar : Char -> Result<Nat8, Text>;
  encode : [Nat8] -> Hex;
  encodeByte : Nat8 -> Hex;
  equal : (Hex, Hex) -> Bool;
  hash : Hex -> Hash;
  valid : Hex -> Bool;
};
```
