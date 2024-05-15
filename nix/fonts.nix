{ pkgs ? import <nixpkgs> { } }:
let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
in
stdenv.mkDerivation rec {
  pname = "fira-code";
  version = "6.2";

  src = fetchzip {
    # https://github.com/terrastruct/TALA/releases/download/v0.3.14/tala-v0.3.14-linux-amd64.tar.gz
    url = "https://github.com/tonsky/FiraCode/releases/download/${version}/Fira_Code_v${version}.zip";
    sha256 = "08n8y1k2h2ncrgwvklja58zhizmsdw018k8jqhvi1qbkp4qcjmk6";
  };

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/fonts
    cp -r src/ttf $out/ttf
  '';

  meta = with lib; {
    description = "FiraCode font";
    homepage = "https://github.com/tonsky/FiraCode";
    license = licenses.ofl;
  };
}
