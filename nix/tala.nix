{ pkgs ? import <nixpkgs> { }, system }:
let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
  tala-system = 
    if system == "x86_64-linux" then "linux-amd64"
    else if system == "aarch64-linux" then "linux-arm64" else "unknown";
in
stdenv.mkDerivation rec {
  pname = "d2plugin-tala";
  version = "0.3.14";

  src = fetchTarball {
    # https://github.com/terrastruct/TALA/releases/download/v0.3.14/tala-v0.3.14-linux-amd64.tar.gz
    url = "https://github.com/terrastruct/TALA/releases/download/v${version}/tala-v${version}-${tala-system}.tar.gz";
    sha256 = "08n8y1k2h2ncrgwvklja58zhizmsdw018k8jqhvi1qbkp4qcjmk6";
  };

  nativeBuildInputs = [ pkgs.installShellFiles ];
  phases = [ "installPhase" ];
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
