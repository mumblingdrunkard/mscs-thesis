{ pkgs, system }:
let
  fonts = pkgs.callPackage ./fonts.nix { };
in 
pkgs.mkShell {
  inputsFrom = [
    (pkgs.callPackage ./default.nix { })
  ];
  buildInputs = [
    (pkgs.callPackage ./tinymist.nix {})
  ];
  TYPST_FONT_PATHS="${fonts}/ttf";
}
