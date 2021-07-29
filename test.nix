with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "test-idr";
  src = ./src;
  buildPhase = ''
    # $src/test.idr doesn't exist, test.idr is available in the cwd
    # Basically, it's like the cwd is whatever we set src to
    ${pkgs.idris2}/bin/idris2 test.idr -o tictactoe
  '';
  installPhase = ''
    # putting executables in $out/bin adds them to PATH when installed
    mkdir -p $out/bin
    mv build/exec/* $out/bin
  '';
}
