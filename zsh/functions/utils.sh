alias t='tmux new-session -A -s main'

y() {
  local tmp final_dir
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"

  # yazi を起動し、終了時の位置を tmp に記録
  yazi "$@" --cwd-file="$tmp"

  if [[ -f "$tmp" ]]; then
    final_dir="$(cat "$tmp")"
    rm -f "$tmp"

    # 終了時の位置が有効、かつ現在の場所と異なる場合のみ cd
    if [[ -d "$final_dir" && "$final_dir" != "$PWD" ]]; then
      builtin cd "$final_dir"
    fi
  fi
}
list() {
  emulate -L zsh
  setopt localoptions typesetsilent

  # 引数から最大階層数を取得（未指定時はデフォルト10）
  local max_depth="${1:-10}"
  local target="."
  local l r_path d_count b_name indent count

  # 汎用的な除外ディレクトリ定義
  local -a dir_ignores=(
    ".git" "node_modules" "__pycache__" "result" ".direnv"
    "bin" "obj" ".idea" ".vscode" ".venv" "venv" "dist" "build" "out" ".next"
  )

  # 汎用的な除外ファイル・拡張子定義
  local -a file_ignores=(
    "flake.lock" "package-lock.json" "yarn.lock" "pnpm-lock.yaml" 
    "*.pyc" ".DS_Store" "Thumbs.db"
  )

  # find用条件式の組み立て
  local -a find_args=()
  
  # ディレクトリ除外条件
  find_args+=( \( -type d \( )
  for i in "${dir_ignores[@]}"; do
    find_args+=( -name "$i" -o )
  done
  find_args[-1]=\) # 最後の "-o" を ")" に置換
  find_args+=( -prune \) -o )

  # ファイル除外条件
  find_args+=( \( -type f \( )
  for i in "${file_ignores[@]}"; do
    find_args+=( -name "$i" -o )
  done
  find_args[-1]=\) 
  find_args+=( -prune \) -o )

  # メイン出力
  echo "$target"

  # -maxdepth に指定階層数を適用
  find "$target" -maxdepth "$max_depth" "${find_args[@]}" -print | sort | while IFS= read -r l; do
      [[ "$l" == "$target" ]] && continue

      r_path=$(echo "$l" | sed "s|^$target/||; s|^\./||")
      d_count=$(echo "$r_path" | tr -cd '/' | wc -c)
      b_name=$(basename "$l")
      indent=$(printf '%*s' $((d_count * 2)) "")

      if [[ -d "$l" && $((d_count + 1)) -eq "$max_depth" ]]; then
        # 指定の最大階層に達したディレクトリのみ、配下の総アイテム数をカウント（除外条件を適用）
        count=$(find "$l" -mindepth 1 "${find_args[@]}" -print 2>/dev/null | wc -l)
        if (( count > 0 )); then
          printf "%s└── %s/ (%d items)\n" "$indent" "$b_name" "$count"
        else
          printf "%s└── %s\n" "$indent" "$b_name"
        fi
      else
        printf "%s└── %s\n" "$indent" "$b_name"
      fi
    done
}

fzf_locate() {
  local search_paths=(${*:-.})
  local target
  target=$(fd --type f --hidden --exclude .git . "${search_paths[@]}" | fzf --exact --height 70% --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {}')
  [[ -n "$target" ]] && "${EDITOR:-${VISUAL:-nvim}}" "$target"
}

fzf_grep() {
  local search_paths=(${*:-.})
  local out file line
  out=$(rg --column --line-number --no-heading --color=always --smart-case . "${search_paths[@]}" | fzf --exact --ansi --delimiter : --nth 4.. --height 70% --reverse --preview 'bat --color=always --style=numbers --highlight-line {2} --line-range={2}:+50 {1}')
  if [[ -n "$out" ]]; then
    file=$(echo "$out" | cut -d: -f1)
    line=$(echo "$out" | cut -d: -f2)
    "${EDITOR:-${VISUAL:-nvim}}" "$file" +"$line"
  fi
}

fzf_git_diff() {
  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$repo_root" ]] && { echo "Not a git repository" >&2; return 1; }

  local target
  target=$((git -C "$repo_root" ls-files --others --modified --exclude-standard && git -C "$repo_root" diff --name-only @{u}...HEAD 2>/dev/null) | sort -u | fzf --exact --height 70% --reverse --preview "bat --color=always --style=numbers $repo_root/{}")
  [[ -n "$target" ]] && "${EDITOR:-${VISUAL:-nvim}}" "$repo_root/$target"
}

_silent_goto() {
  if [[ -d "$1" ]]; then
    builtin cd "$1" >/dev/null 2>&1
  else
    printf '%s\n' "$1 not found" >&2
    return 1
  fi
}

dot() { _silent_goto "$HOME/dotfiles"; }

disk() {
  if command -v ncdu >/dev/null; then
    ncdu /
  else
    df -h
  fi
}
ssh() {
  if [[ $# -gt 0 ]]; then
    command ssh "$@"
    return
  fi

  local ssh_config="$HOME/.ssh/config"
  if [[ ! -f "$ssh_config" ]]; then
    echo "Error: $ssh_config not found" >&2
    return 1
  fi

  local target
  target=$(grep -iE '^Host[[:space:]]+' "$ssh_config" | \
           awk '{print $2}' | \
           grep -vE '[*?]' | \
           fzf --height 40% --reverse --prompt="SSH Connect: ")

  if [[ -n "$target" ]]; then
    command ssh "$target"
  fi
}
