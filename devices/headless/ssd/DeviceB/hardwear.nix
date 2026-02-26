{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
  ];
  fileSystems."/mnt/ext_hdd" = {
    device = "/dev/sdb1";
    fsType = "ext4";
    options = [ "defaults" "nofail" ];
  };
  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ ];

  hardware.cpu.intel.updateMicrocode = true;

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
