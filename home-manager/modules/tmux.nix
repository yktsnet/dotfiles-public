{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    escapeTime = 0;
    terminal = "tmux-256color";
    keyMode = "vi";

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

      # その他
      bind-key -n M-v copy-mode
      bind-key -n M-\; command-prompt

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
      set -g status-right ""

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
