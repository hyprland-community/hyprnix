lib: _:
let
  # Given `pattern` as a list of regular expressions, and `list` as a list of strings,
  # check that the `list` matches the `pattern`.
  # Always returns `false` if the `list` and `pattern` are different lengths.
  elemsMatch = pattern: list:
    lib.length pattern == lib.length list
    && lib.all ({ fst, snd }: builtins.match fst snd != null)
    (lib.zipLists pattern list);
in { # #
  inherit elemsMatch;
}
