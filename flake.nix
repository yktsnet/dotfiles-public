{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    claude-history = {
      url = "github:raine/claude-history";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # 全 nixosConfigurations に sops module と secret 自動登録層を一律で足す。
    # devices/flake-edit.nix 側の modules 列挙は個別デバイスの構成に専念させ、
    # 横断的な配線はここで extendModules によって1箇所にまとめる。
    nixosConfigurations = builtins.mapAttrs
      (_: cfg: cfg.extendModules {
        modules = [
          inputs.sops-nix.nixosModules.sops
          ./devices/secrets.nix
        ];
      })
      (import ./devices/flake-edit.nix {
        inherit inputs;
        lib = nixpkgs.lib;
      });

    darwinConfigurations = {
      macbook = inputs.nix-darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { inherit inputs; };
        modules = [
          inputs.home-manager.darwinModules.home-manager
          inputs.sops-nix.darwinModules.sops
          ./devices/gui/macbook/system.nix
        ];
      };
    };
  };
}
