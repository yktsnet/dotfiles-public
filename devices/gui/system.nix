{ pkgs, lib, inputs, config, ... }:

let
  appsRoot = ../../../apps;
  appDirs = builtins.attrNames (
    lib.filterAttrs (name: type: type == "directory") (builtins.readDir appsRoot)
  );
  toServicePath = name: appsRoot + "/${name}/${name}-service.nix";
  autoApps = builtins.filter (path: builtins.pathExists path) (map toServicePath appDirs);
in
{
  imports = [
    ../system.nix
    ./hardware.nix
    ./audio.nix
    ./virt.nix
    ../../../zsh/apps-zsh.nix
    ./symlinks.nix
  ] ++ autoApps;

  networking.hostName = "t14";
  services.udisks2.enable = true;
  environment.systemPackages = with pkgs; [ udisks2 ];

  services.tailscale.enable = true;
  services.tailscale.extraUpFlags = lib.mkAfter [
    "--advertise-tags=tag:laptop"
    "--ssh"
  ];

  environment.shellAliases = {
    toggle-audio = ''
      wpctl status | grep -q "\*.*USB Audio Device" && \
      wpctl set-default $(wpctl status | grep "Built-in Audio Analog Stereo" | head -n1 | awk '{print $1}' | tr -d '.') || \
      wpctl set-default $(wpctl status | grep "USB Audio Device Analog Stereo" | head -n1 | awk '{print $1}' | tr -d '.')
    '';
  };

  users.users.yktsnet.extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "audio"
    "docker"
    "uinput"
    "input"
    "libvirtd"
  ];

  # OS-level Helix-like navigation
  services.xremap = {
    enable = true;
    withHypr = true;
    userName = "yktsnet";
    config = {
      modmap = [
        { name = "CapsToRightAlt"; remap = { "CapsLock" = "RightAlt"; }; }
      ];
      keymap = [
        {
          name = "Helix-Global-Navigation";
          remap = {
            "RightAlt-h" = "Left";
            "RightAlt-j" = "Down";
            "RightAlt-k" = "Up";
            "RightAlt-l" = "Right";
            "RightAlt-g" = "Home";
            "RightAlt-semicolon" = "End";
            "RightAlt-n" = "PageDown";
            "RightAlt-p" = "PageUp";
            "RightAlt-d" = "Delete";
            "RightAlt-x" = "BackSpace";
            "RightAlt-D" = { launch = [ "Shift-End" "BackSpace" ]; };
          };
        }
      ];
    };
  };

  yktsnet.apps.lpt = {
    enable = true;
    envTxtMaker = true;
    systemdOverview = false;
    zshChecker = true;
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
