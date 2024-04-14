import P "mo:base/Prelude";

import HashTree "HashTree";

module {
    public type Node = (
        key : [Nat8], // 0 : key
        value : [Nat8], // 1 : value
        left : ?Node, // 2 : left
        right : ?Node, // 3 : right
        color : Color, // 4 : color
        hash : HashTree.Hash, // 5 : hash
    );

    private type Color = {
        #Red;
        #Black;
    };

    private func flip(c : Color) : Color {
        switch (c) {
            case (#Red) { #Black };
            case (#Black) { #Red };
        };
    };

    public func insertRoot(root : ?Node, k : [Nat8], v : [Nat8]) : (Node, ?[Nat8]) {
        let ((nk, nv, l, r, _, h), ov) = insert(root, k, v);
        ((nk, nv, l, r, #Black, h), ov);
    };

    public func insert(t : ?Node, k : [Nat8], v : [Nat8]) : (Node, ?[Nat8]) {
        switch (t) {
            case (null) { (newNode(k, v), null) };
            case (?n) {
                let (nk, kv, l, r, c, h) = n;
                let (nn, ov) : (Node, ?[Nat8]) = switch (compare(k, nk)) {
                    case (#less) {
                        let (nl, ov) = insert(l, k, v);
                        ((nk, kv, ?nl, r, c, h), ov);
                    };
                    case (#equal) {
                        ((nk, v, l, r, c, h), ?kv);
                    };
                    case (#greater) {
                        let (nr, ov) = insert(r, k, v);
                        ((nk, kv, l, ?nr, c, h), ov);
                    };
                };
                (balance(update(nn)), ov);
            };
        };
    };

    public func get(t : ?Node, k : [Nat8]) : ?[Nat8] {
        var root = t;
        label l loop {
            let (key, v, l, r, _, _) = switch (root) {
                case (null) { break l };
                case (?v) { v };
            };
            switch (compare(k, key)) {
                case (#less) {
                    root := l;
                };
                case (#equal) {
                    return ?v;
                };
                case (#greater) {
                    root := r;
                };
            };
        };
        null;
    };

    private func compare(xs : [Nat8], ys : [Nat8]) : { #less; #equal; #greater } {
        if (xs.size() < ys.size()) return #less;
        if (xs.size() > ys.size()) return #greater;
        var i = 0;
        while (i < xs.size()) {
            let x = xs[i];
            let y = ys[i];
            if (x < y) return #less;
            if (y < x) return #greater;
            i += 1;
        };
        #equal;
    };

    private func isRed(n : ?Node) : Bool {
        switch (n) {
            case (?(_, _, _, _, #Red, _)) { true };
            case (_) { false };
        };
    };

    private func balance(n : Node) : Node {
        switch (n) {
            case (k, v, ?l, ?r, c, h) {
                if (not isRed(?l) and isRed(?r)) return rotateLeft(n);
                if (isRed(?l) and isRed(l.2)) return rotateRight(n);
                if (isRed(?l) and isRed(?r)) return (k, v, ?flipColor(l), ?flipColor(r), flip(c), h);
            };
            case (_) {};
        };
        n;
    };

    private func rotateRight(n : Node) : Node {
        assert (isRed(n.2));
        var l = unwrap(n.2);
        // n.l = n.l.r;
        let h = update((n.0, n.1, l.3, n.3, n.4, n.5));
        // r.r = h;
        // r.c = h.c;
        // r.r.c = #Red;
        update((l.0, l.1, l.2, ?(h.0, h.1, h.2, h.3, #Red, h.5), h.4, l.5));
    };

    private func rotateLeft(n : Node) : Node {
        assert (isRed(n.3));
        var r = unwrap(n.3);
        // n.r = n.r.l;
        let h = update((n.0, n.1, n.2, r.2, n.4, n.5));
        // r.l = h;
        // r.c = h.c;
        // r.l.c = #Red;
        update((r.0, r.1, ?(h.0, h.1, h.2, h.3, #Red, h.5), r.3, h.4, r.5));
    };

    private func flipColor((k, v, l, r, c, h) : Node) : Node {
        (k, v, l, r, flip(c), h);
    };

    // NOTE: do use with caution!
    private func unwrap<T>(x : ?T) : T {
        switch x {
            case (null) { P.unreachable() };
            case (?x) { x };
        };
    };

    // Returns a new node based on the given key and value.
    public func newNode(key : [Nat8], value : [Nat8]) : Node {
        (key, value, null, null, #Red, HashTree.reconstruct(#Labeled(key, #Leaf(value))));
    };

    // Updates the hashes of the given node.
    private func update(n : Node) : Node {
        let (k, v, l, r, c, _) = n;
        (k, v, l, r, c, subHashTree(n));
    };

    private func subHashTree(n : Node) : HashTree.Hash {
        let h = dataHash(n);
        let (_, _, l, r, _, _) = n;
        switch (l, r) {
            case (null, null) h;
            case (?l, null) HashTree.reconstruct(#Fork(#Pruned(l.5), #Pruned(h)));
            case (null, ?r) HashTree.reconstruct(#Fork(#Pruned(h), #Pruned(r.5)));
            case (?l, ?r) HashTree.reconstruct(#Fork(#Pruned(l.5), #Fork(#Pruned(h), #Pruned(r.5))));
        };
    };

    // Returns the Hash corresponding to the node.
    public func getHash(n : ?Node) : ?HashTree.Hash {
        switch (n) {
            case (?n) ?n.5;
            case (null) null;
        };
    };

    // Returns the HashTree corresponding to the node.
    public func getHashTree(n : ?Node) : HashTree.HashTree {
        switch (n) {
            case (null) #Empty;
            case (?(v, k, null, null, _, _)) {
                if (v.size() == 0) return #Leaf(k);
                return #Labeled(v, #Leaf(k));
            };
            case (?(v, _, l, r, _, _)) {
                if (v.size() == 0) return #Fork(
                    getHashTree(l),
                    getHashTree(r),
                );
                return #Labeled(
                    v,
                    #Fork(
                        getHashTree(l),
                        getHashTree(r),
                    ),
                );
            };
        };
    };

    // Hashes the data contained within the node.
    private func dataHash((k, v, _, _, _, _) : Node) : HashTree.Hash {
        HashTree.reconstruct(#Labeled(k, #Leaf(v)));
    };
};
