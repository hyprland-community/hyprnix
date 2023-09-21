lib: lib0:
let
  libAttrs = lib.pipe ./. [
    (dir:
      lib.importDir dir
      (name: type: !(type == "regular" && name == "default.nix")))
    (lib.mapAttrs (_: fn: fn { inherit lib; }))
  ];
in lib0 // { # #
  hl = libAttrs;
}
