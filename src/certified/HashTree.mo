import Blob "mo:base/Blob";
import Debug "mo:base/Debug";

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
            case (#empty) { hashEmpty() };
            case (#fork(l, r)) { hashFork(reconstruct(l), reconstruct(r)) };
            case (#labeled(k, t)) { hashLabeled(k, reconstruct(t)) };
            case (#leaf(v)) { hashLeaf(v) };
            case (#pruned(prunedHash)) { prunedHash };
        };
    };

    private func hashEmpty() : Hash {
        SHA256.sum(Blob.toArray("\11ic-hashtree-empty"));
    };

    private func hashFork(l : Hash, r : Hash) : Hash {
        let digest = SHA256.SHA256();
        digest.write(Blob.toArray("\10ic-hashtree-fork"));
        digest.write(l);
        digest.write(r);
        digest.checkSum();
    };

    private func hashLabeled(k : Key, h : Hash) : Hash {
        let digest = SHA256.SHA256();
        digest.write(Blob.toArray("\13ic-hashtree-labeled"));
        digest.write(k);
        digest.write(h);
        digest.checkSum();
    };

    private func hashLeaf(v : Value) : Hash {
        let digest = SHA256.SHA256();
        digest.write(Blob.toArray("\10ic-hashtree-leaf"));
        digest.write(v);
        digest.checkSum();
    };
};
