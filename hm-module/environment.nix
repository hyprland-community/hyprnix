self:
{ config, lib, pkgs, ... }:
let
  inherit (self.lib) lib;
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland;
in {
  options = {
    wayland.windowManager.hyprland = {
      recommendedEnvironment = lib.mkOption {
        type = types.bool;
        default = pkgs.stdenv.isLinux;
        description = lib.mdDoc ''
          Whether to set some recommended environment variables.
        '';
      };
    };
  };

  config = lib.mkIf cfg.recommendedEnvironment {
    home.sessionVariables = { NIXOS_OZONE_WL = "1"; };
  };
}
