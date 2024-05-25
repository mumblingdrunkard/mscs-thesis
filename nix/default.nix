{ pkgs, system }:
let
  typst = pkgs.typst;
  lib = pkgs.lib;
  d2 = pkgs.d2;
  tala = pkgs.callPackage ./tala.nix { };
  fonts = pkgs.callPackage ./fonts.nix { };
in
pkgs.stdenv.mkDerivation rec {
  pname = "mscs-thesis";
  version = "0.1.0";
  
  src = lib.sources.cleanSource ../src;
  buildInputs = [ typst d2 tala fonts ];

  buildPhase = ''
    export PATH=$PATH:${d2}/bin
    export TYPST_FONT_PATHS=${fonts}/ttf
    ./build-diagrams.sh
    ${typst}/bin/typst compile index.typ
  '';

  installPhase = ''
    mkdir -p $out
    cp index.pdf $out/${pname}-${version}.pdf
  '';
}
