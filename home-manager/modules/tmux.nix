{ config, pkgs, lib, osConfig, ... }:

let
  host = osConfig.networking.hostName;
  # 対話的にClaude Codeセッションを渡り歩くホストにのみ導入する
  hasClaudeSessionManager = builtins.elem host [ "macbook" "linux-desktop" ];

  claudeSessionManager = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "claude-session-manager";
    version = "unstable-2026-07-26";
    src = pkgs.fetchFromGitHub {
      owner = "craftzdog";
      repo = "tmux-claude-session-manager";
      rev = "ac3470e57d143e281dc6822b5d425b295c64412f";
      sha256 = "1jrrpifhydnppzdap0c8m7zhrzvnyrzhf23zhkwk98db9i41fif7";
    };
    rtpFilePath = "claude_session_manager.tmux";

    # `shell` はターンを終えてバックグラウンドの作業だけが残っている状態で、user の番である。
    # プラグインは知らない状態として灰色の ? にするので、idle と同じ扱いの分岐を足す。
    postInstall = ''
      substituteInPlace $target/scripts/agents.sh \
        --replace-fail 'else if ($3 == "busy")' 'else if ($3 == "shell")   { icon = "\033[32m●\033[0m idle+sh"; rank = 1 } else if ($3 == "busy")'
    '';
  };

  # status-right 用エージェント表示。並行で数本走らせても幅を取らないよう、状態ごとの件数だけを出す。
  # どのセッションが待っているかは M-u ピッカーで見る。
  # 地は3つで揃え、状態は文字色だけで分ける。待ちは太字で目立たせる。
  # 並びは waiting / idle / busy で、0件は出さない。
  # 色相は M-u ピッカー（プラグインの agents.sh）に合わせ、Poimandres に置き換える。
  # 対象も M-u に揃える。Remote Control のセッションは pane を持たないので agents.sh に
  # 落とされ、ここで数えても飛べない件数が残るだけになる。status の有無で判別できる。
  # `shell`（ターンを終え、バックグラウンドのシェルだけが残っている）は idle に数える。
  agentStatus = pkgs.writeShellScript "tmux-agent-status.sh" ''
    set -uo pipefail
    agents="$(claude agents --json 2>/dev/null)" || exit 0
    printf '%s' "$agents" | ${pkgs.jq}/bin/jq -r '
      [ .[] | select(.kind == "interactive" and .status != null) | .status ] as $s
      | def n($st): [$s[] | select(. == $st)] | length;
      [ { n: n("waiting"), style: "fg=#fffac2,bg=#303340,bold" },
        { n: (n("idle") + n("shell")), style: "fg=#5de4c7,bg=#303340" },
        { n: ([$s[] | select(. != "waiting" and . != "idle" and . != "shell")] | length), style: "fg=#d0679d,bg=#303340" } ]
      | [ .[] | select(.n > 0) | "#[\(.style)] ● \(.n) #[default]" ]
      | join(" ")
      | if length > 0 then . + "  " else "" end
    ' 2>/dev/null
  '';
in
{
  programs.tmux = {
    enable = true;

    plugins = lib.optionals hasClaudeSessionManager [
      claudeSessionManager
    ];

    extraConfig = ''
      # popup が起動した隠しセッションのexit時、デフォルト(on)だとデタッチしtmux終了に見えるためoffにして直前セッションへ自動復帰させる。
      set -g detach-on-destroy off

      set -g status-right "#(${agentStatus})#(cat ~/.cache/claude/tmux-status.txt 2>/dev/null) "
      set -g status-right-length 120
      set -g status-interval 15
    '' + lib.optionalString hasClaudeSessionManager ''

      # Claude Codeセッション管理: 起動は c()（今いるペイン）に一本化し、M-uは走っている
      # Claudeの一覧・移動を担う。popupで起動していないペインもloose行として拾われる。
      bind-key -n M-u run-shell "PATH=\"${lib.makeBinPath [ pkgs.tmux pkgs.fzf pkgs.jq pkgs.coreutils ]}:\$PATH\" ${claudeSessionManager}/share/tmux-plugins/claude-session-manager/scripts/list.sh '#{q:client_name}'"
    '';
  };
}
