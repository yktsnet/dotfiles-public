{ pkgs, ... }:

{
  imports = [
    ../../home.nix
    ../../../../home-manager/modules/spotifyd.nix
    ./spotifyd.nix
  ];
}
