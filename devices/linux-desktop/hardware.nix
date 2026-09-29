{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "sdhci_pci" ];
  boot.kernelModules = [ "kvm-intel" ];

  hardware.cpu.intel.updateMicrocode = true;

  networking.useDHCP = lib.mkDefault true;
  networking.interfaces.enp0s0.useDHCP = true;
  networking.interfaces.wlp0s0.useDHCP = true;
}
