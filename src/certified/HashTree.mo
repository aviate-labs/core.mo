import Blob "mo:base/Blob";
import Debug "mo:base/Debug";
import Array "mo:base/Array";

import CBOR "../cbor/CBOR";
import SHA256 "../crypto/SHA256";

module {
    type Hash = [Nat8];
    type Key = [Nat8];
    type Value = [Nat8];

    type HashTree = {
        #empty;
        #fork : (HashTree, HashTree);
        #labeled : (Key, HashTree);
        #leaf : Value;
        #pruned : Hash;
    };

    public func reconstruct(t : HashTree) : Hash {
        switch (t) {
            case (#empty) { hash.empty() };
            case (#fork(l, r)) { hash.fork(reconstruct(l), reconstruct(r)) };
            case (#labeled(k, t)) { hash.labeled(k, reconstruct(t)) };
            case (#leaf(v)) { hash.leaf(v) };
            case (#pruned(h)) { h };
        };
    };

    private module hash = {
        public func empty() : Hash {
            SHA256.sum(Blob.toArray("\11ic-hashtree-empty"));
        };

        public func fork(l : Hash, r : Hash) : Hash {
            let digest = SHA256.SHA256();
            digest.write(Blob.toArray("\10ic-hashtree-fork"));
            digest.write(l);
            digest.write(r);
            digest.checkSum();
        };

        public func labeled(k : Key, h : Hash) : Hash {
            let digest = SHA256.SHA256();
            digest.write(Blob.toArray("\13ic-hashtree-labeled"));
            digest.write(k);
            digest.write(h);
            digest.checkSum();
        };

        public func leaf(v : Value) : Hash {
            let digest = SHA256.SHA256();
            digest.write(Blob.toArray("\10ic-hashtree-leaf"));
            digest.write(v);
            digest.checkSum();
        };
    };

    public func encodeCBOR(t : HashTree) : Hash {
        Blob.toArray(CBOR.encode(cbor.tree(t)));
    };

    private module cbor = {
        public func tree(t : HashTree) : CBOR.Value = switch (t) {
            case (#empty) { empty() };
            case (#fork(l, r)) { fork(l, r) };
            case (#labeled(k, t)) { labeled(k, t) };
            case (#leaf(v)) { leaf(v) };
            case (#pruned(h)) { pruned(h) };
        };
        
        public func empty() : CBOR.Value = #Array([
            #UnsignedInteger(0),
        ]);

        public func fork(l : HashTree, r : HashTree) : CBOR.Value = #Array([
            #UnsignedInteger(1),
            tree(l),
            tree(r),
        ]);

        public func labeled(k : Key, t : HashTree) : CBOR.Value = #Array([
            #UnsignedInteger(2),
            #ByteString(Blob.fromArray(k)),
            tree(t),
        ]);

        public func leaf(v : Value) : CBOR.Value = #Array([
            #UnsignedInteger(3),
            #ByteString(Blob.fromArray(v)),
        ]);

        public func pruned(h : Hash) : CBOR.Value = #Array([
            #UnsignedInteger(4),
            #ByteString(Blob.fromArray(h)),
        ]);
    };
};
