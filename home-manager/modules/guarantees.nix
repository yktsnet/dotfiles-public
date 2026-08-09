{ config, lib, pkgs, ... }:

{
  # スクリプトが無くても activation 全体を落とさない（claude.nix / memory.nix と同じ理由）。
  # 環境変数は渡さずスクリプト側の既定に任せる。上書きしたい利用者はこの module を書き換える。
  home.activation.runLinkGuarantees = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    SCRIPT_PATH="${config.home.homeDirectory}/dotfiles/apps/lpt/link_guarantees.py"
    if [ -f "$SCRIPT_PATH" ]; then
      ${pkgs.python3}/bin/python3 "$SCRIPT_PATH"
    fi
  '';
}
