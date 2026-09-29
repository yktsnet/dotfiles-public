{ pkgs, inputs, config, lib, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;

  # Basic system settings
  system.activationScripts.postActivation.text = lib.mkAfter ''
    # Prevent system sleep when connected to power
    /usr/bin/pmset -c sleep 0
    /usr/bin/pmset -c disksleep 0
    # Enable SSH Remote Login
    /usr/sbin/systemsetup -setremotelogin on 2>/dev/null || true
  '';

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.auto-optimise-store = true;
  nix.settings.trusted-users = [ "root" "ykts" ];

  security.sudo.extraConfig = ''
    %wheel ALL=(ALL) NOPASSWD: ALL
  '';

  environment.systemPackages = with pkgs; [
    mosh
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];

  services.tailscale.enable = true;
  programs.zsh.enable = true;

  users.users.ykts = {
    name = "ykts";
    home = "/Users/ykts";
  };

  # Shared home-manager setup
  home-manager = {
    extraSpecialArgs = { inherit inputs; osConfig = config; };
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
  };

  home-manager.users.ykts = import ./home.nix;
  system.primaryUser = "ykts";
  networking.hostName = "macbook";
  system.stateVersion = 6;
}
