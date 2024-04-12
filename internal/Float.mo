import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Int "mo:base/Int";
import Int16 "mo:base/Int16";
import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";

import { LittleEndian; BigEndian } = "../src/encoding/Binary";

module {

    // Precision of a floating point number.
    public type Precision = {
        #half; // IEEE 754 Half-Precision Float (16 bits)
        #single; // IEEE 754 Single-Precision Float (32 bits)
        #double; // IEEE 754 Double-Precision Float (64 bits)
    };

    // Floating point numbers.
    // I.e. 65504 as #b4: 0.10001110.11111111110000000000000
    // | 0    | 10001110 | 11111111110000000000000
    // | +1   | 15       | 1.11111111110000000000000 (binary)
    // | +1   * 2^15     * 1.9990234375              = 65504
    public type FloatingPoint = {
        // The precision of the float.
        precision : Precision;
        // The decimal representation of the mantissa bytes.
        // i.e. 1_023 -> 1111111111
        mantissa : Nat64;
        // The exponent of the float.
        exponent : ?Int16;
        // The sign of the float.
        sign : Bool;
    };

    public type Infinity = {
        // The precision of the float.
        precision : Precision;
        // The sign of the infinity.
        sign : Bool;
    };

    public type NaN = {
        // The precision of the float.
        precision : Precision;
    };

    public func toFloat({ precision; mantissa; exponent; sign } : FloatingPoint) : Float {
        let s = if (sign) -1.0 else 1.0;
        let (exp : Float, n : Float) = switch (exponent) {
            case (?exp) (Float.fromInt(Int16.toInt(exp)), 1.0);
            case (null) (-14.0, 0.0);
        };
        let expValue : Float = if (sign) { 1 / 2 ** (-1 * exp) } else {
            2 ** exp;
        };
        let max = Float.fromInt(
            switch (precision) {
                case (#half) 2 ** 10;
                case (#single) 2 ** 23;
                case (#double) 2 ** 52;
            }
        );
        s * expValue * (n + Float.fromInt(Nat64.toNat(mantissa)) / max);
    };

    public type DecodeResult = {
        #Float : FloatingPoint;
        #Infinity : Infinity;
        #NaN : NaN;
    };

    // Decode a floating point number from a byte array.
    public func decode(bytes : [Nat8]) : Result.Result<DecodeResult, Text> {
        let (exponentSize, mantissaSize, precision) : (Nat64, Nat64, Precision) = switch (bytes.size()) {
            case (2) (5, 10, #half);
            case (4) (8, 23, #single);
            case (8) (11, 52, #double);
            case (_) return #err("invalid float size");
        };

        let n = Nat64.fromNat(BigEndian.toNat(bytes));
        if (n == 0) return #ok(#Float({ precision = precision; mantissa = 0; exponent = null; sign = false }));

        let mantissa = n & ((1 << mantissaSize) - 1);
        let e = (n >> mantissaSize) & ((1 << exponentSize) - 1);
        let exponentMax = (1 << (exponentSize - 1)) - 1;
        let sign = (n >> (mantissaSize + exponentSize)) & 1;
        if (e + 1 == 1 << exponentSize) {
            if (mantissa == 0) return #ok(#Infinity({ precision = precision; sign = sign == 1 }));
            if (mantissa == 1 << (mantissaSize - 1)) return #ok(#NaN({ precision = precision }));
        };
        let exponent = if (e == 0) null else {
            ?(Int16.fromInt(Nat64.toNat(e)) - Int16.fromInt(Nat64.toNat(exponentMax)));
        };
        #ok(#Float({ precision; mantissa; exponent; sign = sign == 1 }));
    };

    // Encode a floating point number into a byte array.
    public func encode({ precision; mantissa; exponent; sign } : FloatingPoint) : (buffer : Buffer.Buffer<Nat8>) {
        let (exponentSize, mantissaSize) : (Nat64, Nat64) = switch (precision) {
            case (#half) (5, 10);
            case (#single) (8, 23);
            case (#double) (11, 52);
        };
        var n : Nat64 = if (sign) { 1 } else { 0 };
        n <<= exponentSize;
        n += switch (exponent) {
            case (?e) {
                let exponentMax = (1 << (exponentSize - 1)) - 1;
                Nat64.fromNat(Int.abs(Int16.toInt(e) + Nat64.toNat(exponentMax)));
            };
            case (_) 0;
        };
        n <<= mantissaSize;
        n += mantissa;

        let tmp = Buffer.fromArray<Nat8>(LittleEndian.fromNat(Nat64.toNat(n)));
        switch (tmp.size()) {
            case (0) {
                tmp.add(0);
                tmp.add(0);
            };
            case (1 or 3) tmp.add(0);
            case (2 or 4 or 8) {};
            case (_) while (tmp.size() < 8) tmp.add(0);
        };
        tmp;
    };

};
