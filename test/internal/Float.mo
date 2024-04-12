import Float = "../../internal/Float";

// You can play around here:
// https://evanw.github.io/float-toy/

assert(Float.decode([0x00, 0x00, 0x00, 0x00]) == #ok(#Float({exponent = null; mantissa = 0; precision = #single; sign = false}))); // 0.0
assert(Float.decode([0x80, 0x00, 0x00, 0x00]) == #ok(#Float({exponent = null; mantissa = 0; precision = #single; sign = true}))); // -0.0
assert(Float.decode([0x3f, 0x80, 0x00, 0x00]) == #ok(#Float({exponent = ?0; mantissa = 0; precision = #single; sign = false}))); // 1.0
assert(Float.decode([0x3f, 0x8c, 0xcc, 0xcd]) == #ok(#Float({exponent = ?0; mantissa = 838861; precision = #single; sign = false}))); // 1.1
assert(Float.decode([0x3f, 0xc0, 0x00, 0x00]) == #ok(#Float({exponent = ?0; mantissa = 4194304; precision = #single; sign = false}))); // 1.5
assert(Float.decode([0x47, 0x7f, 0xe0, 0x00]) == #ok(#Float({exponent = ?15; mantissa = 8380416; precision = #single; sign = false}))); // 65504.0
// etc.

func toFloat(bytes : [Nat8]) : Float = switch (Float.decode(bytes)) {
  case (#ok(#Float(f))) Float.toFloat(f);
  case (_) {
    assert(false);
    0.0;
  };
};

assert(toFloat([0x3f, 0x80, 0x00, 0x00]) == 1.0);
// Expected error of: 2.38418579_1015625E-8
assert(toFloat([0x3f, 0x8c, 0xcc, 0xcd]) == 1.100_000_023_841_857_9);
assert(toFloat([0x3f, 0xc0, 0x00, 0x00]) == 1.5);
assert(toFloat([0x47, 0x7f, 0xe0, 0x00]) == 65504.0);
