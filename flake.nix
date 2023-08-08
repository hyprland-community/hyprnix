{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Official `hyprwm` flakes. Re-listed here because you can `follows`
    # this flake's inputs.
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-protocols = {
      url = "github:hyprwm/hyprland-protocols";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland-xdph = {
      url = "github:hyprwm/xdg-desktop-portal-hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.hyprland-protocols.follows = "hyprland-protocols";
    };

    nixfmt.url = "github:serokell/nixfmt";
    birdos.url = "github:spikespaz/dotfiles";
  };

  outputs = inputs@{ self, hyprland, ... }:
    let
      lib = inputs.birdos.lib;
      systems = [ "x86_64-linux" ];
      eachSystem = lib.genAttrs systems;
      # pkgsFor =
      #   lib.genAttrs systems (system: import nixpkgs { localSystem = system; });
    in {
      inherit (hyprland) overlays packages nixConfig;

      homeManagerModules = {
        default = self.homeManagerModules.hyprland;
        hyprland = import ./hm-module;
      };

      formatter = eachSystem (system: inputs.nixfmt.packages.${system}.default);
    };
}
