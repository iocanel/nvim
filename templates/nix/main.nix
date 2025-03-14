{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {

  buildInputs = with pkgs; [
    fish
  ];

  shellHook = ''
    exec fish
  '';
}
