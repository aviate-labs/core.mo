import { decode } = "mo:core/encoding/Hex";
import { encodeCBOR; reconstruct; wellFormed } "mo:core/certified/HashTree";
import { encodeUtf8 } = "mo:base/Text";

func b(t : Text) : [Nat8] = Blob.toArray(encodeUtf8(t));
func xb(t : Text) : [Nat8] = switch (decode(t)) {
    case (#ok(b)) b;
    case (#err(_)) {
        assert(false);
        [];
    };
};

let prunedTree = #fork(
    #fork(
        #labeled(b("a"), #fork(
            #pruned(xb("1b4feff9bef8131788b0c9dc6dbad6e81e524249c879e9f10f71ce3749f5a638")),
            #labeled(b("y"), #leaf(b("world"))),
        )),
        #labeled(b("b"), #pruned(xb("7b32ac0c6ba8ce35ac82c255fc7906f7fc130dab2a090f80fe12f9c2cae83ba6"))),
    ),
    #fork(
        #pruned(xb("ec8324b8a1f1ac16bd2e806edba78006479c9877fed4eb464a25485465af601d")),
        #labeled(b("d"), #leaf(b("morning"))),
    ),
);

let tree = #fork(
    #fork(
        #labeled(b("a"), #fork(
            #fork(
                #labeled(b("x"), #leaf(b("hello"))),
                #empty,
            ),
            #labeled(b("y"), #leaf(b("world"))),
        )),
        #labeled(b("b"), #leaf(b("good"))),
    ),
    #fork(
        #labeled(b("c"), #empty),
        #labeled(b("d"), #leaf(b("morning"))),
    ),
);

assert(wellFormed(prunedTree));
assert(wellFormed(tree));
assert(not wellFormed(#fork(#leaf(b("a")), #empty)));

assert(Hex.encode(reconstruct(prunedTree)) == "eb5c5b2195e62d996b84c9bcc8259d19a83786a2f59e0878cec84c811f669aa0");
assert(Hex.encode(reconstruct(prunedTree)) == Hex.encode(reconstruct(tree)));

assert(Hex.encode(encodeCBOR(tree)) == "8301830183024161830183018302417882034568656c6c6f810083024179820345776f726c6483024162820344676f6f648301830241638100830241648203476d6f726e696e67");
assert(Hex.encode(encodeCBOR(prunedTree)) == "83018301830241618301820458201b4feff9bef8131788b0c9dc6dbad6e81e524249c879e9f10f71ce3749f5a63883024179820345776f726c6483024162820458207b32ac0c6ba8ce35ac82c255fc7906f7fc130dab2a090f80fe12f9c2cae83ba6830182045820ec8324b8a1f1ac16bd2e806edba78006479c9877fed4eb464a25485465af601d830241648203476d6f726e696e67");
