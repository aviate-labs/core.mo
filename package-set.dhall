let Package = { name : Text, version : Text, repo : Text, dependencies : List Text }
in  [
    { name = "base"
    , repo = "https://github.com/dfinity/motoko-base"
    , version = "6f49e5f877742b79e97ef1b6f226a7f905ba795c" -- v0.11.1
    , dependencies = [] : List Text
    }
] : List Package
