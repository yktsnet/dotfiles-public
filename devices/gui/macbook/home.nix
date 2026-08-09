{ pkgs, lib, config, osConfig, inputs, ... }:
{
  imports = [
    ../../../home-manager/modules/btop.nix
    ../../../home-manager/modules/tmux.nix
    ../../../home-manager/modules/claude.nix
    ../../../home-manager/modules/memory.nix
    ../../../home-manager/modules/secrets-agents.nix
    ../../ssh.nix
    ../../../zsh/darwin.nix
    ../../../home-manager/modules/glow.nix
    ../../../home-manager/modules/vscode.nix
    ../../../home-manager/modules/alacritty.nix
    ../../../home-manager/modules/git.nix
    ../../../home-manager/modules/hunk.nix
    ../../../home-manager/modules/ctx.nix
  ];

  home.username = "ykts";
  home.homeDirectory = "/Users/ykts";
  home.stateVersion = "24.11";

  programs.zsh = {
    enable = lib.mkForce true;
    dotDir = "${config.xdg.configHome}/zsh";
    initContent = lib.mkBefore ''
      export PATH="$HOME/.local/bin:/etc/profiles/per-user/ykts/bin:/run/current-system/sw/bin:$PATH"
    '';
  };

  programs.home-manager.enable = true;
  home.sessionPath = [ "/etc/profiles/per-user/ykts/bin" "/run/current-system/sw/bin" ];
  fonts.fontconfig.enable = lib.mkForce false;

  home.packages = with pkgs; [
    cmake
    ninja
    python3
    go
    gh
    curl
    wget
    tree
    jq
    ripgrep
    fzf
    rsync
    neovim
    fd
    unzip
    ncdu
    docker
    colima
    home-manager
    pure-prompt
    aerospace
    inputs.claude-history.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  xdg.configFile."nvim" = {
    source = ../../../home-manager/config/nvim;
    recursive = true;
  };
}
