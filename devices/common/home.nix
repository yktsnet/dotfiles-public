{ pkgs, lib, config, osConfig, ... }:

{
  imports = [
    ../../home-manager/modules/tmux.nix
    ../../home-manager/modules/claude.nix
    ../../home-manager/modules/memory.nix
    ../../home-manager/modules/secrets-agents.nix
    ../ssh.nix
    ../../home-manager/modules/zsh/nixos.nix
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/crit.nix
  ];

  home.username = lib.mkForce "yktsnet";
  home.homeDirectory = lib.mkForce "/home/yktsnet";
  home.stateVersion = "23.11";



  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    htop
    curl
    wget
    tree
    jq
    ripgrep
    fzf
    rsync
    unzip
    ncdu
    desktop-file-utils
    wl-clipboard
    neovim
    gcc
    gnumake
  ];


  home.file = {
    "dotfiles-hub/current-host-system".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/devices/${osConfig.networking.hostName}/system.nix";
    "dotfiles-hub/current-host-home".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/devices/${osConfig.networking.hostName}/home.nix";
  };
}
