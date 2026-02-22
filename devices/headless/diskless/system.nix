{ pkgs, inputs, lib, config, ... }:

{
  imports = [
    ../system.nix
    (inputs.nixpkgs + "/nixos/modules/installer/netboot/netboot-minimal.nix")
  ];

  boot.loader.grub.enable = false;

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=755" ];
  };

  boot.kernelParams = [
    "boot.shell_on_fail"
    "ramdisk_size=4096000"
    "console=tty1"
  ];

  boot.initrd = {
    compressor = "zstd";
    compressorArgs = [ "-19" "-T0" ];
  };
}
