{ testIdr, mkShell }:
mkShell {
  buildInputs = [ idrTest ];
}
