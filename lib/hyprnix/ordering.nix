lib: _:
let
  inherit (lib.hyprnix.lists) elemsMatch;

  # Given a list of strings as `path` and a list of `patterns`,
  # return the index of the first match.
  # If no match is found, the resulting order is one more than the length of
  # `patterns`, positioning it last.
  orderOfPath = path: patterns:
    let
      recurse = i: patterns:
        if lib.length patterns == 0 then
          i + 1 # no match found, order is last
        else if elemsMatch (lib.head patterns) path then
          i # a match has been found
        else
          recurse (i + 1) (lib.tail patterns);
    in recurse 0 patterns;
in { # #
  inherit orderOfPath;
}
