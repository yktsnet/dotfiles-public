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

  # 呼ぶたびに新しい隠しセッションを起動し、ポップアップ枠でアタッチする。
  # 離脱してもバックグラウンドセッションで実行が継続し、Alt+u（ピッカー）から復帰できる。
  claudeLaunchVariant = pkgs.writeShellScript "claude-launch-variant.sh" ''
    set -uo pipefail
    profile="$1"; w="$2"; h="$3"; path="$4"; shift 4

    [ -d "$path" ] || { tmux display-message "claude-launch-variant: $path no longer exists"; exit 0; }

    prefix="claude-"
    if [[ "$(tmux display-message -p '#S')" == "$prefix"* ]]; then
      tmux display-message '🫪 Popup window already open'
      exit 0
    fi

    session="claude-''${profile}-$$-''${RANDOM}"
    tmux new-session -d -s "$session" -c "$path" -- "$@"

    exec tmux display-popup -w "$w" -h "$h" -d "$path" -E "unset TMUX; tmux attach-session -t '$session'"
  '';

  # session-nudge の fzf プレビュー: sessionId からトランスクリプトを引いて直近を表示する。
  # ファイルは ~/.claude/projects/<プロジェクト>/ 配下にあるが、cwd からディレクトリ名を
  # 組み立てず glob で引く（変換規則に依存しないため）。
  nudgePreview = pkgs.writeShellScript "session-nudge-preview.sh" ''
    set -uo pipefail
    sid="''${1:-}"
    [ -n "$sid" ] || exit 0

    file=""
    for f in "$HOME"/.claude/projects/*/"$sid".jsonl; do
      [ -f "$f" ] && file="$f" && break
    done
    [ -n "$file" ] || { printf 'no transcript for %s\n' "$sid"; exit 0; }

    ${pkgs.jq}/bin/jq -r '
      select(type=="object" and (.type=="user" or .type=="assistant"))
      | (if .type=="user" then "▸ " else "  " end)
        + ((.message.content // "") | if type=="string" then .
           else ([.[]
                  | if .type=="text" then .text
                    elif .type=="tool_use" then "$ " + .name
                    else "" end] | join(" ")) end)
    ' "$file" 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -v '^[▸ ] *$' \
      | ${pkgs.gnugrep}/bin/grep -v '^▸ <' \
      | tail -n 60
  '';

  # session-nudge: 対象セッションをfzfで選んでから claude を起動する。
  # 相談内容は claude 側で聞く。素のシェルの read では IME が効かず日本語を打てない。
  #
  # 呼び出し元セッションを候補から外すために pane を照合する。claude の pid は tmux の
  # pane_pid（シェル側）と一致しないので、親を辿って解決する。
  nudgePickAndLaunch = pkgs.writeShellScript "session-nudge-pick.sh" ''
    set -uo pipefail

    self_pane="$(tmux display-message -p '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null || true)"

    resolve_pane() {
      pid="$1"
      while [ -n "$pid" ] && [ "$pid" -gt 1 ] 2>/dev/null; do
        pane="$(tmux list-panes -a -F '#{pane_pid} #{session_name}:#{window_index}.#{pane_index}' \
          | ${pkgs.gawk}/bin/awk -v p="$pid" '$1==p{print $2; exit}')"
        if [ -n "$pane" ]; then
          printf '%s' "$pane"
          return 0
        fi
        pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')"
      done
      return 1
    }

    # そのセッションが何の話か: 最初の実ユーザー発言を見出しにする。
    # 冒頭にはスラッシュコマンド・system-reminder・添付・skill本文が混ざるので落とす。
    topic_of() {
      for f in "$HOME"/.claude/projects/*/"$1".jsonl; do
        [ -f "$f" ] || continue
        head -n 80 "$f" | ${pkgs.jq}/bin/jq -r '
          select(type=="object" and .type=="user")
          | (.message.content // "")
          | if type=="string" then . else ([.[] | select(.type=="text") | .text] | join(" ")) end
          | select(length > 0
                   and (startswith("<") | not)
                   and (startswith("/") | not)
                   and (startswith("Base directory for this skill") | not))
        ' 2>/dev/null | head -n 1 | tr '\t' ' ' | cut -c1-48
        return 0
      done
    }

    rows=""
    while IFS="$(printf '\t')" read -r name status cwd pid sid; do
      [ -n "$name" ] || continue
      pane="$(resolve_pane "$pid")" || continue
      [ "$pane" = "$self_pane" ] && continue
      topic="$(topic_of "$sid")"
      rows="$rows$name	$status	$(basename "$cwd")	''${topic:--}	$sid
    "
    done <<EOF
    $(claude agents --json 2>/dev/null \
      | ${pkgs.jq}/bin/jq -r '.[] | select(.kind == "interactive") | [.name, .status, .cwd, .pid, .sessionId] | @tsv')
    EOF

    [ -n "$(printf '%s' "$rows" | tr -d '[:space:]')" ] || {
      printf 'No other interactive session found.\n'
      read -r _
      exit 0
    }

    selected="$(
      printf '%s' "$rows" \
        | ${pkgs.fzf}/bin/fzf --reverse --delimiter='\t' --with-nth=1,2,3,4 \
            --header='Select target session (name / status / repo / topic)' \
            --preview='${nudgePreview} {5}' \
            --preview-window='right,65%,wrap,follow'
    )" || exit 0

    target="$(printf '%s' "$selected" | cut -f1)"
    [ -n "$target" ] || exit 0

    exec env CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 claude --model opus --effort medium --permission-mode bypassPermissions \
      "/session-nudge target=$target"
  '';

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

      # session-nudge: 別セッションへの違和感をcross-session messagingで確認・送信する。
      # 対象選択と懸念入力はポップアップ内でfzf/readにより先に済ませ、claudeは判定・送信だけを担う。
      # 判定・送信は確認を挟まず自走してよい作業のためAuto mode（bypassPermissions）で起動する。
      bind-key -n M-m run-shell "${claudeLaunchVariant} nudge 90% 90% '#{q:pane_current_path}' ${nudgePickAndLaunch}"
    '';
  };
}
