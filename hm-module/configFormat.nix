# This file copies the style of:
# <https://github.com/NixOS/nixpkgs/blob/55bf31e28e1b11574b56926d8c80f45271d696d5/pkgs/pkgs-lib/formats.nix>
{ lib, pkgs, ... }:
formatOptions@{
# Required ordering of attribute paths, required from `config`.
configOrder,
# The predicate for sorting nodes in the Hyprlang AST.
# Returns `true` if `next` should be placed before `prev`, false otherwise.
# A default `sortPred` is provided based on the `configOrder` list.
sortPred ? prev: next:
  let
    inherit (lib.hyprnix.ordering) orderOfPath;
    prevOrder = orderOfPath prev configOrder;
    nextOrder = orderOfPath next configOrder;
  in nextOrder > prevOrder,
#
... }:
let
  toConfigString = lib.generators.toHyprlang
    (removeAttrs formatOptions [ "configOrder" ] // { inherit sortPred; });
in {
  # freeformType = types.attrsOf types.anything;
  type = with lib.types;
    let
      valueType =
        oneOf [ bool number singleLineStr attrsOfValueTypes listOfValueTypes ];
      attrsOfValueTypes = attrsOf valueType;
      listOfValueTypes = listOf valueType;
    in attrsOfValueTypes;

  lib = lib.hyprnix.hyprlang;

  inherit toConfigString;
  generate = name: value: pkgs.writeText name (toConfigString value);
}
