{
  description = "A very basic flake";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-20.09";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      testIdr = import ./test.nix { idris2 = pkgs.idris2; stdenv = pkgs.stdenv; };
      in {
        packages.test-idr = testIdr;

        devShell = pkgs.mkShell { buildInputs = [ testIdr ]; };
      });
}
