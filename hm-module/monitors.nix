{ lib, ... }:
{ config, ... }:
let
  inherit (lib) types;

  cfg = config.wayland.windowManager.hyprland.monitors;

  mkIntEnum = mapping: {
    inherit mapping;
    # Given `needle`, which is either the variant name or an integer value,
    # return the corresponding variant name.
    variantName = needle:
      (lib.findFirst ({ name, value }: needle == name || needle == value) null
        (lib.attrsToList mapping)).name;
    # Given `needle`, which is either the variant name or an integer value,
    # return the corresponding integer value.
    variantValue = needle:
      (lib.find ({ name, value }: needle == name || needle == value) null
        (lib.attrsToList mapping)).value;
    type =
      types.enum (builtins.attrValues mapping ++ builtins.attrNames mapping);
    apply = x: if lib.isString x then mapping.${x} else x;
  };

  # See docs of option `transform`.
  transformEnum = mkIntEnum {
    "Normal" = 0;
    "Degrees90" = 1;
    "Degrees180" = 2;
    "Degrees270" = 3;
    "Flipped" = 4;
    "FlippedDegrees90" = 5;
    "FlippedDegrees180" = 6;
    "FlippedDegrees270" = 7;
  };

  # See docs of option `vrrMode`.
  vrrModeEnum = mkIntEnum {
    "default" = null;
    "on" = 1;
    "off" = 0;
    "fullscreen" = 2;
  };

  # For position and resolution.
  point2DType = numType:
    types.submodule {
      options = {
        x = lib.mkOption {
          type = numType;
          description =
            "The X-coordinate of a point, or the width of a rectangle.";
        };
        y = lib.mkOption {
          type = numType;
          description =
            "The Y-coordinate of a point, or the height of a rectangle.";
        };
      };
    };

  monitorDefType = types.submodule ({ config, ... }: {
    options = {
      name = lib.mkOption {
        type = types.singleLineStr;
        description = ''
          The name of the monitor as shown in the output of
          `hyprctl monitors`, for example `eDP-1` or `HDMI-A-1`.
        '';
      };
      description = lib.mkOption {
        type = types.nullOr types.singleLineStr;
        default = null;
        description = ''
          The description of a monitor as shown in the output of
          `hyprctl monitors` (without the parenthesized name at the end).
        '';
      };
      position = lib.mkOption {
        type = types.either (point2DType types.ints.unsigned) (types.enum [
          "auto"
          "auto-up"
          "auto-down"
          "auto-left"
          "auto-right"
          "auto-center-up"
          "auto-center-down"
          "auto-center-left"
          "auto-center-right"
        ]);
        default = "auto";
        description = ''
          The position of the monitor as `{ x, y }` attributes,
          or the name of some automatic behavior.

          ::: {.note}
          Coordinates are offsets relative to the top-left corner of virtual
          screen space.
          :::
        '';
      };
      resolution = lib.mkOption {
        type = types.either (point2DType types.ints.positive)
          (types.enum [ "preferred" "highrr" "highres" "maxwidth" ]);
        default = "preferred";
        description = ''
          The physical size of the display as `{ x, y }` attributes,
          or the name of some automatic behavior.

          ::: {.note}
          If you want define your `position` attributes relative to
          each other, use the value of {option}`scale` recursively.
          :::
        '';
      };
      scale = lib.mkOption {
        type = types.either types.float (types.enum [ "auto" ]);
        default = 1.0;
        description = ''
          The fractional scaling factor to use for Wayland-native programs.
          The virtual size of the display will be each dimension divided by
          this float. For example, the virtual size of a monitor with a physical
          size of 2880x1800 pixels would be 1920x1200 virtual pixels.
        '';
      };
      refreshRate = lib.mkOption {
        type = types.nullOr (types.either types.ints.positive types.float);
        default = null;
        description = ''
          The refresh rate of the monitor, if unspecified will choose
          a default mode for your specified resolution.
        '';
      };
      vrrMode = lib.mkOption {
        inherit (vrrModeEnum) type apply;
        default = null;
        description = ''
          Whether to enable variable refresh rate (FreeSync/AdaptiveSync/GSync).
          This option is specifically for a monitor. There is a global option also,
          `null`/`default` is for deferring.
        '';
      };
      bitdepth = lib.mkOption {
        type = types.enum [ 8 10 ];
        default = 8;
        description = ''
          The color bit-depth of the monitor (8-bit or 10-bit color).
        '';
      };
      transform = lib.mkOption {
        inherit (transformEnum) type apply;
        default = "Normal";
        description = ''
          Attribute names (enum identifiers) and values (repr) from the
          following ~~enum~~ attribute set are accepted as variants
          in this option `lib.types.enum`.

          ```nix
          ${lib.generators.toPretty { multiline = true; } transformEnum.mapping}
          ```
        '';
      };
      mirror = lib.mkOption {
        type = types.nullOr types.singleLineStr;
        default = null;
        description = "The name of the monitor to mirror.";
        example = lib.mdDoc ''
          The "name" of the monitor is after the display protocol
          it is connected with: `eDP-1`, `HDMI-A-1`, `DP-5`, `DP-6`, etc.
        '';
      };

      size = lib.mkOption {
        type = types.nullOr (point2DType types.float);
        readOnly = true;
        description = ''
          The virtual display size after scaling,
          intended for use in recursive Nix configurations.

          This value can be `null` if {option}`resolution` is not an
          attribute set of coordinates.
        '';
      };
      modeString = lib.mkOption {
        type = types.singleLineStr;
        readOnly = true;
        internal = true;
      };
      positionString = lib.mkOption {
        type = types.singleLineStr;
        readOnly = true;
        internal = true;
      };
      keywordParams = lib.mkOption {
        type = types.listOf types.singleLineStr;
        internal = true;
      };
    };

    config = let
      positionIsPoint = (point2DType types.ints.unsigned).check config.position;
      resolutionIsPoint =
        (point2DType types.ints.positive).check config.resolution;
    in {
      name = lib.mkIf (config.description != null) "desc:${config.description}";

      size = if resolutionIsPoint then
        let
          transform = transformEnum.variantName config.transform;
          horizontal = {
            x = config.resolution.x / config.scale;
            y = config.resolution.y / config.scale;
          };
          vertical = {
            x = horizontal.y;
            y = horizontal.x;
          };
          lut = {
            "Normal" = horizontal;
            "Degrees90" = vertical;
            "Degrees180" = horizontal;
            "Degrees270" = vertical;
            "Flipped" = horizontal;
            "FlippedDegrees90" = vertical;
            "FlippedDegrees180" = horizontal;
            "FlippedDegrees270" = vertical;
          };
        in lut.${transform}
      else
        null;

      modeString = if resolutionIsPoint then
      # The resolution in `WIDTHxHEIGHT@REFRESH`, with `@REFRESH` optionally.
        "${toString config.resolution.x}x${toString config.resolution.y}${
          lib.optionalString (config.refreshRate != null)
          "@${toString config.refreshRate}"
        }"
      else
      # The resolution verbatim if it is an enum string.
        config.resolution;

      positionString = if positionIsPoint then
      # The position in `XxY` format if it is a point.
        "${toString config.position.x}x${toString config.position.y}"
      else
      # The position verbatim if it is an enum string.
        config.position;

      keywordParams = lib.concatLists [
        [
          config.name
          config.modeString
          config.positionString
        ]

        #
        [ (toString config.scale) ]
        [ "bitdepth" (toString config.bitdepth) ]
        (lib.optionals (config.vrrMode != null) [
          "vrr"
          (toString config.vrrMode)
        ])
        [ "transform" (toString config.transform) ]
        (lib.optionals (config.mirror != null) [ "mirror" config.mirror ])
        #
      ];
    };
  });
in {
  options = {
    wayland.windowManager.hyprland.monitors = lib.mkOption {
      type = types.attrsOf monitorDefType;
      default = { };
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
            pos = "auto"; # `auto` is default
            size = "preferred"; # `preferred` is default
            bitdepth = 10;
          };
        })
      '';
    };
  };

  config = {
    wayland.windowManager.hyprland.config.monitor = lib.mapAttrsToList
      (attrName: monitor: lib.concatStringsSep "," monitor.keywordParams) cfg;
  };
}
