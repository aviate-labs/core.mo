import Array "mo:base/Array";
import Nat8 "mo:base/Nat8";
import Nat16 "mo:base/Nat16";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";

import {
    nat8ToNat16 = nat8to16;
    nat16ToNat8 = nat16to8;
    shiftLeft;
    shiftRight;
} = "mo:⛔";

module {
    private type ByteOrder = {
        fromNat16 : (Nat16) -> [Nat8];
        fromNat32 : (Nat32) -> [Nat8];
        fromNat64 : (Nat64) -> [Nat8];
        fromNat : (Nat) -> [Nat8];
        toNat16 : ([Nat8]) -> Nat16;
        toNat32 : ([Nat8]) -> Nat32;
        toNat64 : ([Nat8]) -> Nat64;
        toNat : ([Nat8]) -> Nat;
    };

    private func byteSize(n : Nat) : Nat {
        var m = n;
        var size = 0;
        while (m > 0) {
            m := shiftRight(m, 8);
            size += 1;
        };
        size;
    };

    private func nat32to8(n : Nat32) : Nat8 = Nat8.fromIntWrap(Nat32.toNat(n));
    private func nat8to32(n : Nat8) : Nat32 = Nat32.fromIntWrap(Nat8.toNat(n));

    private func nat64to8(n : Nat64) : Nat8 = Nat8.fromIntWrap(Nat64.toNat(n));
    private func nat8to64(n : Nat8) : Nat64 = Nat64.fromIntWrap(Nat8.toNat(n));

    public let LittleEndian : ByteOrder = {
        toNat16 = func(src : [Nat8]) : Nat16 {
            nat8to16(src[0]) | nat8to16(src[1]) << 8;
        };

        fromNat16 = func(n : Nat16) : [Nat8] = [
            nat16to8(n),
            nat16to8(n >> 8),
        ];

        toNat32 = func(src : [Nat8]) : Nat32 {
            nat8to32(src[0]) | nat8to32(src[1]) << 8 | nat8to32(src[2]) << 16 | nat8to32(src[3]) << 24;
        };

        fromNat32 = func(n : Nat32) : [Nat8] = [
            nat32to8(n),
            nat32to8(n >> 8),
            nat32to8(n >> 16),
            nat32to8(n >> 24),
        ];

        toNat64 = func(src : [Nat8]) : Nat64 {
            nat8to64(src[0]) | nat8to64(src[1]) << 8 | nat8to64(src[2]) << 16 | nat8to64(src[3]) << 24 | nat8to64(src[4]) << 32 | nat8to64(src[5]) << 40 | nat8to64(src[6]) << 48 | nat8to64(src[7]) << 56;
        };

        fromNat64 = func(n : Nat64) : [Nat8] = [
            nat64to8(n),
            nat64to8(n >> 8),
            nat64to8(n >> 16),
            nat64to8(n >> 24),
            nat64to8(n >> 32),
            nat64to8(n >> 40),
            nat64to8(n >> 48),
            nat64to8(n >> 56),
        ];

        toNat = func(src : [Nat8]) : Nat {
            var n = 0x00 : Nat;
            var idx = 0;
            var multiplier = 1 : Nat;
            while (idx < src.size()) {
                n += Nat8.toNat(src[idx]) * multiplier;
                multiplier := shiftLeft(multiplier, 8);
                idx += 1;
            };
            n;
        };

        fromNat = func(n : Nat) : [Nat8] {
            // Precalculate the size of the array.
            let s = byteSize(n);
            let b = Array.init<Nat8>(s, 0x00);

            var idx = 0;
            while (idx < s) {
                b[idx] := Nat8.fromIntWrap(
                    shiftRight(n, Nat32.fromIntWrap(idx * 8))
                );
                idx += 1;
            };
            Array.freeze(b);
        };
    };

    public let BigEndian : ByteOrder = {
        toNat16 = func(src : [Nat8]) : Nat16 {
            nat8to16(src[1]) | nat8to16(src[0]) << 8;
        };

        fromNat16 = func(n : Nat16) : [Nat8] = [
            nat16to8(n >> 8),
            nat16to8(n),
        ];

        toNat32 = func(src : [Nat8]) : Nat32 {
            nat8to32(src[3]) | nat8to32(src[2]) << 8 | nat8to32(src[1]) << 16 | nat8to32(src[0]) << 24;
        };

        fromNat32 = func(n : Nat32) : [Nat8] = [
            nat32to8(n >> 24),
            nat32to8(n >> 16),
            nat32to8(n >> 8),
            nat32to8(n),
        ];

        toNat64 = func(src : [Nat8]) : Nat64 {
            nat8to64(src[7]) | nat8to64(src[6]) << 8 | nat8to64(src[5]) << 16 | nat8to64(src[4]) << 24 | nat8to64(src[3]) << 32 | nat8to64(src[2]) << 40 | nat8to64(src[1]) << 48 | nat8to64(src[0]) << 56;
        };

        fromNat64 = func(n : Nat64) : [Nat8] = [
            nat64to8(n >> 56),
            nat64to8(n >> 48),
            nat64to8(n >> 40),
            nat64to8(n >> 32),
            nat64to8(n >> 24),
            nat64to8(n >> 16),
            nat64to8(n >> 8),
            nat64to8(n),
        ];

        toNat = func(src : [Nat8]) : Nat {
            var n = 0 : Nat;
            for (b in src.vals()) {
                n := shiftLeft(n, 8) + Nat8.toNat(b);
            };
            n;
        };

        fromNat = func(n : Nat) : [Nat8] {
            // Precalculate the size of the array.
            let s = byteSize(n);
            let b = Array.init<Nat8>(s, 0x00);

            var idx = 0;
            while (idx < s) {
                b[idx] := Nat8.fromIntWrap(
                    shiftRight(n, Nat32.fromIntWrap((s - idx - 1) * 8))
                );
                idx += 1;
            };
            Array.freeze(b);
        };
    };
};
