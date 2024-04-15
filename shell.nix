{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell rec {
  inputsFrom = [ (pkgs.callPackage ./default.nix { }) ];
  buildInputs = [ pkgs.typst-lsp ];
}
