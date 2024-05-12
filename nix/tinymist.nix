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
  version = "0.11.8";

  src = builtins.fetchurl {
    url = "https://github.com/Myriad-Dreamin/tinymist/releases/download/v${version}/tinymist-${tinymist-system}";
    sha256 = "09qgqwyhjm0qh8nkx6spb1fmidxgdxwvnds73v9vkzk0vm2ijbd1";
  };

  # nativeBuildInputs = [ pkgs.installShellFiles ];
  phases = [ "installPhase" ];
  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/tinymist
    chmod +x $out/bin/tinymist
  '';

  meta = with lib; {
    description = "TALA Layout Engine plugin for D2";
    homepage = "https://terrastruct.com/tala";
    license = licenses.unfree;
  };
}
