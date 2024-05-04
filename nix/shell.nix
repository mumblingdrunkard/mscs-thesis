{ pkgs ? import <nixpkgs> { }, system }:
let
  d2 = pkgs.d2;
  tala = import ./tala.nix { inherit pkgs system; };
in
pkgs.mkShell rec {
  inputsFrom = [ (pkgs.callPackage ./default.nix { }) ];
  buildInputs = [ pkgs.tinymist d2 tala ];
}
