//// The Concise Binary Object Representation (CBOR) data format.
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Nat8 "mo:base/Nat8";
import Nat64 "mo:base/Nat64";
import Result "mo:base/Result";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Text "mo:base/Text";

import { shiftLeft } = "mo:⛔";

import { LittleEndian; BigEndian } "../encoding/Binary";
import Float "../../internal/Float";

module {

  public type Value = {
    /// An unsigned integer in the range 0..2^(64)-1 inclusive. The value
    /// of the encoded item is the argument itself.  For example, the
    /// integer 10 is denoted as the one byte 0b000_01010 (major type 0,
    /// additional information 10). The integer 500 would be 0b000_11001
    /// (major type 0, additional information 25) followed by the two
    /// bytes 0x01f4, which is 500 in decimal.
    #UnsignedInteger : Nat64;
    /// A negative integer in the range -2^(64)..-1 inclusive. The value
    /// of the item is -1 minus the argument. For example, the integer
    /// -500 would be 0b001_11001 (major type 1, additional information
    /// 25) followed by the two bytes 0x01f3, which is 499 in decimal.
    #NegativeInteger : Int;
    /// A byte string. The number of bytes in the string is equal to the
    /// argument. For example, a byte string whose length is 5 would have
    /// an initial byte of 0b010_00101 (major type 2, additional
    /// information 5 for the length), followed by 5 bytes of binary
    /// content. A byte string whose length is 500 would have 3 initial
    /// bytes of 0b010_11001 (major type 2, additional information 25 to
    /// indicate a two-byte length) followed by the two bytes 0x01f4 for a
    /// length of 500, followed by 500 bytes of binary content.
    #ByteString : Blob;
    /// A text string encoded as UTF-8 [RFC3629]. The number
    /// of bytes in the string is equal to the argument. A string
    /// containing an invalid UTF-8 sequence is well-formed but invalid.
    /// This type is provided for systems that need to
    /// interpret or display human-readable text, and allows the
    /// differentiation between unstructured bytes and text that has a
    /// specified repertoire (that of Unicode) and encoding (UTF-8). In
    /// contrast to formats such as JSON, the Unicode characters in this
    /// type are never escaped. Thus, a newline character (U+000A) is
    /// always represented in a string as the byte 0x0a, and never as the
    /// bytes 0x5c6e (the characters "\" and "n") nor as 0x5c7530303061
    /// (the characters "\", "u", "0", "0", "0", and "a").
    #TextString : Text;
    /// An array of data items.  In other formats, arrays are also called
    /// lists, sequences, or tuples (a "CBOR sequence" is something
    /// slightly different, though [RFC8742]). The argument is the number
    /// of data items in the array.  Items in an array do not need to all
    /// be of the same type.  For example, an array that contains 10 items
    /// of any type would have an initial byte of 0b100_01010 (major type
    /// 4, additional information 10 for the length) followed by the 10
    /// remaining items.
    #Array : [Value];
    /// A map of pairs of data items.  Maps are also called tables,
    /// dictionaries, hashes, or objects (in JSON). A map is comprised of
    /// pairs of data items, each pair consisting of a key that is
    /// immediately followed by a value. The argument is the number of
    /// _pairs_ of data items in the map. For example, a map that
    /// contains 9 pairs would have an initial byte of 0b101_01001 (major
    /// type 5, additional information 9 for the number of pairs) followed
    /// by the 18 remaining items. The first item is the first key, the
    /// second item is the first value, the third item is the second key,
    /// and so on.  Because items in a map come in pairs, their total
    /// number is always even: a map that contains an odd number of items
    /// (no value data present after the last key data item) is not well-
    /// formed. A map that has duplicate keys may be well-formed, but it
    /// is not valid, and thus it causes indeterminate decoding.
    #Map : [(Value, Value)];
    /// A tagged data item ("tag") whose tag number, an integer in the
    /// range 0..2^(64)-1 inclusive, is the argument and whose enclosed
    /// data item (_tag content_) is the single encoded data item that
    /// follows the head.
    #Tag : {
      tag : Nat64;
      value : Value;
    };
    // Tag numbers 2 and 3 extend the generic data model with "bignums"
    // representing arbitrarily sized integers.
    #BigNumber : {
      // A positive bignum.
      #Positive : Nat;
      // A negative bignum.
      #Negative : Int;
    };
    // A boolean value.
    #Bool : Bool;
    // The "null" value.
    #Null;
    // The "undefined" value.
    #Undefined;
    // A simple value is a single byte that does not have any content.
    #Simple : Nat8;
    // Floating-point number.
    #Float : Float.FloatingPoint;
    // Positive and negative infinity.
    #Infinity : Float.Infinity;
    // Not a number.
    #NaN : Float.NaN;
    // Break is used to indicate the end of an indefinite-length array or map.
    #Break;
  };

  public func decode(b : Blob) : Result.Result<Value, Text> = _decode(b.vals());

  private func _decode(bytes : Iter.Iter<Nat8>) : Result.Result<Value, Text> {
    let initialByte = switch (bytes.next()) {
      case (?initialByte) initialByte;
      case (null) return #err("empty blob");
    };

    let (majorTypeNumber, additionalInformationNumber) = bit3n5(initialByte);
    let majorType = switch (getMajorType(majorTypeNumber)) {
      case (#ok(majorType)) majorType;
      case (#err) return #err("invalid major type");
    };
    let (additionalInformation) = switch (getAdditionalValue(additionalInformationNumber)) {
      case (#ok(additionalInformation)) additionalInformation;
      case (#err(msg)) return #err(msg);
    };

    switch (majorType) {
      case (#UnsignedInteger) switch (additionalInformation) {
        case (#Value(value)) #ok(#UnsignedInteger(Nat64.fromNat(Nat8.toNat(value))));
        case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
          case (#ok(bytes)) #ok(#UnsignedInteger(Nat64.fromNat(BigEndian.toNat(bytes))));
          case (#err(msg)) #err(msg);
        };
        case (#Indefinite) #err("not supported: inf for uint");
      };

      case (#NegativeInteger) switch (additionalInformation) {
        case (#Value(value)) #ok(#NegativeInteger(- 1 - Nat8.toNat(value)));
        case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
          case (#ok(bytes)) #ok(#NegativeInteger(- 1 - BigEndian.toNat(bytes)));
          case (#err(msg)) #err(msg);
        };
        case (#Indefinite) #err("not supported: inf for int");
      };

      case (#ByteString(blob)) {
        let n : Nat = switch (additionalInformation) {
          case (#Value(value)) Nat8.toNat(value);
          case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
            case (#ok(bytes)) BigEndian.toNat(bytes);
            case (#err(msg)) return #err(msg);
          };
          case (#Indefinite) {
            let buffer = Buffer.Buffer<Nat8>(8);
            label l loop {
              let byte = switch (bytes.next()) {
                case (?byte) byte;
                case (null) return #err("unexpected end of blob");
              };

              if (byte == 0xFF) break l;

              // Load block.
              let (majorTypeNumber, additionalInformationNumber) = bit3n5(byte);
              switch (getMajorType(majorTypeNumber)) {
                case (#ok(majorType)) if (majorType != #ByteString) return #err("invalid major type");
                case (#err) return #err("invalid major type");
              };
              for (_ in Iter.range(0, Nat8.toNat(additionalInformationNumber) - 1)) {
                buffer.add(
                  switch (bytes.next()) {
                    case (?byte) byte;
                    case (null) return #err("unexpected end of blob");
                  }
                );
              };
            };
            return #ok(#ByteString(Blob.fromArray(Buffer.toArray(buffer))));
          };
        };
        let buffer = Buffer.Buffer<Nat8>(n);
        for (_ in Iter.range(0, n - 1)) {
          buffer.add(
            switch (bytes.next()) {
              case (?byte) byte;
              case (null) return #err("unexpected end of blob");
            }
          );
        };
        #ok(#ByteString(Blob.fromArray(Buffer.toArray(buffer))));
      };

      case (#TextString) {
        let n : Nat = switch (additionalInformation) {
          case (#Value(value)) Nat8.toNat(value);
          case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
            case (#ok(bytes)) BigEndian.toNat(bytes);
            case (#err(msg)) return #err(msg);
          };
          case (#Indefinite) {
            let buffer = Buffer.Buffer<Nat8>(8);
            label l loop {
              let byte = switch (bytes.next()) {
                case (?byte) byte;
                case (null) return #err("unexpected end of blob");
              };

              if (byte == 0xFF) break l;

              // Load block.
              let (majorTypeNumber, additionalInformationNumber) = bit3n5(byte);
              switch (getMajorType(majorTypeNumber)) {
                case (#ok(majorType)) if (majorType != #TextString) return #err("invalid major type");
                case (#err) return #err("invalid major type");
              };
              for (_ in Iter.range(0, Nat8.toNat(additionalInformationNumber) - 1)) {
                buffer.add(
                  switch (bytes.next()) {
                    case (?byte) byte;
                    case (null) return #err("unexpected end of blob");
                  }
                );
              };
            };
            let text : Text = switch (Text.decodeUtf8(Blob.fromArray(Buffer.toArray(buffer)))) {
              case (?text) text;
              case (null) return #err("invalid utf8");
            };
            return #ok(#TextString(text));
          };
        };
        var eod = false;
        let array = Array.tabulate(
          n,
          func(_ : Nat) : Nat8 {
            switch (bytes.next()) {
              case (?byte) byte;
              case (null) { eod := true; 0 };
            };
          },
        );
        if (eod) return #err("unexpected end of blob");
        let text : Text = switch (Text.decodeUtf8(Blob.fromArray(array))) {
          case (?text) text;
          case (null) return #err("invalid utf8");
        };
        return #ok(#TextString(text));
      };

      case (#Array) {
        let n : Nat = switch (additionalInformation) {
          case (#Value(value)) Nat8.toNat(value);
          case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
            case (#ok(bytes)) BigEndian.toNat(bytes);
            case (#err(msg)) return #err(msg);
          };
          case (#Indefinite) {
            let buffer = Buffer.Buffer<Value>(8);
            label l loop {
              buffer.add(
                switch (_decode(bytes)) {
                  case (#ok(#Break)) break l;
                  case (#ok(v)) v;
                  case (#err(msg)) return #err(msg);
                }
              );
            };
            return #ok(#Array(Buffer.toArray(buffer)));
          };
        };
        let buffer = Buffer.Buffer<Value>(n);
        for (_ in Iter.range(0, n - 1)) {
          buffer.add(
            switch (_decode(bytes)) {
              case (#ok(v)) v;
              case (#err(msg)) return #err(msg);
            }
          );
        };
        #ok(#Array(Buffer.toArray(buffer)));
      };

      case (#Map) {
        let n : Nat = switch (additionalInformation) {
          case (#Value(value)) Nat8.toNat(value);
          case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
            case (#ok(bytes)) BigEndian.toNat(bytes);
            case (#err(msg)) return #err(msg);
          };
          case (#Indefinite) {
            let buffer = Buffer.Buffer<(Value, Value)>(8);
            label l loop {
              let key : Value = switch (_decode(bytes)) {
                case (#ok(#Break)) break l;
                case (#ok(v)) v;
                case (#err(e)) return #err(e);
              };
              let value : Value = switch (_decode(bytes)) {
                case (#ok(v)) v;
                case (#err(e)) return #err(e);
              };
              buffer.add(key, value);
            };
            return #ok(#Map(Buffer.toArray(buffer)));
          };
        };
        let buffer = Buffer.Buffer<(Value, Value)>(n);
        for (_ in Iter.range(0, n - 1)) {
          let key : Value = switch (_decode(bytes)) {
            case (#ok(v)) v;
            case (#err(e)) return #err(e);
          };
          let value : Value = switch (_decode(bytes)) {
            case (#ok(v)) v;
            case (#err(e)) return #err(e);
          };
          buffer.add(key, value);
        };
        #ok(#Map(Buffer.toArray(buffer)));
      };

      case (#Tag) {
        let n : Nat64 = switch (additionalInformation) {
          case (#Value(value)) Nat64.fromNat(Nat8.toNat(value));
          case (#ByteSize(size)) switch (getAdditionalBytes(bytes, size)) {
            case (#ok(bytes)) Nat64.fromNat(BigEndian.toNat(bytes));
            case (#err(msg)) return #err(msg);
          };
          case (#Indefinite) return #err("invalid tag");
        };
        let value : Value = switch (_decode(bytes)) {
          case (#ok(v)) v;
          case (#err(msg)) return #err(msg);
        };
        switch (n) {
          // Nat
          case 2 switch (value) {
            case (#ByteString(bytes)) {
              var n = 0;
              for (byte in bytes.vals()) {
                n := shiftLeft(n, 8);
                n += Nat8.toNat(byte);
              };
              return #ok(#BigNumber(#Positive(n)));
            };
            case (_) return #err("invalid tag");
          };
          // Int
          case 3 switch (value) {
            case (#ByteString(bytes)) {
              var n = 0;
              for (byte in bytes.vals()) {
                n := shiftLeft(n, 8);
                n += Nat8.toNat(byte);
              };
              return #ok(#BigNumber(#Negative(-1 - n)));
            };
            case (_) return #err("invalid tag");
          };
          case _ #ok(#Tag({ tag = n; value = value }));
        };
      };

      case (#SimpleOrFloat) {
        if (additionalInformationNumber == 0xff) return #ok(#Break);
        if (additionalInformationNumber <= 23) return #ok(
          switch (additionalInformationNumber) {
            case (20) #Bool(false);
            case (21) #Bool(true);
            case (22) #Null;
            case (23) #Undefined;
            case (a) #Simple(a);
          }
        );
        if (additionalInformationNumber == 24) {
          let byte : Nat8 = switch (bytes.next()) {
            case (?byte) byte;
            case (null) return #err("unexpected end of blob");
          };
          if (byte < 32) return #err("invalid additional byte");
          return #ok(#Simple(byte));
        };
        let n = switch (additionalInformationNumber) {
          case (25) 2; // Half, 16 bit
          case (26) 4; // Single, 32 bit
          case (27) 8; // Double, 64 bit
          case (31) return #ok(#Break);
          case (_) return #err("invalid additional byte");
        };
        let buffer = Buffer.Buffer<Nat8>(n);
        for (_ in Iter.range(0, n - 1)) {
          buffer.add(
            switch (bytes.next()) {
              case (?byte) byte;
              case (null) return #err("unexpected end of blob");
            }
          );
        };
        let raw = Buffer.toArray(buffer);
        switch (Float.decode(raw)) {
          case (#ok(#Float(f))) #ok(#Float(f));
          case (#ok(#Infinity(i))) #ok(#Infinity(i));
          case (#ok(#NaN(n))) #ok(#NaN(n));
          case (_) #err("invalid float");
        };
      };
    };
  };

  public func encode(v : Value) : Blob {
    let buffer = Buffer.Buffer<Nat8>(8);
    _encode(v, buffer);
    Blob.fromArray(Buffer.toArray(buffer));
  };

  private func _encode(v : Value, buffer : Buffer.Buffer<Nat8>) {
    switch (v) {
      case (#UnsignedInteger(n)) {
        if (n <= 23) {
          buffer.add(nat5b3(0, Nat8.fromNat(Nat64.toNat(n))));
        } else {
          let bytes = fillZero(LittleEndian.fromNat(Nat64.toNat(n)));
          let additionalInformation = switch (bytes.size()) {
            case (1) 24;
            case (2) 25;
            case (3 or 4) 26;
            case (_) 27;
          };
          buffer.add(nat5b3(0, Nat8.fromNat(additionalInformation)));
          let s = bytes.size() - 1 : Nat;
          for (i in Iter.range(0, s)) {
            buffer.add(bytes.get(s - i));
          };
        };
      };

      case (#NegativeInteger(i)) {
        let n = Int.abs(i + 1);
        if (n <= 23) {
          buffer.add(nat5b3(1, Nat8.fromNat(n)));
        } else {
          let bytes = fillZero(LittleEndian.fromNat(n));
          let additionalInformation = switch (bytes.size()) {
            case (1) 24;
            case (2) 25;
            case (3 or 4) 26;
            case (_) 27;
          };
          buffer.add(nat5b3(1, Nat8.fromNat(additionalInformation)));
          let s = bytes.size() - 1 : Nat;
          for (i in Iter.range(0, s)) {
            buffer.add(bytes.get(s - i));
          };
        };
      };

      case (#ByteString(s)) {
        let l = s.size();
        if (l <= 23) {
          buffer.add(nat5b3(2, Nat8.fromIntWrap(l)));
        } else {
          if (l < 0xff) {
            buffer.add(nat5b3(2, 24));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(2, 25));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(2, 26));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else {
            buffer.add(nat5b3(2, 27));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 56)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 48)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 40)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 32)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          };
        };
        for (c in s.vals()) buffer.add(c);
      };

      case (#TextString(s)) {
        let b = Text.encodeUtf8(s);
        let l = b.size();
        if (l <= 23) {
          buffer.add(nat5b3(3, Nat8.fromIntWrap(l)));
        } else {
          if (l < 0xff) {
            buffer.add(nat5b3(3, 24));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(3, 25));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(3, 26));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else {
            buffer.add(nat5b3(3, 27));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 56)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 48)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 40)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 32)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          };
        };
        for (c in b.vals()) buffer.add(c);
      };

      case (#Array(a)) {
        let l = a.size();
        if (l <= 23) {
          buffer.add(nat5b3(4, Nat8.fromNat(l)));
        } else {
          if (l < 0xff) {
            buffer.add(nat5b3(4, 24));
            buffer.add(Nat8.fromNat(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(4, 25));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(4, 26));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else {
            buffer.add(nat5b3(4, 27));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 56)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 48)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 40)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 32)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          };
        };
        for (v in a.vals()) _encode(v, buffer);
      };

      case (#Map(m)) {
        let l = m.size();
        if (l <= 23) {
          buffer.add(nat5b3(5, Nat8.fromIntWrap(l)));
        } else {
          if (l < 0xff) {
            buffer.add(nat5b3(5, 24));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(5, 25));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else if (l < 0xffff) {
            buffer.add(nat5b3(5, 26));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          } else {
            buffer.add(nat5b3(5, 27));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 56)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 48)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 40)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 32)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(l, 8)));
            buffer.add(Nat8.fromIntWrap(l));
          };
        };
        for ((k, v) in m.vals()) {
          _encode(k, buffer);
          _encode(v, buffer);
        };
      };

      case (#Tag({ tag; value })) {
        let t = Nat64.toNat(tag);
        if (tag <= 23) {
          buffer.add(nat5b3(6, Nat8.fromIntWrap(t)));
        } else {
          if (tag < 0xff) {
            buffer.add(nat5b3(6, 24));
            buffer.add(Nat8.fromIntWrap(t));
          } else if (tag < 0xffff) {
            buffer.add(nat5b3(6, 25));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 8)));
            buffer.add(Nat8.fromIntWrap(t));
          } else if (tag < 0xffff) {
            buffer.add(nat5b3(6, 26));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 8)));
            buffer.add(Nat8.fromIntWrap(t));
          } else {
            buffer.add(nat5b3(6, 27));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 56)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 48)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 40)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 32)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 24)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 16)));
            buffer.add(Nat8.fromIntWrap(shiftLeft(t, 8)));
            buffer.add(Nat8.fromIntWrap(t));
          };
        };
        _encode(value, buffer);
      };

      case (#BigNumber(#Positive(n))) {
        let bytes = fillZero(LittleEndian.fromNat(n));
        buffer.add(nat5b3(6, 2));
        buffer.add(nat5b3(2, Nat8.fromNat(bytes.size())));
        let s = bytes.size() - 1 : Nat;
        for (i in Iter.range(0, s)) {
          buffer.add(bytes.get(s - i));
        };
      };

      case (#BigNumber(#Negative(i))) {
        let n = Int.abs(i + 1);
        let bytes = fillZero(LittleEndian.fromNat(n));
        buffer.add(nat5b3(6, 3));
        buffer.add(nat5b3(2, Nat8.fromNat(bytes.size())));
        let s = bytes.size() - 1 : Nat;
        for (i in Iter.range(0, s)) {
          buffer.add(bytes.get(s - i));
        };
      };

      case (#Bool(b)) buffer.add(nat5b3(7, Nat8.fromNat(if (b) 21 else 20)));

      case (#Null) buffer.add(nat5b3(7, 22));

      case (#Undefined) buffer.add(nat5b3(7, 23));

      case (#Simple(v)) {
        if (v <= 23) {
          buffer.add(nat5b3(7, v));
        } else {
          buffer.add(nat5b3(7, 24));
          buffer.add(v);
        };
      };

      case (#Float(f)) {
        let bytes = Float.encode(f);
        let additionalInformation = switch (bytes.size()) {
          case (2) 25;
          case (4) 26;
          case (8) 27;
          case (_) {
            assert (false);
            loop {};
          };
        };
        buffer.add(nat5b3(7, Nat8.fromNat(additionalInformation)));
        let s = bytes.size() - 1 : Nat;
        for (i in Iter.range(0, s)) {
          buffer.add(bytes.get(s - i));
        };
      };

      case (#Infinity({ precision; sign })) {
        let exp : Int16 = switch (precision) {
          case (#half) 0x10;
          case (#single) 0x80;
          case (#double) 0x400;
        };
        _encode(#Float({ precision; mantissa = 0; exponent = ?exp; sign }), buffer);
      };

      case (#NaN({ precision })) {
        let (mantissa, exp) : (Nat64, Int16) = switch (precision) {
          case (#half) (0x200, 0x10);
          case (#single) (0x400000, 0x80);
          case (#double) (0x8000000000000, 0x400);
        };
        _encode(#Float({ precision; mantissa; exponent = ?exp; sign = false }), buffer);
      };

      case (#Break) {
        buffer.add(0xFF);
      };
    };
  };

  // The initial byte of each encoded data item contains both information about
  // the major type (the high-order 3 bits) and additional information (the
  // low-order 5 bits). With a few exceptions, the additional information's
  // value describes how to load an unsigned integer "argument".
  private func bit3n5(b : Nat8) : (majorType : Nat8, additionalInformation : Nat8) = (b >> 5, b & 0x1F);
  
  private func nat5b3(majorType : Nat8, additionalInformation : Nat8) : (b : Nat8) = (majorType << 5) + additionalInformation;

  private func fillZero(n : [Nat8]) : [Nat8] {
    switch (n.size()) {
      case (3) [n[0], n[1], n[2], 0];
      case (5) [n[0], n[1], n[2], n[3], n[4], 0, 0, 0];
      case (6) [n[0], n[1], n[2], n[3], n[4], n[5], 0, 0];
      case (7) [n[0], n[1], n[2], n[3], n[4], n[5], n[6], 0];
      case _ n;
    };
  };

  private type MajorType = {
    #UnsignedInteger;
    #NegativeInteger;
    #ByteString;
    #TextString;
    #Array;
    #Map;
    #Tag;
    #SimpleOrFloat;
  };

  private func getMajorType(b : Nat8) : Result.Result<MajorType, ()> = switch (b) {
    case (0) #ok(#UnsignedInteger);
    case (1) #ok(#NegativeInteger);
    case (2) #ok(#ByteString);
    case (3) #ok(#TextString);
    case (4) #ok(#Array);
    case (5) #ok(#Map);
    case (6) #ok(#Tag);
    case (7) #ok(#SimpleOrFloat);
    case (_) #err;
  };

  private type AdditionalInformation = {
    /// The argument's value is the value of the additional information.
    #Value : (value : Nat8);
    /// The argument's value is held in the following 1,
    /// 2, 4, or 8 bytes, respectively, in network byte order.  For major
    /// type 7 and additional information value 25, 26, 27, these bytes
    /// are not used as an integer argument, but as a floating-point value.
    #ByteSize : (size : Nat8);
    /// No argument value is derived.  If the major type is 0, 1, or 6,
    /// the encoded item is not well-formed.  For major types 2 to 5, the
    /// item's length is indefinite, and for major type 7, the byte does
    /// not constitute a data item at all but terminates an indefinite-
    /// length item.
    #Indefinite;
  };

  private func getAdditionalValue(b : Nat8) : Result.Result<AdditionalInformation, Text> {
    if (b < 24) return #ok(#Value(b));
    switch (b) {
      case (24) #ok(#ByteSize(1));
      case (25) #ok(#ByteSize(2));
      case (26) #ok(#ByteSize(4));
      case (27) #ok(#ByteSize(8));
      /// These values are reserved for future additions to the
      /// CBOR format.  In the present version of CBOR, the encoded item is
      /// not well-formed.
      case (28 or 29 or 30) #err("reserved");
      case (31) #ok(#Indefinite);
      case (_) #err("invalid additional information");
    };
  };

  private func getAdditionalBytes(bytes : Iter.Iter<Nat8>, size : Nat8) : Result.Result<[Nat8], Text> {
    let s = Nat8.toNat(size);
    let tmp = Array.init<Nat8>(s, 0);
    for (i in Iter.range(0, s - 1)) {
      tmp[i] := switch (bytes.next()) {
        case (?byte) byte;
        case (null) return #err("eod");
      };
    };
    #ok(Array.freeze(tmp));
  };

};
