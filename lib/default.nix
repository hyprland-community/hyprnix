lib: lib0:
let
  # Takes a directory and a predicate, and imports each file or directory
  # based on rules. An attribute set of the imported expressions is returned,
  # named according to each file with the `.nix` suffix removed.
  #
  # The rules for importing are:
  #  1. Is a regular file ending with `.nix`.
  #  2. Is a directory containing the regular file `default.nix`.
  #  3. Your predicate, given `name` and `type`, returns `true`.
  importDir = dir: pred:
    let
      isNix = name: type:
        (type == "regular" && lib.hasSuffix ".nix" name)
        || (lib.pathIsRegularFile "${dir}/${name}/default.nix");
    in lib.pipe dir [
      builtins.readDir
      (lib.filterAttrs (name: type: (isNix name type) && (pred name type)))
      (lib.mapAttrs' (name: _: {
        name = lib.removeSuffix ".nix" name;
        value = import "${dir}/${name}";
      }))
    ];

  libAttrs = lib.pipe ./. [
    (dir:
      importDir dir (name: type: !(type == "regular" && name == "default.nix")))
    (lib.mapAttrs (_: fn: fn { inherit lib; }))
  ];
in lib0 // { # #
  hl = libAttrs // { # #
    inherit (libAttrs.builders) mkJoinedOverlays;
  };
}
