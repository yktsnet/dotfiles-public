{ inputs, lib, ... }:

{
  linux-laptop = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./gui/linux-laptop/system.nix
      inputs.chaotic.nixosModules.default
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  linux-netboot = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./headless/diskless/linux-netboot/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  linux-server-a = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.disko.nixosModules.disko
      ./headless/ssd/linux-server-a/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  linux-desktop = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      ./gui/linux-desktop/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };

  linux-server-b = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.disko.nixosModules.disko
      ./headless/ssd/linux-server-b/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
