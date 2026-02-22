{ pkgs, ... }:

{
  programs.zsh.shellAliases = {
    re = "reset";
    l = "lazygit";
    f = "fzf_locate";
    F = "fzf_history";
    g = "fzf_grep";
    G = "fzf_git_diff";
    rz = "exec zsh";
    nix-sw = "sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname)";
    txt-make = "python3 ~/dotfiles/apps/lpt/core/env_txt_maker.py --config ~/dotfiles/apps/lpt/env/env.txt_maker.nix";
  };

  programs.zsh.interactiveShellInit = ''
    # OSC 52 Clipboard Integration (Local & Headless VPS)
    c() {
      local input
      input=$(cat)
      local b64_data=$(printf "%s" "$input" | ${pkgs.coreutils}/bin/base64 | ${pkgs.gnused}/bin/sed ':a;N;$!ba;s/\n//g')
      
      if [[ -n "$TMUX" ]]; then
        printf "\033Ptmux;\033]52;c;%s\a\033\\" "$b64_data"
      elif [[ "$HOST" == "<LOCAL_HOST_NAME>" ]]; then # t14等のローカルホスト名をプレースホルダー化
        printf "%s" "$input" | ${pkgs.wl-clipboard}/bin/wl-copy
      else
        printf "\033]52;c;%s\a" "$b64_data"
      fi
      printf "%s" "$input"
    }

    # Ranger Wrapper for Directory Sync
    r() {
      local tmp="$(mktemp -t "ranger_cd.XXXXXX")"
      local target_dir="''${1:-$HOME/dotfiles/}"

      if [[ "''$target_dir" != /* ]] && [ ! -d "''$target_dir" ] && [ -d "''$HOME/''$target_dir" ]; then
        target_dir="''$HOME/''$target_dir"
      fi

      ${pkgs.ranger}/bin/ranger --choosedir="''$tmp" "''$target_dir"

      if [ -f "''$tmp" ]; then
        local dir="$(cat "''$tmp")"
        rm -f "''$tmp"
        if [ -d "''$dir" ] && [ "''$dir" != "''$PWD" ]; then
          cd "''$dir"
        fi
      fi
    }

    # Helix & FZF Integration
    fzf_locate() {
      local target=$(fd --type f --hidden --exclude .git . ~/dotfiles | fzf --exact --height 70% --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {}')
      [[ -n "$target" ]] && hx "$target"
    }

    fzf_grep() {
      local out=$(rg --column --line-number --no-heading --color=always --smart-case . ~/dotfiles | fzf --exact --ansi --delimiter : --nth 4.. --height 70% --reverse --preview 'bat --color=always --style=numbers --highlight-line {2} --line-range={2}:+50 {1}')
      if [[ -n "$out" ]]; then
        local file=$(echo "$out" | cut -d: -f1)
        local line=$(echo "$out" | cut -d: -f2)
        hx "$file" +$line
      fi
    }

    fzf_history() {
      local script_path="$HOME/dotfiles/zsh/path_history.py"
      if [[ -f "$script_path" ]]; then
        local target=$(python3 "$script_path")
        [[ -n "$target" && -f "$target" ]] && hx "$target"
      fi
    }

    # AI Context & Scraper Integration
    gsave() {
      local url="''${1:-}"
      if [[ -z "$url" ]]; then
        echo -n "Share URL: "
        read url
      fi
      [[ -z "$url" ]] && return 1

      nix-shell $HOME/dotfiles/apps/lpt/env/env.gsave.nix --run "python3 $HOME/dotfiles/apps/lpt/core/share_extractor.py $url"
    }
  '';
}
