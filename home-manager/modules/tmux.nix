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

  # ディレクトリ単位で使い回すスクラッチターミナル popup（toggleterm.nvim の代替）。
  # popup 内で再度同キーを押すと detach してトグルになる。
  termPopup = pkgs.writeShellScript "tmux-term-popup.sh" ''
    set -uo pipefail
    current="$1"; path="$2"

    case "$current" in
      term-*) exec tmux detach-client ;;
    esac

    hash="$(printf '%s\n' "$path" | md5sum | cut -c1-8)"
    session="term-$hash"

    if ! tmux has-session -t "=$session" 2>/dev/null; then
      tmux new-session -d -s "$session" -c "$path"
      tmux set-option -t "$session" status off
    fi

    tmux display-popup -w 90% -h 90% -E "tmux attach-session -t '$session'"
  '';

  # $HOME 直下と、リポ群を束ねるクラスタ（$HOME/github-public 等、`github-*` 命名）の
  # 1階層下を横断的に列挙し、リポ選択 → そのリポ専用セッションへ切替
  # （craftzdog の ghq+fzf 相当）。存在しないディレクトリは find が黙って無視する。
  sessionizer = pkgs.writeShellScript "tmux-sessionizer.sh" ''
    set -uo pipefail
    sel="$(
      {
        find "$HOME" -mindepth 1 -maxdepth 1 -type d
        find "$HOME"/github-* -mindepth 1 -maxdepth 1 -type d
      } 2>/dev/null | sed "s|^$HOME/||" | ${pkgs.fzf}/bin/fzf --reverse
    )" || exit 0

    path="$HOME/$sel"
    name="$(basename "$path" | tr '.:' '__')"

    tmux has-session -t "=$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$path"
    tmux switch-client -t "=$name"
  '';

  # status-right 用エージェント注意カウント。waiting(黄)/idle(緑)/busy(灰) の数を出す。
  # picker (M-u) を開かなくても「手が必要なエージェントがいるか」が常時見える。
  agentStatus = pkgs.writeShellScript "tmux-agent-status.sh" ''
    set -uo pipefail
    agents="$(claude agents --json 2>/dev/null)" || exit 0
    counts="$(printf '%s' "$agents" | ${pkgs.jq}/bin/jq -r '
      [.[] | select(.kind == "interactive").status]
      | "\(map(select(. == "waiting")) | length) \(map(select(. == "idle")) | length) \(map(select(. == "busy")) | length)"
    ' 2>/dev/null)" || exit 0
    read -r waiting idle busy <<<"$counts" || exit 0

    out=""
    [ "$waiting" -gt 0 ] && out="$out#[fg=#fffac2]●$waiting "
    [ "$idle" -gt 0 ] && out="$out#[fg=#5de4c7]●$idle "
    [ "$busy" -gt 0 ] && out="$out#[fg=#506477]●$busy "
    [ -n "$out" ] && printf '%s#[default] ' "$out"
  '';
in
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    keyMode = "vi";

    plugins = lib.optionals hasClaudeSessionManager [
      claudeSessionManager
    ];

    extraConfig = ''
      # ------------------------------------------
      # Terminal Settings (True Color & Undercurls)
      # ------------------------------------------
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      set -as terminal-overrides ',xterm-256color:RGB'
      set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'
      set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

      # ------------------------------------------
      # Basic & Neovim Optimization Settings
      # ------------------------------------------
      set -g pane-base-index 1
      set -g focus-events on
      set -g allow-passthrough on
      set -g renumber-windows on

      # ------------------------------------------
      # Prefix-less Shortcuts (Alt + Key Only)
      # ------------------------------------------
      # vim-tmux-navigator integration
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
          | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?)(diff)?$'"
      bind-key -n M-Left if-shell "$is_vim" "send-keys M-Left" "select-pane -L"
      bind-key -n M-Down if-shell "$is_vim" "send-keys M-Down" "select-pane -D"
      bind-key -n M-Up if-shell "$is_vim" "send-keys M-Up" "select-pane -U"
      bind-key -n M-Right if-shell "$is_vim" "send-keys M-Right" "select-pane -R"
 
      bind-key -n M-/ if-shell "$is_vim" "send-keys M-/" "split-window -h -c '#{pane_current_path}'"
      bind-key -n M-- if-shell "$is_vim" "send-keys M--" "split-window -v -c '#{pane_current_path}'"
      bind-key -n M-x if-shell "$is_vim" "send-keys M-x" "kill-pane"
      bind-key -n M-j select-pane -t :.+
      bind-key -n M-k select-pane -t :.-

      # ウィンドウ操作
      bind-key -n M-t new-window -c "#{pane_current_path}"
      bind-key -n M-J next-window
      bind-key -n M-K previous-window

      # スクラッチターミナル popup（トグル）とセッショナイザー
      bind-key -n M-p run-shell "${termPopup} '#{q:session_name}' '#{q:pane_current_path}'"
      bind-key -n M-s display-popup -w 60% -h 60% -E "${sessionizer}"

      # その他
      bind-key -n M-v copy-mode
      bind-key -n M-\; command-prompt
    '' + lib.optionalString hasClaudeSessionManager ''

      # Claude Codeセッション管理（zsh・Nvim問わずAlt単押しで統一）
      # M-y/M-Y は押すたびに新しい Claude を起動する（使い回しはしない）。
      # M-y: Sonnet5/Medium（通常運用）、M-Y: Opus5/Low（軽い壁打ち用）
      # 不要になった手前のセッションは exit すれば自動で畳まれる。裏にあるものへ戻るのは M-u。
      bind-key -n M-y run-shell "${claudeLaunchVariant} sonnet 90% 90% '#{q:pane_current_path}' env CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 claude --model sonnet --effort medium"
      bind-key -n M-Y run-shell "${claudeLaunchVariant} opus 90% 90% '#{q:pane_current_path}' env CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 claude --model opus --effort low"
      bind-key -n M-u run-shell "PATH=\"${lib.makeBinPath [ pkgs.tmux pkgs.fzf pkgs.jq pkgs.coreutils ]}:\$PATH\" ${claudeSessionManager}/share/tmux-plugins/claude-session-manager/scripts/list.sh '#{q:client_name}'"
    '' + ''

      set -as command-alias sp="split-window -v -c '#{pane_current_path}'"
      set -as command-alias vs="split-window -h -c '#{pane_current_path}'"
      set -as command-alias q="kill-pane"

      # ------------------------------------------
      # Clipboard & Copy Mode (vi-style)
      # ------------------------------------------
      set -s set-clipboard on
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle
      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "pbcopy"
      bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "pbcopy"

      # ------------------------------------------
      # UI & Status Bar (Poimandres Color Theme)
      # ------------------------------------------
      set -g status-style "bg=#1b1e28,fg=#a6accd"
      set -g status-left ""
      set -g status-right "#(${agentStatus})"

      # ウィンドウタブ
      setw -g window-status-style "fg=#506477,bg=default"
      setw -g window-status-format " #I:#W "
      setw -g window-status-current-style "fg=#addbff,bold,bg=#303340"
      setw -g window-status-current-format " #I:#W "

      # ペインボーダー
      set -g pane-border-style "fg=#303340"
      set -g pane-active-border-style "fg=#addbff"
    '';
  };
}
