{ pkgs, inputs, ... }:

let
  critPkg = inputs.crit.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # 起動中のローカルページに crit live のレビュー UI を被せる。エージェントと user の
  # 共通の入口。zsh 関数は非対話シェルに載らずエージェントの Bash から呼べないので bin にする。
  critLive = pkgs.writeShellScriptBin "crit-live" ''
    set -euo pipefail

    url=''${1:-}
    if [ -z "$url" ]; then
      echo "usage: crit-live <http://localhost:PORT[/path]>" >&2
      exit 2
    fi
    case "$url" in
      http://localhost:* | http://127.0.0.1:* | https://localhost:* | https://127.0.0.1:*) ;;
      *)
        echo "crit-live: loopback の URL だけを受ける（受け取った値: $url）" >&2
        exit 2
        ;;
    esac

    # 同じディレクトリに稼働中のデーモンがあると crit live は無言でハングする
    # （listener も立たずログも出ない）。先に落として理由を出す。
    if ${critPkg}/bin/crit status 2>/dev/null | grep -Eq '^Daemon:[[:space:]]+running'; then
      echo "crit-live: このディレクトリには稼働中のレビューがある。Finish Review を押すか d stop で閉じてから。" >&2
      exit 1
    fi

    exec ${critPkg}/bin/crit live "$url"
  '';
in
{
  home.packages = [
    critPkg
    critLive
  ];

  # crit 同梱の `crit install claude-code` は使わず、marketplace プラグインで入れている。
  # crit 側の検出は前者しか見ないため、起動のたびに出る未導入の案内を止める
  home.sessionVariables.CRIT_NO_INTEGRATION_CHECK = "1";
}
