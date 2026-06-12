{ pkgs, config, lib, ... }:
{
  imports = [
    ./ui.nix
  ];

  programs.zsh = {
    enable = true;
    dotDir = ".config/zsh";

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "less";
    };

    initExtra = ''
      bindkey -e
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward

      # Load custom shell functions and integrations
      ${builtins.readFile ./utils.sh}
      ${builtins.readFile ./git.sh}
      ${builtins.readFile ./aiagent.sh}
      ${builtins.readFile ./jules.sh}
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
