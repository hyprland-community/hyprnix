{
  description = ''
    A Nix flake for the Hyprland window manager.
    <https://github.com/hyprwm/hyprland>
  '';

  inputs = {
    nixpkgs.follows = "hyprland/nixpkgs";

    # <https://github.com/nix-systems/nix-systems>
    systems.url = "github:nix-systems/default-linux";

    # <https://github.com/hyprwm/Hyprland/blob/main/flake.nix>
    hyprland = {
      url = "github:hyprwm/hyprland";
      inputs.systems.follows = "systems";
    };

    # Extensions to `nixpkgs.lib` required by the Hyprlang serializer.
    # <https://github.com/spikespaz/bird-nix-lib>
    bird-nix-lib = {
      url = "github:spikespaz/bird-nix-lib";
      inputs.systems.follows = "systems";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, systems, hyprland, bird-nix-lib }:
    let
      inherit (self) lib;
      eachSystem = lib.genAttrs (import systems);
    in {
      lib = let
        overlay = nixpkgs.lib.composeManyExtensions [
          bird-nix-lib.lib.overlay
          (import ./lib)
        ];
      in nixpkgs.lib.extend overlay // { inherit overlay; };

      # Packages with the `-cross` suffix are removed,
      # prefer using `--all-systems` and providing remote builders which have `binfmt` configured.
      # For GitHub CI, use an `aarch64` runner.
      packages = lib.mapAttrs
        (name: lib.filterAttrs (name: _: !(lib.hasSuffix "-cross" name)))
        hyprland.packages;

      overlays = hyprland.overlays;

      homeManagerModules = {
        default = self.homeManagerModules.hyprland;
        hyprland = import ./hm-module self;
      };

      checks = eachSystem (system:
        let pkgs = import nixpkgs { localSystem = system; };
        in self.packages.${system} // {
          check-formatting = pkgs.stdenvNoCC.mkDerivation {
            name = "check-formatting";
            src = ./.;
            phases = [ "checkPhase" "installPhase" ];
            doCheck = true;
            nativeCheckInputs = [ self.formatter.${system} ];
            checkPhase = ''
              cd $src
              echo 'Checking Nix code formatting with Nixfmt:'
              nixfmt --check .
            '';
            installPhase = "touch $out";
          };
        });

      formatter =
        eachSystem (system: nixpkgs.legacyPackages.${system}.nixfmt-classic);

      # Should be kept in sync with upstream.
      # <https://github.com/hyprwm/Hyprland/blob/1925e64c21811ce76e5059d7a063f968c2d3e98c/flake.nix#L98-L101>
      nixConfig = {
        extra-substituters = [ "https://hyprland.cachix.org" ];
        extra-trusted-public-keys = [
          "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        ];
      };
    };
}
