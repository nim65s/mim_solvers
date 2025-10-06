{
  description = "Implementation of numerical solvers used in the Machines in Motion Laboratory";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = inputs.nixpkgs.lib.systems.flakeExposed;
      perSystem =
        {
          lib,
          pkgs,
          self',
          ...
        }:
        {
          apps.default = {
            type = "app";
            program = pkgs.python3.withPackages (_: [ self'.packages.default ]);
          };
          packages = {
            default = self'.packages.py-mim-solvers;
            mim-solvers = pkgs.mim-solvers.overrideAttrs {
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
            py-mim-solvers = pkgs.python3Packages.toPythonModule (
              self'.packages.mim-solvers.overrideAttrs (super: {
                pname = "py-${super.pname}";
                postPatch = "";
                cmakeFlags = super.cmakeFlags ++ [
                  (lib.cmakeBool "BUILD_PYTHON_INTERFACE" true)
                  (lib.cmakeBool "BUILD_STANDALONE_PYTHON_INTERFACE" true)
                ];
                nativeBuildInputs = super.nativeBuildInputs ++ [
                  pkgs.python3Packages.python
                ];
                propagatedBuildInputs = [
                  pkgs.python3Packages.crocoddyl
                  pkgs.python3Packages.osqp
                  pkgs.python3Packages.proxsuite
                  pkgs.python3Packages.scipy
                  self'.packages.mim-solvers
                ]
                ++ super.propagatedBuildInputs;
                nativeCheckInputs = [
                  pkgs.python3Packages.pythonImportsCheckHook
                ];
              })
            );
          };
        };
    };
}
