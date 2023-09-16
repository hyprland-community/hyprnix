{ lib, ... }:
let
  # Takes a list of overlays and joins them into one.
  mkJoinedOverlays = overlays: final: prev:
    lib.foldl' (attrs: overlay: attrs // (overlay final prev)) { } overlays;
in { # #
  inherit mkJoinedOverlays;
}
