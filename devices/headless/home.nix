{ config, pkgs, ... }:

{
  imports = [
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/btop.nix
    ../../home-manager/modules/zsh/ui.nix
    ../../home-manager/modules/fonts.nix
    ../../home-manager/modules/tmux.nix
    ../ssh.nix
  ];
  home.file.".hushlogin".text = "";
  programs.zsh.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERM = "xterm-256color";
  };

  home.packages = [
    pkgs.bat
    pkgs.neovim
    pkgs.yazi
    pkgs.gcc
    pkgs.gnumake
    pkgs.gopls
    pkgs.pyright
    pkgs.lua-language-server
    pkgs.typescript-language-server
    pkgs.phpactor
  ];

  xdg.configFile."nvim" = {
    source = ../../home-manager/config/nvim;
    recursive = true;
  };
  xdg.configFile."yazi" = {
    source = ../../home-manager/config/yazi;
    recursive = true;
  };

  home.stateVersion = "24.11";
}