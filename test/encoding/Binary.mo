import { BigEndian; LittleEndian } "mo:core/encoding/Binary";

let n64 : Nat64 = 1_000_000_000_000;

let n64_be = BigEndian.fromNat64(n64);
assert (n64_be == [0x00, 0x00, 0x00, 0xe8, 0xd4, 0xa5, 0x10, 0x00]);
assert (n64 == BigEndian.toNat64(n64_be));

let n64_le = LittleEndian.fromNat64(n64);
assert (n64_le == [0x00, 0x10, 0xa5, 0xd4, 0xe8, 0x00, 0x00, 0x00]);
assert (n64 == LittleEndian.toNat64(n64_le));

let n = 1_000_000_000_000;

let n_be_bytes = BigEndian.fromNat(n);
assert (n_be_bytes == [0xe8, 0xd4, 0xa5, 0x10, 0x00]);
assert (n == BigEndian.toNat(n_be_bytes));

let n_le_bytes = LittleEndian.fromNat(n);
assert (n_le_bytes == [0x00, 0x10, 0xa5, 0xd4, 0xe8]);
assert (n == LittleEndian.toNat(n_le_bytes));
