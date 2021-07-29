{ pkgs ? import <nixpkgs> {} }:
let
  idrTest = import ./test.nix;
in
pkgs.mkShell {
  buildInputs = [ idrTest ];
}
