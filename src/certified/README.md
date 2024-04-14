# Cerfified Variables

The Internet Computer supports a scheme where a canister can sign a payload by
declaring a special "certified variable".

[Read more...](https://internetcomputer.org/how-it-works/response-certification/)

## HashTree

```motoko
import HashTree "mo:core/certified/HashTree";
```

## Interface

```motoko
module {
  encodeCBOR : HashTree -> Hash;
  reconstruct : HashTree -> Hash;
  wellFormed : HashTree -> Bool;
};
```

## RBTree

```motoko
module {
  type Node = ([Nat8], [Nat8], ?Node, ?Node, Color, Hash);
  get : (?Node, [Nat8]) -> ?[Nat8];
  getHash : ?Node -> ?Hash;
  getHashTree : ?Node -> HashTree;
  insert : (?Node, [Nat8], [Nat8]) -> (Node, ?[Nat8]);
  insertRoot : (?Node, [Nat8], [Nat8]) -> (Node, ?[Nat8]);
  newNode : ([Nat8], [Nat8]) -> Node;
};
```
