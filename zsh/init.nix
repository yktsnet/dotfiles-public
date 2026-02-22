{ pkgs, ... }:

{
  imports = [ ./zsh.nix ];

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history = {
      size = 10000;
      save = 10000;
      path = "$HOME/.zsh_history";
      ignoreDups = true;
      share = true;
    };

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      PAGER = "less";
    };

    initExtra = ''
      bindkey -e
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward
    '';
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };
}
