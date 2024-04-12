import { decode } = "mo:core/encoding/Hex";
import { reconstruct } "mo:core/certified/HashTree";
import { encodeUtf8 } = "mo:base/Text";
import Debug "mo:base/Debug";

func b(t : Text) : [Nat8] = Blob.toArray(encodeUtf8(t));
func xb(t : Text) : [Nat8] = switch (decode(t)) {
    case (#ok(b)) b;
    case (#err(_)) {
        assert(false);
        [];
    };
};

assert(Hex.encode(reconstruct(#fork(
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
))) == Hex.encode(reconstruct(#fork(
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
))));
