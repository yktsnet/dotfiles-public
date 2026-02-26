{ inputs, lib, ... }:

{
  t14 = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./gui/t14/system.nix
      inputs.chaotic.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  netboot_4gb = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./headless/diskless/netboot_4gb/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  het = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.disko.nixosModules.disko
      ./headless/ssd/het/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  deviceA = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./gui/deviceA/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  DeviceB = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.disko.nixosModules.disko
      ./headless/ssd/DeviceB/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
