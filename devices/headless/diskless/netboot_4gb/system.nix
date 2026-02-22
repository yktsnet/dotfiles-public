{ pkgs, lib, inputs, config, ... }:

{
  imports = [
    ../system.nix
    ./hardware.nix
    ../../../../zsh/ops.nix
    ../../../../zsh/utils.nix
    ../../../../zsh/git.nix
    ../../../wifi.nix
  ];

  networking.hostName = "netboot_4gb";

  users.users.yktsnet.openssh.authorizedKeys.keys = [
    "ssh-ed25519 <YOUR_PUBLIC_KEY> yktsnet@t14"
  ];

  boot.kernelParams = lib.mkAfter [
    "thinkpad_acpi.fan_control=1"
    "intel_pstate=passive"
    "processor.ignore_ppc=1"
  ];

  services.thinkfan = {
    enable = true;
    levels = [
      [ 0 0 50 ]
      [ 1 48 55 ]
      [ 3 52 65 ]
      [ 7 60 85 ]
      [ "level auto" 80 100 ]
    ];
  };

  powerManagement.cpuFreqGovernor = lib.mkForce "powersave";

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 40;
      CPU_BOOST_ON_AC = 0;
      SCHED_POWERSAVE_ON_AC = 1;
    };
  };

  services.getty.autologinUser = lib.mkForce "yktsnet";
  services.logind.settings.Login.HandleLidSwitch = "ignore";

  services.tailscale.extraUpFlags = lib.mkAfter [ "--advertise-tags=tag:server" ];

  environment.variables = {
    HOST_COLOR = "#e0af68";
    TERM = "xterm-256color";
  };

  networking.firewall = {
    allowedTCPPorts = [ 22 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  home-manager.users.yktsnet = import ../../home.nix;
  system.stateVersion = "24.11";
}
