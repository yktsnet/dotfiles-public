{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/system.nix
    ./hardware.nix
    ./disko.nix
  ];

  networking.hostName = "linux-desktop";
  system.stateVersion = "24.11";

  home-manager.users.yktsnet = import ./home.nix;
}
