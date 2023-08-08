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

  outputs = inputs@{ self, hyprland, hyprland-protocols, hyprland-xdph, ... }:
    let
      lib = inputs.birdos.lib.extend (import ./lib.nix);
      systems = [ "x86_64-linux" ];
      eachSystem = lib.genAttrs systems;
      # pkgsFor =
      #   lib.genAttrs systems (system: import nixpkgs { localSystem = system; });
    in {
      # TODO
      inherit (hyprland) packages;

      # The most important overlys are re-exported from this flake.
      # This flake's `default` overlay contains minimum required overlays.
      # Other overlays can be accessed through
      # `inputs.hyprland-nix.inputs.<flake-name>.overlays.<overlay-name>`.
      overlays = {
        inherit (hyprland.overlays)
          hyprland-packages hyprland-extras waybar-hyprland wlroots-hyprland;
        inherit (hyprland-xdph.overlays)
          xdg-desktop-portal-hyprland hyprland-share-picker;
      } // {
        default = lib.mkJoinedOverlays (with self.overlays; [
          hyprland-packages
          hyprland-extras
        ]);
      };

      homeManagerModules = {
        default = self.homeManagerModules.hyprland;
        hyprland = import ./hm-module;
      };

      formatter = eachSystem (system: inputs.nixfmt.packages.${system}.default);

      # This is good if you use the `packages` output. If these settings
      # are accepted, you can use the binary cache for packages locked
      # and built for upstream repositories.
      inherit (hyprland) nixConfig;
    };
}
