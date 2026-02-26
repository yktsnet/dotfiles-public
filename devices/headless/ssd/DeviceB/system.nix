{ config, pkgs, lib, inputs, ... }:

let
  envCtx = import "${inputs.self}/apps/env-context.nix" { inherit pkgs; };
  homeDir = "/home/user";
in
{
  environment.systemPackages = [
    (pkgs.python3.withPackages envCtx.pythonPackages)
    pkgs.jq
  ];
  imports = [
    ../../system.nix
    ./hardware.nix
    ./audio.nix
  ];

  networking.hostName = "DeviceB";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  services.tailscale.extraUpFlags = lib.mkAfter [
    "--advertise-tags=tag:laptop"
  ];

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    LidSwitchIgnoreInhibited = "no";
  };

  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };

  environment.variables = {
    HOST_COLOR = "#7dcfff";
    PYTHONPATH = lib.mkForce (lib.concatStringsSep ":" (envCtx.makePythonPath homeDir));
  };

  home-manager.users.user = import ./home.nix;

  system.stateVersion = "24.11";
}
