{ config, pkgs, lib, inputs, ... }:

let
  envCtx = import "${inputs.self}/apps/env-context.nix" { inherit pkgs; };
  homeDir = "/home/yktsnet";
in
{
  imports = [
    ../system.nix
    ./hardware.nix
    ./disko.nix
    ../../../../zsh/apps-zsh.nix
    ../../../../apps/lpt/lpt-service.nix
    # Other internal services are imported here
  ];

  boot.loader.systemd-boot.enable = lib.mkForce false;
  boot.loader.grub = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };
  boot.loader.efi.canTouchEfiVariables = lib.mkForce false;

  networking.hostName = "het";
  networking.useDHCP = lib.mkDefault true;

  services.tailscale = {
    enable = true;
    extraUpFlags = [ "--ssh" ];
  };

  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPortRanges = [
      { from = 60001; to = 60100; }
    ];
  };

  environment.systemPackages = with pkgs; [ mosh tmux ];

  yktsnet.apps.lpt = {
    enable = false;
  };

  # Abstracted internal services (e.g., trading engines, data pipelines)
  yktsnet.apps.trading_engine = {
    enable = true;
    orchestrator = true;
    tradeGuard = true;
  };

  yktsnet.apps.data_pipeline = {
    enable = true;
    fetchHistory = true;
    snapshotPl = true;
  };

  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  environment.variables = {
    HOST_COLOR = "#ff79c6";
    PYTHONPATH = lib.mkForce (lib.concatStringsSep ":" (envCtx.makePythonPath homeDir));
  };

  users.users.yktsnet.openssh.authorizedKeys.keys = [
    "ssh-ed25519 <YOUR_PUBLIC_KEY> yktsnet@laptop"
  ];

  home-manager.users.yktsnet = {
    imports = [ ./home.nix ];
    programs.tmux = {
      enable = true;
      mouse = true;
      extraConfig = ''
        bind-key -n MouseDragEnd1Pane if-shell "test { #{m:Control,#{client_key_table}} }" "copy-mode -M; send-keys -X copy-selection-and-cancel" "send-keys -X clear-selection"
      '';
    };
  };

  system.stateVersion = "24.11";
}
