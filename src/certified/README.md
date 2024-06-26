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
  type Node = (Key, Value, ?Node, ?Node, Color, Hash);
  type Tree = ?Node;
  delete : (Tree, Key) -> (?Node, ?Value);
  deleteMin : Tree -> (?Node, ?Value);
  get : (Tree, Key) -> ?Value;
  getHash : ?Node -> ?Hash;
  getHashTree : ?Node -> HashTree;
  insert : (Tree, Key, Value) -> (Tree, ?Value);
  iter : Tree -> Iter<(Key, Value)>;
  min : Tree -> ?Node;
  newNode : (Key, Value) -> Node;
  visit : (Tree, (Key, Value) -> ()) -> ();
};
```
