# Cerfified Variables

The Internet Computer supports a scheme where a canister can sign a payload by
declaring a special "certified variable".

[Read more...](https://internetcomputer.org/how-it-works/response-certification/)

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
