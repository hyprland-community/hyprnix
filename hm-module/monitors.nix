self:
{ config, ... }:
let
  inherit (self.lib) lib;
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland.monitors;
in {
  options = {
    wayland.windowManager.hyprland.monitors = lib.mkOption {
      type = types.attrsOf (types.submodule ({ config, ... }: {
        options = {
          name = lib.mkOption {
            type = types.singleLineStr;
            description = ''
              The name of the monitor as shown in the output of
              `hyprctl monitors`, for example `eDP-1` or `HDMI-A-1`.
            '';
          };
          x = lib.mkOption {
            type = types.nullOr types.ints.unsigned;
            default = null;
            description = ''
              The horizontal position of this monitor, offset
              from the top-left of virtual screen space.
            '';
          };
          y = lib.mkOption {
            type = types.nullOr types.ints.unsigned;
            default = null;
            description = ''
              The vertical position of this monitor, offset
              from the top-left of virtual screen space.
            '';
          };
          position = lib.mkOption {
            type = types.singleLineStr;
            default = "auto";
            description = ''
              The position of the monitor, as a string
              (Hyprland keyword value parameter).
            '';
          };
          width = lib.mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = ''
              The physical width of the display, in pixels.
            '';
          };
          height = lib.mkOption {
            type = types.nullOr types.ints.positive;
            default = null;
            description = ''
              The physical height of the display, in pixels.
            '';
          };
          size = lib.mkOption {
            type = types.singleLineStr;
            default = "preferred";
            description = ''
              The physical size of the display, as a string, to pass
            '';
          };
          scale = lib.mkOption {
            type = types.float;
            default = 1.0;
            description = ''
              The fractional scaling factor to use for Wayland-native programs.
              The virtual size of the display will be each dimension divided by
              this float. For example, the virtual size of a monitor with a physical
              size of 2880x1800 pixels would be 1920x1200 virtual pixels.
            '';
          };
        };

        config = {
          position = lib.mkIf (config.x != null && config.y != null)
            (lib.mkDefault "${toString config.x}x${toString config.y}");
          size = lib.mkIf (config.width != null && config.height != null)
            (lib.mkDefault
              "${toString config.width}x${toString config.height}");
        };
      }));
      description = ''
        Monitors to configure. The attribute name is not used in the
        Hyprland configuration, but is a convenience for recursive Nix.

        The "name" the monitor will have (the connector, not make and model)
        is specified in the `name` attribute for the monitor.
        It is not the attribute name of the monitor in *this* parent set.
      '';
      example = lib.literalExpression ''
        (with config.wayland.windowManager.hyprland.monitors; {
          # The attribute name `internal` is for usage in recursive Nix.
          internal = {
            name = "eDP-1";
            position = "auto"; # `auto` is default
            size = "preferred"; # `preferred` is default
            bitdepth = 10;
          };
        })
      '';
      default = { };
    };
  };

  config = {
    wayland.windowManager.hyprland.config.monitor = lib.mapAttrsToList
      (attrName:
        { name, position, size, scale, bitdepth, ... }:
        lib.concatStringsSep "," [
          name
          size
          position
          (toString scale)
        ]) cfg;
  };
}
