lib: _:
let
  inherit (lib.hyprnix.lists) elemsMatch;

  # Given a list of strings as `path` and a list of `patterns`,
  # return the index of the first most-specific match.
  # If no match is found, the resulting order is one more than the length of
  # `patterns`, positioning it last.
  orderOfPath = path: patterns:
    let
      recurse = prior: index: patterns:
        if lib.length patterns == 0 then
          if prior != null then prior else index
        else if lib.head patterns == path then
          index
        else if prior == null && elemsMatch (lib.head patterns) path then
          recurse index (index + 1) (lib.tail patterns)
        else
          recurse prior (index + 1) (lib.tail patterns);
    in recurse null 0 patterns;
in { # #
  inherit orderOfPath;
}
