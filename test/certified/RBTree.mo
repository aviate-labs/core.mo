import Nat8 "mo:base/Nat8";

import HashTree "mo:core/certified/HashTree";
import RBTree "mo:core/certified/RBTree";

func isRed(n : ?RBTree.Node) : Bool {
    switch (n) {
        case (?(_, _, _, _, #Red, _)) { true };
        case (_) { false };
    };
};

func isBalanced(t : ?RBTree.Node) : Bool {
    func _isBalanced(n : ?RBTree.Node, nrBlack : Nat) : Bool {
        var _nrBlack = nrBlack;
        switch (n) {
            case (null) {
                _nrBlack == 0;
            };
            case (?n) {
                if (not isRed(?n)) {
                    _nrBlack -= 1;
                } else {
                    assert (not isRed(n.2));
                    assert (not isRed(n.3));
                };
                _isBalanced(n.2, _nrBlack) and _isBalanced(n.3, _nrBlack);
            };
        };
    };

    // Calculate number of black nodes by following left.
    var nrBlack = 0;
    var current = t;
    label l loop {
        switch (current) {
            case (null) { break l };
            case (?n) {
                if (not isRed(?n)) nrBlack += 1;
                current := n.2;
            };
        };
    };
    _isBalanced(t, nrBlack);
};

var tree : ?RBTree.Node = null;

func insert(n : Nat8) {
    let kv = [n];
    let (nt, ov) = RBTree.insertRoot(tree, kv, kv);
    assert (ov == null);
    assert (isBalanced(?nt));
    tree := ?nt;
};

insert(10);
insert(8);
insert(12);
insert(9);
insert(11);

let ht = RBTree.getHashTree(tree);
assert (HashTree.wellFormed(ht));
assert (
    ht == #Labeled(
        [10],
        #Fork(
            #Labeled(
                [8],
                #Fork(
                    #Empty,
                    #Labeled([9], #Leaf([9])),
                ),
            ),
            #Labeled(
                [12],
                #Fork(
                    #Labeled([11], #Leaf([11])),
                    #Empty,
                ),
            ),
        ),
    )
);