# This example shows how to configure the size and position of vertically
# stacked monitors, taken from @spikespaz' personal configuration.
{ lib, config, ... }: {
  wayland.windowManager.hyprland.monitors =
    with config.wayland.windowManager.hyprland.monitors; {
      # This display is always present, since it's built in to the laptop.
      laptop-internal = {
        # Either `output` or `description` must be defined.
        #
        # You should probably prefer `description` because for most DRM output
        # nodes (for example `HDMI-A-1` or `DP-5`), hard-coded settings aren't
        # necessarily correct for any arbitrary monitor attached to that output.
        #
        # Your system probably also makes no guarantee that the name of the
        # DRM node is consistent between reboots or re-connections.
        #
        # Since this display is built-in, in this specific circumstance,
        # using `output = "eDP-1"` would also work fine.
        description = "Samsung Display Corp. 0x4193";
        resolution = {
          x = 2880;
          y = 1800;
        };
        # When positioning monitors, `size` is provided as a convenience.
        # For `laptop-internal`, it will be `{ x = 1920; y = 1200; }`
        # (that's `{ x = resolution.x / scale; y = resolution.y / scale; }`).
        scale = 1.5;
        refreshRate = 90;
        # The position of this monitor is calculated, taking into account its
        # own scaled size, and the scaled width and height of other monitors.
        #
        # The virtual `size` is not intended to be set explicitly.
        #
        # If the `transform` option causes a monitor to be rotated, the
        # `x` and `y` coordinates of `size` will be swapped for you.
        position = lib.mapAttrs (_: builtins.floor) {
          # Offset to be horizontally centered relative to `desktop-ultrawide`.
          x = desktop-ultrawide.position.x
            + (desktop-ultrawide.size.x - laptop-internal.size.x) / 2;
          # Vertically shifted down according to the position and scaled height
          # of `desktop-ultrawide`.
          y = desktop-ultrawide.position.y + desktop-ultrawide.size.y;
        };
        bitdepth = 10;
      };
      # This display is positioned above and center relative to
      # `laptop-internal`, in a vertical stack configuration.
      desktop-ultrawide = {
        description = "ASUSTek COMPUTER INC ASUS VG34V S8LMTF062111";
        resolution = {
          x = 3440;
          y = 1440;
        };
        refreshRate = 165;
        # This monitor's position (top-left corner) is at the origin point
        # of virtual screen space (also top-left corner).
        # The widest and top-most monitor gets the honor of being positioned
        # at the origin, because while negative coordinates are supported by
        # Hyprland, some popups and tooltips (specifically Qt) don't render
        # correctly if they're in a different quadrant from other monitors.
        position = {
          x = 0;
          y = 0;
        };
      };
      # Here is an entry that will handle arbitrary monitors,
      # setting the position to the right side of `laptop-internal`.
      default = {
        output = "";
        resolution = "preferred";
        position = lib.mapAttrs (_: builtins.floor) {
          x = laptop-internal.position.x + laptop-internal.size.x;
          y = laptop-internal.position.y;
        };
      };
    };
}
