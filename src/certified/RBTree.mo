import P "mo:base/Prelude";
import Iter "mo:base/Iter";
import List "mo:base/List";

import HashTree "HashTree";

// Based on the RBTree of the Rust CDK.
module RBTree {
    // Tree represents a red-black tree, which keeps track of the hashes of the
    // subtrees. This creates an overhead, so only use this if you need a
    // certified tree.
    public type Tree = ?Node;

    // Node represents a node in the red-black tree.
    public type Node = (
        key : HashTree.Key, // 0 : key
        value : HashTree.Value, // 1 : value
        left : ?Node, // 2 : left
        right : ?Node, // 3 : right
        color : Color, // 4 : color
        hash : HashTree.Hash, // 5 : hash
    );

    // Internal color type.
    private type Color = {
        #Red;
        #Black;
    };

    private module Color {
        public func flip(c : Color) : Color {
            switch (c) {
                case (#Red) { #Black };
                case (#Black) { #Red };
            };
        };
    };

    // Visits the tree in order.
    public func visit(t : Tree, f : (HashTree.Key, HashTree.Value) -> ()) = _visit(t, f);

    private func _visit(n : ?Node, f : (HashTree.Key, HashTree.Value) -> ()) {
        switch (n) {
            case (null) {};
            case (?n) {
                let (k, v, l, r, _, _) = n;
                _visit(l, f);
                f(k, v);
                _visit(r, f);
            };
        };
    };

    public func iter(t : Tree) : Iter.Iter<(HashTree.Key, HashTree.Value)> = object {
        type IR = { #kv : (HashTree.Key, HashTree.Value); #node : Node };
        var stack : List.List<IR> = switch (t) {
            case (null) null;
            case (?n) ?(#node(n), null);
        };
        public func next() : ?(HashTree.Key, HashTree.Value) {
            switch (stack) {
                case (null) null;
                case (?(#kv(kv), rest)) {
                    stack := rest;
                    ?kv;
                };
                case (?(#node(k, v, ?l, ?r, _, _), rest)) {
                    stack := ?(#node(l), ?(#kv(k, v), ?(#node(r), rest)));
                    next();
                };
                case (?(#node(k, v, ?l, null, _, _), rest)) {
                    stack := ?(#node(l), ?(#kv(k, v), rest));
                    next();
                };
                case (?(#node(k, v, null, ?r, _, _), rest)) {
                    stack := ?(#kv(k, v), ?(#node(r), rest));
                    next();
                };
                case (?(#node(k, v, null, null, _, _), rest)) {
                    stack := rest;
                    ?(k, v);
                };
            };
        };
    };

    // Inserts a new key-value pair into the tree.
    public func insert(root : Tree, k : HashTree.Key, v : HashTree.Value) : (Tree, ?HashTree.Value) {
        let ((nk, nv, l, r, _, h), ov) = _insert(root, k, v);
        (?(nk, nv, l, r, #Black, h), ov);
    };

    private func _insert(n : ?Node, k : HashTree.Key, v : HashTree.Value) : (Node, ?HashTree.Value) {
        switch (n) {
            case (null) { (newNode(k, v), null) };
            case (?(nk, kv, l, r, c, h)) {
                let (nn, ov) : (Node, ?HashTree.Value) = switch (compare(k, nk)) {
                    case (#equal) ((nk, v, l, r, c, h), ?kv);
                    case (#less) {
                        let (nl, ov) = _insert(l, k, v);
                        ((nk, kv, ?nl, r, c, h), ov);
                    };
                    case (#greater) {
                        let (nr, ov) = _insert(r, k, v);
                        ((nk, kv, l, ?nr, c, h), ov);
                    };
                };
                (balance(update(nn)), ov);
            };
        };
    };

    // Gets the value associated with the given key.
    public func get(root : Tree, k : HashTree.Key) : ?HashTree.Value = _get(root, k);

    private func _get(n : ?Node, k : HashTree.Key) : ?HashTree.Value {
        var current = n;
        loop {
            let (nk, nv, l, r, _, _) = switch (current) {
                case (?v) v;
                case (null) return null;
            };
            switch (compare(k, nk)) {
                case (#less) current := l;
                case (#equal) return ?nv;
                case (#greater) current := r;
            };
        };
    };

    private func compare(xs : HashTree.Key, ys : HashTree.Key) : {
        #less;
        #equal;
        #greater;
    } {
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

    private func isRed(n : ?Node) : Bool = switch (n) {
        case (?(_, _, _, _, #Red, _)) { true };
        case (_) { false };
    };

    private func balance(n : Node) : Node {
        var nn = n;
        if (not isRed(nn.2) and isRed(nn.3)) nn := rotateLeft(nn);
        if (isRed(nn.2) and isRed(unwrap(nn.2).2)) nn := rotateRight(nn);
        if (isRed(nn.2) and isRed(nn.3)) nn := flipColors(nn);
        nn;
    };

    // Rotates the given node to the left.
    // This comes down to making the right child the new root of the subtree.
    // Which means that the left tree of the right child becomes the right tree
    // of the old root. The hashes of the nodes are updated accordingly.
    private func rotateLeft(n : Node) : Node {
        assert (isRed(n.3));
        var nn = unwrap(n.3);
        let nl = update((n.0, n.1, n.2, nn.2, n.4, n.5));
        update((nn.0, nn.1, ?(nl.0, nl.1, nl.2, nl.3, #Red, nl.5), nn.3, nl.4, nn.5));
    };

    // Rotates the given node to the right.
    // This comes down to making the left child the new root of the subtree.
    // Which means that the right tree of the left child becomes the left tree
    // of the old root. The hashes of the nodes are updated accordingly.
    private func rotateRight(n : Node) : Node {
        assert (isRed(n.2));
        var nn = unwrap(n.2);
        let nr = update((n.0, n.1, nn.3, n.3, n.4, n.5));
        update((nn.0, nn.1, nn.2, ?(nr.0, nr.1, nr.2, nr.3, #Red, nr.5), nr.4, nn.5));
    };

    // Flips the color of the given node and its children.
    private func flipColors((k, v, l, r, c, h) : Node) : Node {
        (k, v, flipColor(l), flipColor(r), Color.flip(c), h);
    };

    private func flipColor(n : ?Node) : ?Node {
        switch (n) {
            case (null) n;
            case (?(k, v, l, r, c, h)) {
                ?(k, v, l, r, Color.flip(c), h);
            };
        };
    };

    // NOTE: do use with caution!
    private func unwrap<T>(x : ?T) : T {
        switch x {
            case (null) { P.unreachable() };
            case (?x) { x };
        };
    };

    // Returns a new node based on the given key and value.
    public func newNode(key : HashTree.Key, value : HashTree.Value) : Node {
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
