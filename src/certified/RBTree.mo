import P "mo:base/Prelude";
import Iter "mo:base/Iter";
import List "mo:base/List";

import HashTree "HashTree";

// Based on 2-3 LLRB trees (https://sedgewick.io/wp-content/themes/sedgewick/papers/2008LLRB.pdf).
// This is the same type of tree that is used in de Rust CDK.
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

    // Iterates over the tree in order (left, root, right).
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
        (?(nk, nv, l, r, #Black, h), ov); // The root is always black.
    };

    private func _insert(n : ?Node, k : HashTree.Key, v : HashTree.Value) : (Node, ?HashTree.Value) {
        switch (n) {
            // The root is empty, so we insert a new node.
            case (null) { (newNode(k, v), null) };
            // The root is not empty, so we insert the key-value pair into the tree.
            case (?(nk, kv, l, r, c, h)) {
                let (nn, ov) : (Node, ?HashTree.Value) = switch (compare(k, nk)) {
                    // The key is equal to the current key, so we update the value.
                    case (#equal) ((nk, v, l, r, c, h), ?kv);
                    case (#less) {
                        // The key is less than the current key, so we insert it into the left subtree.
                        let (nl, ov) = _insert(l, k, v);
                        ((nk, kv, ?nl, r, c, h), ov);
                    };
                    case (#greater) {
                        // The key is greater than the current key, so we insert it into the right subtree.
                        let (nr, ov) = _insert(r, k, v);
                        ((nk, kv, l, ?nr, c, h), ov);
                    };
                };
                // Balance the tree and update the hash.
                (balance(update(nn)), ov);
            };
        };
    };

    public func deleteMin(root : Tree) : (?Node, ?HashTree.Value) {
        switch (root) {
            case (?n) switch (_deleteMin(n)) {
                case (?nn, ov) (?(nn.0, nn.1, nn.2, nn.3, #Black, nn.5), ov);
                case (n, ov) (n, ov);
            };
            // Nothing to delete.
            case (_) (null, null);
        };
    };

    private func _deleteMin(n : Node) : (?Node, ?HashTree.Value) {
        var nn = n;
        if (nn.2 == null) {
            debug assert(nn.3 == null);
            return (null, ?nn.0);
        };

        if (not isRed(nn.2) and not isRed(unwrap(nn.2).2)) {
            nn := moveRedLeft(nn);
        };

        let (nl, ov) = _deleteMin(unwrap(nn.2));
        return (?balance(update((nn.0, nn.1, nl, nn.3, nn.4, nn.5))), ov);
    };

    public func delete(root : Tree, k : HashTree.Key) : (?Node, ?HashTree.Value) {
        if (get(root, k) == null) return (root, null);
        switch (root) {
            case (?n) switch (_delete(n, k)) {
                case (?nn, ov) (?(nn.0, nn.1, nn.2, nn.3, #Black, nn.5), ov);
                case (n, ov) (n, ov);
            };
            // Nothing to delete.
            case (_) (null, null);
        };
    };

    private func _delete(n : Node, k : HashTree.Key) : (?Node, ?HashTree.Value) {
        var nn = n;
        var ov : ?HashTree.Value = null;

        let cmp = compare(k, nn.0);
        if (cmp == #less) {
            if (not isRed(nn.2) and nn.2 != null and not isRed(unwrap(nn.2).2)) {
                nn := moveRedLeft(nn);
            };

            let (nl, nov) = _delete(unwrap(nn.2), k);
            nn := (nn.0, nn.1, nl, nn.3, nn.4, nn.5);
            ov := nov;
        } else {
            if (isRed(nn.2)) {
                nn := rotateRight(nn);
            };
            if (cmp == #equal and nn.3 == null) {
                debug assert(nn.2 == null);
                return (null, ?nn.1);
            };
            if (not isRed(nn.3) and nn.3 != null and not isRed(unwrap(nn.3).2)) {
                nn := moveRedRight(nn);
            };
            if (compare(k, nn.0) == #equal) {
                let m = unwrap(min(nn.3));
                let (nr, _) = _deleteMin(unwrap(nn.3));
                nn := (m.0, m.1, nn.2, nr, nn.4, nn.5);
                ov := ?nn.1;
            } else {
                let (nr, nov) = _delete(unwrap(nn.3), k);
                nn := (nn.0, nn.1, nn.2, nr, nn.4, nn.5);
                ov := nov;
            };
        };
        (?balance(update(nn)), ov);
    };

    private func moveRedLeft(n : Node) : Node {
        var nn = flipColors(n);
        if (nn.3 != null and isRed(unwrap(nn.3).2)) {
            return flipColors(rotateLeft(nn.0, nn.1, nn.2, ?rotateRight(unwrap(nn.3)), nn.4, nn.5));
        };
        nn;
    };

    private func moveRedRight(n : Node) : Node {
        var nn = flipColors(n);
        if (nn.2 != null and isRed(unwrap(nn.2).2)) {
            return flipColors(rotateRight(nn));
        };
        nn;
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

    public func min(root : Tree) : ?Node = _min(root);

    private func _min(n : ?Node) : ?Node {
        var current = n;
        loop switch (current) {
            case (?(_, _, ?l, _, _, _)) current := ?l;
            case (_) return current;
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
        // If the left child it black and the right child is red, rotate left.
        if (not isRed(nn.2) and isRed(nn.3)) nn := rotateLeft(nn);
        // If the left child and its left child are red, rotate right.
        if (isRed(nn.2) and isRed(unwrap(nn.2).2)) nn := rotateRight(nn);
        // If both children are red, flip the colors.
        if (isRed(nn.2) and isRed(nn.3)) nn := flipColors(nn);
        nn;
    };

    // Rotates the given node to the left.
    // This comes down to making the right child the new root of the subtree.
    // Which means that the left tree of the right child becomes the right tree
    // of the old root. The hashes of the nodes are updated accordingly.
    private func rotateLeft(n : Node) : Node {
        debug assert (isRed(n.3));
        var nn = unwrap(n.3);
        let nl = update((n.0, n.1, n.2, nn.2, n.4, n.5));
        update((nn.0, nn.1, ?(nl.0, nl.1, nl.2, nl.3, #Red, nl.5), nn.3, nl.4, nn.5));
    };

    // Rotates the given node to the right.
    // This comes down to making the left child the new root of the subtree.
    // Which means that the right tree of the left child becomes the left tree
    // of the old root. The hashes of the nodes are updated accordingly.
    private func rotateRight(n : Node) : Node {
        debug assert (isRed(n.2));
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
