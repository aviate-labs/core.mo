import Blob "mo:base/Blob";

import CBOR "mo:core/cbor/CBOR";
import { encode; decode } = "mo:core/cbor/CBOR";

// https://www.rfc-editor.org/rfc/rfc7049#appendix-A
let tests : [(Blob, CBOR.Value)] = [
  (Blob.fromArray([0x00]), #UnsignedInteger(0)), // 0
  (Blob.fromArray([0x01]), #UnsignedInteger(1)), // 1
  (Blob.fromArray([0x0a]), #UnsignedInteger(10)), // 10
  (Blob.fromArray([0x17]), #UnsignedInteger(23)), // 23
  (Blob.fromArray([0x18, 0x18]), #UnsignedInteger(24)), // 24
  (Blob.fromArray([0x18, 0x19]), #UnsignedInteger(25)), // 25
  (Blob.fromArray([0x18, 0x64]), #UnsignedInteger(100)), // 100
  (Blob.fromArray([0x19, 0x03, 0xe8]), #UnsignedInteger(1000)), // 1000
  (Blob.fromArray([0x1a, 0x00, 0x0f, 0x42, 0x40]), #UnsignedInteger(1000000)), // 1000000
  (Blob.fromArray([0x1b, 0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]), #UnsignedInteger(1000000000000)), // 1000000000000
  (Blob.fromArray([0x1b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]), #UnsignedInteger(18446744073709551615)), // 18446744073709551615
  (
    Blob.fromArray([0xc2, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    #BigNumber(#Positive(18446744073709551616)),
  ), // 18446744073709551616
  (Blob.fromArray([0x3b, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff]), #NegativeInteger(-18446744073709551616)), // -18446744073709551616
  (
    Blob.fromArray([0xc3, 0x49, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]),
    #BigNumber(#Negative(-18446744073709551617)),
  ), // -18446744073709551617
  (Blob.fromArray([0x20]), #NegativeInteger(-1)), // -1
  (Blob.fromArray([0x29]), #NegativeInteger(-10)), // -10
  (Blob.fromArray([0x38, 0x63]), #NegativeInteger(-100)), // -100
  (Blob.fromArray([0x39, 0x03, 0xe7]), #NegativeInteger(-1000)), // -1000
  (Blob.fromArray([0xf9, 0x00, 0x00]), #Float({ precision = #half; mantissa = 0; exponent = null; sign = false })), // 0.0
  (Blob.fromArray([0xf9, 0x80, 0x00]), #Float({ precision = #half; mantissa = 0; exponent = null; sign = true })), // -0.0
  (Blob.fromArray([0xf9, 0x3c, 0x00]), #Float({ precision = #half; mantissa = 0; exponent = ?0; sign = false })), // 1.0
  (
    Blob.fromArray([0xfb, 0x3f, 0xf1, 0x99, 0x99, 0x99, 0x99, 0x99, 0x9a]),
    #Float({
      precision = #double;
      mantissa = 450_359_962_737_050;
      exponent = ?0;
      sign = false;
    }),
  ), // 1.1
  (Blob.fromArray([0xf9, 0x3e, 0x00]), #Float({ precision = #half; mantissa = 512; exponent = ?0; sign = false })), // 1.5
  (Blob.fromArray([0xf9, 0x7b, 0xff]), #Float({ precision = #half; mantissa = 1_023; exponent = ?15; sign = false })), // 65504.0
  (
    Blob.fromArray([0xfa, 0x47, 0xc3, 0x50, 0x00]),
    #Float({
      precision = #single;
      mantissa = 4_411_392;
      exponent = ?16;
      sign = false;
    }),
  ), // 100000.0
  (
    Blob.fromArray([0xfa, 0x7f, 0x7f, 0xff, 0xff]),
    #Float({
      precision = #single;
      mantissa = 8_388_607;
      exponent = ?127;
      sign = false;
    }),
  ), // 3.4028234663852886e+38
  (
    Blob.fromArray([0xfb, 0x7e, 0x37, 0xe4, 0x3c, 0x88, 0x00, 0x75, 0x9c]),
    #Float({
      precision = #double;
      mantissa = 2_221_273_467_876_764;
      exponent = ?996;
      sign = false;
    }),
  ), // 1.0e+300
  (Blob.fromArray([0xf9, 0x00, 0x01]), #Float({ precision = #half; mantissa = 1; exponent = null; sign = false })), // 5.960464477539063e-8
  (Blob.fromArray([0xf9, 0x04, 0x00]), #Float({ precision = #half; mantissa = 0; exponent = ?-14; sign = false })), // 0.00006103515625
  (Blob.fromArray([0xf9, 0xc4, 0x00]), #Float({ precision = #half; mantissa = 0; exponent = ?2; sign = true })), // -4.0
  (
    Blob.fromArray([0xfb, 0xc0, 0x10, 0x66, 0x66, 0x66, 0x66, 0x66, 0x66]),
    #Float({
      precision = #double;
      mantissa = 112_589_990_684_262;
      exponent = ?2;
      sign = true;
    }),
  ), // -4.1
  (Blob.fromArray([0xf9, 0x7c, 0x00]), #Infinity({ precision = #half; sign = false })), // Infinity
  (Blob.fromArray([0xf9, 0x7e, 0x00]), #NaN({ precision = #half })), // NaN
  (Blob.fromArray([0xf9, 0xfc, 0x00]), #Infinity({ precision = #half; sign = true })), // -Infinity
  (Blob.fromArray([0xfa, 0x7f, 0x80, 0x00, 0x00]), #Infinity({ precision = #single; sign = false })), // Infinity
  (Blob.fromArray([0xfa, 0x7f, 0xc0, 0x00, 0x00]), #NaN({ precision = #single })), // NaN
  (Blob.fromArray([0xfa, 0xff, 0x80, 0x00, 0x00]), #Infinity({ precision = #single; sign = true })), // -Infinity
  (Blob.fromArray([0xfb, 0x7f, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), #Infinity({ precision = #double; sign = false })), // Infinity
  (Blob.fromArray([0xfb, 0x7f, 0xf8, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), #NaN({ precision = #double })), // NaN
  (Blob.fromArray([0xfb, 0xff, 0xf0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]), #Infinity({ precision = #double; sign = true })), // -Infinity

  (Blob.fromArray([0xf4]), #Bool(false)), // false
  (Blob.fromArray([0xf5]), #Bool(true)), // true
  (Blob.fromArray([0xf6]), #Null), // null
  (Blob.fromArray([0xf7]), #Undefined), // undefined
  (Blob.fromArray([0xf0]), #Simple(16)), // simple(16)
  (Blob.fromArray([0xf8, 0xff]), #Simple(255)), // simple(255)

  (
    Blob.fromArray([0xc0, 0x74, 0x32, 0x30, 0x31, 0x33, 0x2d, 0x30, 0x33, 0x2d, 0x32, 0x31, 0x54, 0x32, 0x30, 0x3a, 0x30, 0x34, 0x3a, 0x30, 0x30, 0x5a]),
    #Tag({ tag = 0; value = #TextString("2013-03-21T20:04:00Z") }),
  ), // 0("2013-03-21T20:04:00Z")
  (Blob.fromArray([0xc1, 0x1a, 0x51, 0x4b, 0x67, 0xb0]), #Tag({ tag = 1; value = #UnsignedInteger(1363896240) })), // 1(1363896240)
  (
    Blob.fromArray([0xc1, 0xfb, 0x41, 0xd4, 0x52, 0xd9, 0xec, 0x20, 0x00, 0x00]),
    #Tag({
      tag = 1;
      value = #Float({
        precision = #double;
        mantissa = 1_216_995_829_743_616;
        exponent = ?30;
        sign = false;
      });
    }),
  ), // 1(1363896240.5)
  (
    Blob.fromArray([0xd7, 0x44, 0x01, 0x02, 0x03, 0x04]),
    #Tag({
      tag = 23;
      value = #ByteString("\01\02\03\04");
    }),
  ), // 23(h'01020304')
  (
    Blob.fromArray([0xd8, 0x18, 0x45, 0x64, 0x49, 0x45, 0x54, 0x46]),
    #Tag({
      tag = 24;
      value = #ByteString("\64\49\45\54\46");
    }),
  ), // 24(h'6449455446')
  (
    Blob.fromArray([0xd8, 0x20, 0x76, 0x68, 0x74, 0x74, 0x70, 0x3a, 0x2f, 0x2f, 0x77, 0x77, 0x77, 0x2e, 0x65, 0x78, 0x61, 0x6d, 0x70, 0x6c, 0x65, 0x2e, 0x63, 0x6f, 0x6d]),
    #Tag({
      tag = 32;
      value = #TextString("http://www.example.com");
    }),
  ), // 32("http://www.example.com")

  (Blob.fromArray([0x40]), #ByteString("")), // h''
  (Blob.fromArray([0x44, 0x01, 0x02, 0x03, 0x04]), #ByteString("\01\02\03\04")), // h'01020304'

  (Blob.fromArray([0x60]), #TextString("")), // ""
  (Blob.fromArray([0x61, 0x61]), #TextString("a")), // "a"
  (Blob.fromArray([0x64, 0x49, 0x45, 0x54, 0x46]), #TextString("IETF")), // "IETF"
  (Blob.fromArray([0x62, 0x22, 0x5c]), #TextString("\"\\")), // "\"\\"
  (Blob.fromArray([0x62, 0xc3, 0xbc]), #TextString("ü")), // "ü"
  (Blob.fromArray([0x63, 0xe6, 0xb0, 0xb4]), #TextString("水")), // "水"
  (Blob.fromArray([0x64, 0xf0, 0x9f, 0x92, 0xa9]), #TextString("💩")), // "💩"
  (Blob.fromArray([0x80]), #Array([])), // []
  (
    Blob.fromArray([0x83, 0x01, 0x02, 0x03]),
    #Array([#UnsignedInteger(1), #UnsignedInteger(2), #UnsignedInteger(3)]),
  ), // [1, 2, 3]
  (
    Blob.fromArray([0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]),
    #Array([#UnsignedInteger(1), #Array([#UnsignedInteger(2), #UnsignedInteger(3)]), #Array([#UnsignedInteger(4), #UnsignedInteger(5)])]),
  ), // [1, [2, 3], [4, 5]]
  (Blob.fromArray([0xa0]), #Map([])), // {}
  (
    Blob.fromArray([0xa2, 0x01, 0x02, 0x03, 0x04]),
    #Map([(#UnsignedInteger(1), #UnsignedInteger(2)), (#UnsignedInteger(3), #UnsignedInteger(4))]),
  ), // {1: 2, 3: 4}
  (
    Blob.fromArray([0xa2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x82, 0x02, 0x03]),
    #Map([(#TextString("a"), #UnsignedInteger(1)), (#TextString("b"), #Array([#UnsignedInteger(2), #UnsignedInteger(3)]))]),
  ), // {"a": 1, "b": [2, 3]}
  (
    Blob.fromArray([0x82, 0x61, 0x61, 0xa1, 0x61, 0x62, 0x61, 0x63]),
    #Array([#TextString("a"), #Map([(#TextString("b"), #TextString("c"))])]),
  ), // ["a", {"b": "c"}]
  (
    Blob.fromArray([0xa5, 0x61, 0x61, 0x61, 0x41, 0x61, 0x62, 0x61, 0x42, 0x61, 0x63, 0x61, 0x43, 0x61, 0x64, 0x61, 0x44, 0x61, 0x65, 0x61, 0x45]),
    #Map([
      (#TextString("a"), #TextString("A")),
      (#TextString("b"), #TextString("B")),
      (#TextString("c"), #TextString("C")),
      (#TextString("d"), #TextString("D")),
      (#TextString("e"), #TextString("E")),
    ]),
  ), // {"a": "A", "b": "B", "c": "C", "d": "D", "e": "E"}
] : [(Blob, CBOR.Value)];

for ((b, r) in tests.vals()) {
  let v = switch (decode(b)) {
    case (#ok(value)) {
      assert (value == r);
      value;
    };
    case (#err(_)) {
      assert (false);
      loop {};
    };
  };

  let value = encode(v);
  assert (value == b);
};

let streaming_tests = [
  (
    Blob.fromArray([0x5f, 0x42, 0x01, 0x02, 0x43, 0x03, 0x04, 0x05, 0xff]),
    #ByteString("\01\02\03\04\05"),
    Blob.fromArray([0x45, 0x01, 0x02, 0x03, 0x04, 0x05]),
  ), // (_ h'0102', h'030405')
  (
    Blob.fromArray([0x7f, 0x65, 0x73, 0x74, 0x72, 0x65, 0x61, 0x64, 0x6d, 0x69, 0x6e, 0x67, 0xff]),
    #TextString("streaming"),
    Blob.fromArray([0x69, 0x73, 0x74, 0x72, 0x65, 0x61, 0x6d, 0x69, 0x6e, 0x67]),
  ), // (_ "strea", "ming")
  (
    Blob.fromArray([0x9f, 0xff]),
    #Array([]),
    Blob.fromArray([0x80]),
  ), // [_ ]
  (
    Blob.fromArray([0x9f, 0x01, 0x82, 0x02, 0x03, 0x9f, 0x04, 0x05, 0xff, 0xff]),
    #Array([#UnsignedInteger(1), #Array([#UnsignedInteger(2), #UnsignedInteger(3)]), #Array([#UnsignedInteger(4), #UnsignedInteger(5)])]),
    Blob.fromArray([0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]),
  ), // [_ 1, [2, 3], [_ 4, 5]]
  (
    Blob.fromArray([0x9f, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05, 0xff]),
    #Array([#UnsignedInteger(1), #Array([#UnsignedInteger(2), #UnsignedInteger(3)]), #Array([#UnsignedInteger(4), #UnsignedInteger(5)])]),
    Blob.fromArray([0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]),
  ), // [_ 1, [2, 3], [4, 5]]
  (
    Blob.fromArray([0x83, 0x01, 0x9f, 0x02, 0x03, 0xff, 0x82, 0x04, 0x05]),
    #Array([#UnsignedInteger(1), #Array([#UnsignedInteger(2), #UnsignedInteger(3)]), #Array([#UnsignedInteger(4), #UnsignedInteger(5)])]),
    Blob.fromArray([0x83, 0x01, 0x82, 0x02, 0x03, 0x82, 0x04, 0x05]),
  ), // [1, [_ 2, 3], [4, 5]]
  (
    Blob.fromArray([0x9f, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19, 0xff]),
    #Array([
      #UnsignedInteger(1), #UnsignedInteger(2), #UnsignedInteger(3), #UnsignedInteger(4), #UnsignedInteger(5),
      #UnsignedInteger(6), #UnsignedInteger(7), #UnsignedInteger(8), #UnsignedInteger(9), #UnsignedInteger(10),
      #UnsignedInteger(11), #UnsignedInteger(12), #UnsignedInteger(13), #UnsignedInteger(14), #UnsignedInteger(15),
      #UnsignedInteger(16), #UnsignedInteger(17), #UnsignedInteger(18), #UnsignedInteger(19), #UnsignedInteger(20),
      #UnsignedInteger(21), #UnsignedInteger(22), #UnsignedInteger(23), #UnsignedInteger(24), #UnsignedInteger(25),
    ]),
    Blob.fromArray([0x98, 0x19, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x18, 0x18, 0x19]),
  ), // [_ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]
  (
    Blob.fromArray([0xbf, 0x61, 0x61, 0x01, 0x61, 0x62, 0x9f, 0x02, 0x03, 0xff, 0xff]),
    #Map([(#TextString("a"), #UnsignedInteger(1)), (#TextString("b"), #Array([#UnsignedInteger(2), #UnsignedInteger(3)]))]),
    Blob.fromArray([0xa2, 0x61, 0x61, 0x01, 0x61, 0x62, 0x82, 0x02, 0x03]),
  ), // {_ "a": 1, "b": [_ 2, 3]}
  (
    Blob.fromArray([0x82, 0x61, 0x61, 0xbf, 0x61, 0x62, 0x61, 0x63, 0xff]),
    #Array([#TextString("a"), #Map([(#TextString("b"), #TextString("c"))])]),
    Blob.fromArray([0x82, 0x61, 0x61, 0xa1, 0x61, 0x62, 0x61, 0x63]),
  ), // ["a", {_ "b": "c"}]
  (
    Blob.fromArray([0xbf, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21, 0xff]),
    #Map([(#TextString("Fun"), #Bool(true)), (#TextString("Amt"), #NegativeInteger(-2))]),
    Blob.fromArray([0xa2, 0x63, 0x46, 0x75, 0x6e, 0xf5, 0x63, 0x41, 0x6d, 0x74, 0x21]),
  ), // {_ "Fun": true, "Amt": -2}
] : [(Blob, CBOR.Value, Blob)];

for ((b, r, e) in streaming_tests.vals()) {
  switch (decode(b)) {
    case (#ok(value)) {
      assert (value == r);
    };
    case (#err(msg)) {
      assert (false);
    };
  };

  let ve = switch (decode(e)) {
    case (#ok(value)) {
      assert (value == r);
      value;
    };
    case (#err(_)) {
      assert (false);
      loop {};
    };
  };

  let value = encode(ve);
  assert (value == e);
};
