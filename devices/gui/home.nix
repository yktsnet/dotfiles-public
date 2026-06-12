{ pkgs, lib, config, osConfig, ... }:

{
  imports = [
    ../../home-manager/modules/btop.nix
    ../../home-manager/modules/tmux.nix
    ../ssh.nix
    ../../home-manager/modules/alacritty.nix
    ../../home-manager/modules/zsh/ui.nix
    ../../home-manager/modules/glow.nix
    ../../home-manager/modules/fonts.nix
    ../../home-manager/modules/vscode.nix
    ../../home-manager/modules/waybar.nix
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/desktop/gui-bundle.nix
    ../../home-manager/modules/firefox.nix
    ../../home-manager/modules/sioyek.nix
  ];

  home.username = lib.mkForce "yktsnet";
  home.homeDirectory = lib.mkForce "/home/yktsnet";
  home.stateVersion = "23.11";



  programs.zsh = {
    enable = lib.mkForce true;
    dotDir = "${config.xdg.configHome}/zsh";
  };

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
    yazi
    gcc
    gnumake
  ];


  home.file = {
    "dotfiles-hub/current-host-system".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/devices/gui/${osConfig.networking.hostName}/system.nix";
    "dotfiles-hub/current-host-home".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/devices/gui/${osConfig.networking.hostName}/home.nix";
  };



  xdg.configFile."nvim" = {
    source = ../../home-manager/config/nvim;
    recursive = true;
  };
  xdg.configFile."yazi" = {
    source = ../../home-manager/config/yazi;
    recursive = true;
  };
}
