{ pkgs, ... }:

{
  imports = [
    ../../home.nix
    ./spotifyd.nix
  ];
}
