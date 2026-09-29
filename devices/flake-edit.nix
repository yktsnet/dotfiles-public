{ inputs, lib, ... }:

{
  linux-desktop = lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = { inherit inputs; };
    modules = [
      inputs.disko.nixosModules.disko
      ./linux-desktop/system.nix
      inputs.home-manager.nixosModules.home-manager
    ];
  };
}
