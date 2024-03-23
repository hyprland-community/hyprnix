self:
{ ... }: {
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
}
