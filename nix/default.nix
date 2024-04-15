{ pkgs ? import <nixpkgs> { } }:
let
  typst = pkgs.typst;
  lib = pkgs.lib;
in
pkgs.stdenv.mkDerivation rec {
  pname = "mumblingdrunkard.com/master's-thesis";
  version = "0.1.0";
  tala = pkgs.callPackage ./tala.nix {};
  buildInputs = [ typst pkgs.d2 tala ];
  buildPhase = ''
    ${typst}/bin/typst compile ./thesis.typ
  '';
  installPhase = ''
    mkdir -p $out/doc
    cp thesis.pdf $out/doc/thesis.pdf
  '';
  src = lib.sources.cleanSource ./.;
}
