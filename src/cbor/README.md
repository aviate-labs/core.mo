# CBOR (Concise Binary Object Representation)

The CBOR library provides functions to encode and decode data in CBOR format,
which is a compact data format designed for efficient data exchange.

```motoko
import CBOR "mo:core/cbor/CBOR";
```

## Interface

```motoko
module {
  type Value = {
    #Array : [Value];
    #BigNumber : { #Negative : Int; #Positive : Nat };
    #Bool : Bool;
    #Break;
    #ByteString : Blob;
    #Float : FloatingPoint;
    #Infinity : Infinity;
    #Map : [(Value, Value)];
    #NaN : NaN;
    #NegativeInteger : Int;
    #Null;
    #Simple : Nat8;
    #Tag : { tag : Nat64; value : Value };
    #TextString : Text;
    #Undefined;
    #UnsignedInteger : Nat64;
  };
  decode : Blob -> Result<Value, Text>;
  encode : Value -> Blob;
};
```
