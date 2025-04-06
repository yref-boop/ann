{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
        (pkgs.haskellPackages.ghcWithPackages (pkgs: with pkgs; [ 
            data-default
            statistics
            mersenne-random
        ]))
  ];
}
