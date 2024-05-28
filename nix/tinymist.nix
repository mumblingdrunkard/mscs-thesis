{ pkgs ? import <nixpkgs> { }, system }:
let
  stdenv = pkgs.stdenv;
  lib = pkgs.lib;
  tinymist-system = 
    if system == "x86_64-linux" then "linux-x64"
    else if system == "aarch64-linux" then "linux-arm64" else "unknown";
in
stdenv.mkDerivation rec {
  pname = "tinymist";
  version = "0.11.9";

  src = builtins.fetchurl {
    url = "https://github.com/Myriad-Dreamin/tinymist/releases/download/v${version}/tinymist-${tinymist-system}";
    sha256 = "15g4ijir66ql2y0njm7zp10hbl218d0v2b294ncligcz6107532f";
  };

  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/tinymist
    chmod +x $out/bin/tinymist
  '';
}
