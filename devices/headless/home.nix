{ config, pkgs, ... }:

{
  imports = [
    ../../home-manager/modules/git.nix
    ../../home-manager/modules/btop.nix
    ../../home-manager/modules/ranger/home.nix
    ../../home-manager/modules/zsh/ui.nix
    ../../home-manager/modules/fonts.nix
    ../../home-manager/modules/tmux.nix
    ../../home-manager/modules/helix.nix
    ../ssh.nix
  ];
  home.file.".hushlogin".text = "";
  programs.zsh.enable = true;

  home.sessionVariables = {
    EDITOR = "hx";
    VISUAL = "hx";
    TERM = "xterm-256color";
  };

  home.packages = [ pkgs.bat ];

  home.stateVersion = "24.11";
}