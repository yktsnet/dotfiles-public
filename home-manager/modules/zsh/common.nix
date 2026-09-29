{ config, ... }:
# 共通 zsh ベース（home-manager モジュール）。
# OS 非依存の設定とシェル関数のロードをここに集約し、
# darwin.nix / nixos.nix が OS 固有の差分を上乗せする。
{
  programs.zsh = {
    enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

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
      unset __HM_ZSH_S_SOURCED

      bindkey -e
      bindkey '^[[A' history-search-backward
      bindkey '^[[B' history-search-forward

      # Issue 駆動ワークフローのシェル関数群を読み込む。
      # os.sh のシムと menu.sh の _pick / _confirm は aiagent.sh から呼ばれる土台なので、先に読み込む。
      ${builtins.readFile ./functions/os.sh}
      ${builtins.readFile ./functions/menu.sh}
      ${builtins.readFile ./functions/aiagent.sh}
    '';
  };
}
