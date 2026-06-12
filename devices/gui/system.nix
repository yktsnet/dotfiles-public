{ pkgs, lib, inputs, config, ... }:

let
  appsRoot = ../../apps;
  appDirs = builtins.attrNames (
    lib.filterAttrs (name: type: type == "directory") (builtins.readDir appsRoot)
  );
  toServicePath = name: appsRoot + "/${name}/${name}-service.nix";
  autoApps = builtins.filter (path: builtins.pathExists path) (map toServicePath appDirs);
in
{
  imports = [
  ] ++ autoApps;



  environment.shellAliases = {
    toggle-audio = ''
      wpctl status | grep -q "\*.*USB Audio Device" && \
      wpctl set-default $(wpctl status | grep "Built-in Audio Analog Stereo" | head -n1 | awk '{print $1}' | tr -d '.') || \
      wpctl set-default $(wpctl status | grep "USB Audio Device Analog Stereo" | head -n1 | awk '{print $1}' | tr -d '.')
    '';
  };

  users.users.yktsnet = {
    isNormalUser = true;
    description = "yktsnet";
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker"
      "uinput"
      "input"
      "libvirtd"
    ];
    uid = 1000;
    hashedPassword = "*";
    linger = true;
  };



  yktsnet.apps.lpt = {
    enable = true;
    envTxtMaker = true;
    resultHarvest = true;
  };

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

  security.sudo.wheelNeedsPassword = false;
  hardware.uinput.enable = true;

  environment.variables = { HOST_COLOR = "#7aa2f7"; };

  powerManagement.cpuFreqGovernor = "powersave";

  home-manager.users.yktsnet = import ./home.nix;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  system.stateVersion = "24.11";
}
