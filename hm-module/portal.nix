{ self, lib, ... }:
{ config, pkgs, ... }:
let
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland.portal;

  # If the overlay is applied to Nixpkgs, `xdg-desktop-portal-hyprland` in
  # `pkgs` is probably newer. Otherwise, the package provided by the flake is
  # guaranteed to be newer.
  defaultPackage = let
    inNixpkgs = pkgs.xdg-desktop-portal-hyprland.version;
    inFlake = self.packages.${pkgs.system}.xdg-desktop-portal-hyprland.version;
  in if lib.versionOlder inNixpkgs inFlake then
    pkgs.xdg-desktop-portal-hyprland
  else
    self.packages.${pkgs.system}.xdg-desktop-portal-hyprland;
in {
  options = {
    wayland.windowManager.hyprland.portal = {
      enable = lib.mkOption {
        type = types.bool;
        example = true;
        description = ''
          Whether to enable {option}`xdg.portal.enable` and configure
          to use `xdg-desktop-portal-hyprland`.

          ::: {.note}
          Enabling this option only configures XDPH, but does not
          change {option}`xdg.portal.config` or add any fallback implementations
          to {option}`xdg.portal.extraPortals`. Thus, you still need to configure
          other portals to handle other interfaces such as
          `org.freedesktop.impl.portal.FileChooser`.
          :::

          See {manpage}`portals.conf(5)` and <https://wiki.archlinux.org/title/XDG_Desktop_Portal>.
        '';
      };

      package = lib.mkOption {
        type = types.package;
        default = defaultPackage;
        defaultText = ''
          The package with the highest version number, chosen from:
          - `pkgs.xdg-desktop-portal-hyprland` (if the overlay is used, always this)
          - `self.packages.''${pkgs.system}.xdg-desktop-portal-hyprland`, from the Hyprnix flake.
        '';
        example = lib.literalExpression ''
          pkgs.xdg-desktop-portal-hyprland # if you use the overlay
        '';
        description = ''
          The XDPH package to use. This package's `hyprland` input will be overridden
          with {option}`wayland.windowManager.hyprland.finalPackage` to ensure
          that the wrapper will add the correct version of `hyprctl` to `PATH`.
        '';
      };

      finalPackage = lib.mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          The final XDPH package to install, with necessary overrides applied.
        '';
      };

      config = lib.mkOption {
        # If this ever gets more complicated, just instantiate `configFormat.nix`.
        type = with types;
          let
            valueType = oneOf [ bool number singleLineStr attrsOfValueTypes ];
            attrsOfValueTypes = attrsOf valueType;
          in attrsOfValueTypes;
        default = { };
        description = ''
          XDPH configuration attributes.

          This will be serialized to Hyprlang at
          {path}`$XDG_CONFIG_HOME/hypr/xdph.conf`.

          ::: {.note}
          The configuration file will be generated as long as this option
          has been set to some meaningful value. It is not dependent upon
          {option}`wayland.windowManager.hyprland.portal.enable`.
          :::

          For available options, see <https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland/#configuration>.
        '';
      };
    };
  };

  config = lib.mkMerge [
    {
      # If the Hyprland package is `null`, it is assumed that the user is configuring
      # things using NixOS options (discouraged). We leave it up to them whether
      # they want Home Manager to configure the portal implementations.
      wayland.windowManager.hyprland.portal.enable =
        lib.mkDefault (config.wayland.windowManager.hyprland.package != null);

      wayland.windowManager.hyprland.portal.finalPackage =
        cfg.package.override {
          hyprland = config.wayland.windowManager.hyprland.finalPackage;
        };
    }
    (lib.mkIf cfg.enable {
      xdg.portal = {
        enable = lib.mkDefault true;
        extraPortals = [ cfg.finalPackage ];
        configPackages = [ config.wayland.windowManager.hyprland.finalPackage ];
      };
    })
    (lib.mkIf (cfg.config != { }) {
      wayland.windowManager.hyprland.configFile."xdph.conf".text =
        lib.generators.toHyprlang
        config.wayland.windowManager.hyprland.configFormatOptions cfg.config;
    })
  ];
}
