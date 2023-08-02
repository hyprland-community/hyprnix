{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/hyprland";
    nixfmt.url = "github:serokell/nixfmt";
    birdos.url = "github:spikespaz/dotfiles";
  };

  outputs = inputs@{ self, ... }:
    let
      lib = inputs.birdos.lib;
      systems = [ "x86_64-linux" ];
      eachSystem = lib.genAttrs systems;
      # pkgsFor =
      #   lib.genAttrs systems (system: import nixpkgs { localSystem = system; });
    in {
      formatter = eachSystem (system: inputs.nixfmt.packages.${system}.default);
    };
}
