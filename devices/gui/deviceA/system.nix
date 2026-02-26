{ config, pkgs, lib, ... }:

{
  imports = [
    ../system.nix
    ./hardware.nix
    ./disko.nix
  ];

  networking.hostName = "deviceA";
  system.stateVersion = "24.11";

  home-manager.users.yktsnet = import ./home.nix;
}
