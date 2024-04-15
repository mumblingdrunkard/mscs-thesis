{ pkgs ? import <nixpkgs> { } }:
let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
in
stdenv.mkDerivation rec {
  pname = "d2plugin-tala";
  version = "0.3.13";

  src = fetchTarball {
    # https://github.com/terrastruct/TALA/releases/download/v0.3.13/tala-v0.3.13-linux-amd64.tar.gz
    url = "https://github.com/terrastruct/TALA/releases/download/v${version}/tala-v${version}-linux-amd64.tar.gz";
    sha256 = "08n8y1k2h2ncrgwvklja58zhizmsdw018k8jqhvi1qbkp4qcjmk6";
  };

  phases = [ "installPhase" ];

  nativeBuildInputs = [ pkgs.installShellFiles ];
  installPhase = ''
    mkdir -p $out/bin
    cd $src
    install -Dm555 bin/d2plugin-tala $out/bin
  '';

  meta = with lib; {
    description = "TALA Layout Engine plugin for D2";
    homepage = "https://terrastruct.com/tala";
    license = licenses.unfree;
  };
}
