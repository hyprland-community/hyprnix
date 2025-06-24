lib: lib0:
let libAttrs = lib.mapAttrs (_: fn: fn lib lib0) (lib.importDir ./hyprnix null);
in lib0 // {
  hyprnix = libAttrs;
  generators = lib0.generators or { } // {
    toHyprlang = lib.hyprnix.hyprlang.toConfigString;
  };
}
