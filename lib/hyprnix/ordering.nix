lib: _:
let
  inherit (lib.lists) findFirstIndex;
  inherit (lib.hyprnix.lists) elemsMatch;

  # Given a list of strings as `path` and a list of `patterns`,
  # return the index of the first most-specific match.
  # If no match is found, the resulting order is one more than the length of
  # `patterns`, positioning it last.
  orderOfPath = path: patterns:
    let
      exact = findFirstIndex (pattern: pattern == path) null patterns;
      inexact = findFirstIndex (pattern: elemsMatch pattern path) null patterns;
    in if exact != null then
      exact
    else if inexact != null then
      inexact
    else
      lib.length patterns;
in { # #
  inherit orderOfPath;
}
