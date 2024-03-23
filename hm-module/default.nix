self:
{ config, lib, pkgs, ... }:
let
  inherit (self.lib) lib;
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland;
in {
  disabledModules = [
    # module in Home Manager conflicts with this one
    "services/window-managers/hyprland.nix"
  ];

  imports = [
    (import ./events.nix self)
    (import ./config.nix self)
    (import ./environment.nix self)
    (import ./rules.nix self) # windowrulev2, layerrule, workspace
    (import ./animations.nix self)
    (import ./keybinds.nix self)
    (import ./monitors.nix self)
  ];

  options = let
    configFile = basePath:
      types.submodule ({ config, name, ... }: {
        options = {
          target = lib.mkOption {
            type = types.singleLineStr;
            readOnly = true;
          };
          source = lib.mkOption {
            type = types.path;
            default = null;
          };
          text = lib.mkOption {
            type = types.nullOr types.lines;
            default = null;
          };
          executable = lib.mkOption {
            type = types.bool;
            default = false;
          };
        };
        config = {
          target = name;
          source = lib.mkIf (config.text != null) (pkgs.writeTextFile {
            name = "${basePath}/${config.target}";
            destination = "/${config.target}";
            inherit (config) text executable;
          });
        };
      });
  in {
    wayland.windowManager.hyprland = {
      configFile = lib.mkOption {
        type = types.attrsOf (configFile "${config.xdg.configHome}/hypr");
        default = { };
        description = lib.mdDoc ''
          Configuration files and directories to link in the Hyprland config directory.
          This is an attribute set of file descriptions similar to
          {option}`xdg.configFile`, except relative to {path}`$XDG_CONFIG_HOME/hypr`.

          If necessary, you may set {option}`xdg.configFile."hypr".recursive = true`.
        '';
      };
      configPackage = lib.mkOption {
        type = types.package;
        readOnly = true;
      };
    };
  };

  config = lib.mkMerge [
    {
      wayland.windowManager.hyprland.configPackage = pkgs.symlinkJoin {
        name = "hyprland-config";
        paths = lib.mapAttrsToList (_: file: file.source) cfg.configFile;
      };
    }
    (lib.mkIf cfg.enable { xdg.configFile."hypr".source = cfg.configPackage; })
  ];
}
