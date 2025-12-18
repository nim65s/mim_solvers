{
  description = "Implementation of numerical solvers used in the Machines in Motion Laboratory";

  inputs = {
    gepetto.url = "github:gepetto/nix";
    flake-parts.follows = "gepetto/flake-parts";
    nixpkgs.follows = "gepetto/nixpkgs";
    nix-ros-overlay.follows = "gepetto/nix-ros-overlay";
    systems.follows = "gepetto/systems";
    treefmt-nix.follows = "gepetto/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, self, ... }:
      {
        systems = inputs.nixpkgs.lib.systems.flakeExposed;
        imports = [
          inputs.gepetto.flakeModule
          { gepetto-pkgs.overlays = [ self.overlays.default ]; }
        ];
        flake.overlays.default = _final: prev: {
          mim-solvers = prev.mim-solvers.overrideAttrs {
            patches = [ ];
            src = lib.fileset.toSource {
              root = ./.;
              fileset = lib.fileset.unions [
                ./benchmarks
                ./bindings
                ./examples
                ./include
                ./python
                ./src
                ./tests
                ./CMakeLists.txt
                ./package.xml
              ];
            };
          };
        };
        perSystem =
          { pkgs, self', ... }:
          {
            apps.default = {
              type = "app";
              program = pkgs.python3.withPackages (_: [ self'.packages.default ]);
            };
            packages = {
              default = self'.packages.mim-solvers;
              mim-solvers = pkgs.python3Packages.mim-solvers.override { buildStandalone = false; };
            };
          };
      }
    );
}
