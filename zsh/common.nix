{ ... }:
# 共通 zsh ベース（home-manager モジュール）。
# OS 非依存の設定とシェル関数のロードをここに集約し、
# darwin.nix / nixos.nix が OS 固有の差分を上乗せする。
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

    initContent = ''
      bindkey -e
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward

      # Issue 駆動ワークフローのシェル関数群を読み込む。
      ${builtins.readFile ./functions/utils.sh}
      ${builtins.readFile ./functions/git.sh}
      ${builtins.readFile ./functions/aiagent.sh}
      ${builtins.readFile ./functions/jules.sh}
    '';
  };
  # プロンプトは ui.nix の pure prompt を使用する。
}
