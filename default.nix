{ pkgs ? import <nixpkgs> { } }:
let
  typst = pkgs.typst;
  lib = pkgs.lib;
in
pkgs.stdenv.mkDerivation rec {
  pname = "mumblingdrunkard.com/master's-thesis";
  version = "0.1.0";
  buildPhase = ''
    $typst/bin/typst thesis.typ
  '';
  installPhase = ''
  '';
  src = lib.sources.cleanSource ./;
}
