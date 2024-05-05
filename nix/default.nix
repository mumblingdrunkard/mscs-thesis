{ pkgs, system }:
let
  typst = pkgs.typst;
  lib = pkgs.lib;
  d2 = pkgs.d2;
  tala = import ./tala.nix { inherit pkgs system; };
in
pkgs.stdenv.mkDerivation rec {
  pname = "mscs-thesis";
  version = "0.1.0";
  
  src = lib.sources.cleanSource ../src;
  buildInputs = [ typst d2 tala ];

  buildPhase = ''
    for f in `find . -name "*.d2" -type f`; do \
      ${d2}/bin/d2 --layout tala --theme 301 "$f" \
    ; done
    ${typst}/bin/typst compile index.typ
  '';

  installPhase = ''
    mkdir -p $out
    cp index.pdf $out/index.pdf
  '';
}
