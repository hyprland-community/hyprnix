# This file is not to be considered example code.
# It is responsible for instantiating the example modules, which are siblings
# of this file, for the sake of using them as flake checks.
#
# `npins` is used to lock the inputs which are used to instantiate
# a matrix of checks. Users should stick to the flake inputs interface.
{ system, hyprnix }:
let
  # TODO: In the future, module checks should be instantiated for both
  # stable and unstable pairs of `nixpkgs` and `home-manager`.
  # Currently only the unstable branches of each is pinned,
  # because that is all that is currently used.
  sources = import ./npins;
  inherit (sources) nixpkgs;
  home-manager = import sources.home-manager {
    pkgs = import nixpkgs { localSystem.system = system; };
  };

  mkExampleHome = system: exampleModule:
    home-manager.lib.homeManagerConfiguration {
      modules = [
        {
          home.stateVersion = "25.11";
          home.username = "example";
          home.homeDirectory = "/home/example";
        }
        ({ lib, ... }: {
          imports = [ hyprnix.homeManagerModules.hyprland ];
          wayland.windowManager.hyprland.enable = true;
          # This is specified to avoid building twice; these examples are meant
          # to verify functionality of the Home Manager module only.
          wayland.windowManager.hyprland.package =
            lib.mkDefault hyprnix.packages.${system}.hyprland;
        })
        exampleModule
      ];
      pkgs = import nixpkgs {
        localSystem.system = system;
        overlays = [ hyprnix.overlays.default ];
      };
    };
in {
  # This example has an empty module (`{ }`) because it is only intended to
  # check the generation of a minimal/default configuration.
  hyprland-enable = (mkExampleHome system { }).activationPackage;
}
