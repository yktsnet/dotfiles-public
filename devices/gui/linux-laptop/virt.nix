{ pkgs, ... }:

{
  imports = [
    ../../../home-manager/modules/virtualisation/virt-common.nix
  ];

  programs.virt-manager.enable = true;

}
