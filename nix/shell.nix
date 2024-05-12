{ pkgs, system }:
pkgs.mkShell rec {
  inputsFrom = [ (pkgs.callPackage ./default.nix { }) ];
  buildInputs = [ (pkgs.callPackage ./tinymist.nix {}) ];
}
