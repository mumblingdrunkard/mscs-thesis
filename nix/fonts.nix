{ pkgs ? import <nixpkgs> { }, fetchzip }:
let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
in
stdenv.mkDerivation rec {
  pname = "fira-code";
  version = "6.2";

  src = fetchzip {
    url = "https://github.com/tonsky/FiraCode/releases/download/${version}/Fira_Code_v${version}.zip";
    sha256 = "UHOwZL9WpCHk6vZaqI/XfkZogKgycs5lWg1p0XdQt0A=";
    stripRoot = false;
  };

  installPhase = ''
    mkdir -p $out/ttf
    cp -r ttf $out/
  '';

  meta = with lib; {
    description = "FiraCode font";
    homepage = "https://github.com/tonsky/FiraCode";
    license = licenses.ofl;
  };
}
