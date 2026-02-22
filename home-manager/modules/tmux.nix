{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    mouse = true;
    escapeTime = 0;
    terminal = "tmux-256color";

    extraConfig = ''
      set -g pane-base-index 1
      set -g status off
      set -g pane-border-style fg=default
      set -g pane-active-border-style fg=default

      set -s set-clipboard on
      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      set -as terminal-overrides ',xterm-256color:RGB'
      set -g focus-events on

      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D
    '';
  };
}
