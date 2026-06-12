_ensure_npm_path() {
  if [[ -d "$HOME/.local/npm-global/bin" ]] && [[ ":$PATH:" != *":$HOME/.local/npm-global/bin:"* ]]; then
    export PATH="$HOME/.local/npm-global/bin:$PATH"
  fi
}

gpl() {
  local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
  if [[ -z "$branch" ]]; then
    echo "Error: Not a git repository or detached HEAD."
    return 1
  fi
  echo "Pulling from origin/$branch..."
  git pull origin "$branch"
}

gs() {
  emulate -L zsh

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  [[ -z "$repo_root" ]] && { print "gs: not a git repository" >&2; return 1; }

  local branch ahead behind
  branch=$(git symbolic-ref -q --short HEAD || print "detached")
  ahead=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
  behind=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")

  local remote_info=""
  if (( ahead > 0 && behind > 0 )); then
    remote_info=$(printf "  \033[33m↑%s ↓%s\033[0m" "$ahead" "$behind")
  elif (( ahead > 0 )); then
    remote_info=$(printf "  \033[32m↑%s ahead\033[0m" "$ahead")
  elif (( behind > 0 )); then
    remote_info=$(printf "  \033[31m↓%s behind\033[0m" "$behind")
  fi

  printf "\033[1m%s\033[0m%s\n\n" "$branch" "$remote_info"

  # 未追跡ファイルも含めて差分・新規数を正確に取得
  local numstat
  numstat=$(git diff HEAD --numstat 2>/dev/null)
  
  # 未追跡ファイル（ステージ前）をカバーするため status も併用（-u で未追跡ディレクトリ内を展開）
  local status_out
  status_out=$(git status --porcelain=v1 -u 2>/dev/null)

  if [[ -z "$numstat" && -z "$status_out" ]]; then
    print "  no changes since last commit"
    return 0
  fi

  local -a filepaths adds dels
  local max_len=0
  local -A seen

  # 1. numstat から編集・ステージ済ファイルを処理
  if [[ -n "$numstat" ]]; then
    while IFS=$'\t' read -r a d fp; do
      [[ -z "$fp" ]] && continue
      local short="${fp/#$HOME/~}"
      filepaths+=("$short")
      adds+=("$a")
      dels+=("$d")
      seen[$fp]=1
      (( ${#short} > max_len )) && max_len=${#short}
    done <<< "$numstat"
  fi

  # 2. porcelain から numstat に漏れた未追跡ファイル（??）を補完
  if [[ -n "$status_out" ]]; then
    while read -r line; do
      [[ -z "$line" ]] && continue
      local xy="${line:0:2}"
      local fp="${line:3}"
      [[ "$xy" =~ 'R' ]] && fp="${fp##* -> }"
      
      # 既に処理済、または未追跡ファイル以外はスキップ
      [[ -n "${seen[$fp]}" || "$xy" != "??" ]] && continue

      local short="${fp/#$HOME/~}"
      local cnt=0
      [[ -f "$fp" ]] && cnt=$(wc -l < "$fp" | tr -d ' ')

      filepaths+=("$short")
      adds+=("$cnt")
      dels+=("0")
      (( ${#short} > max_len )) && max_len=${#short}
    done <<< "$status_out"
  fi

  for i in {1..${#filepaths}}; do
    printf "  %-${max_len}s  \033[32m+%-4s\033[0m \033[31m-%-4s\033[0m\n" \
      "${filepaths[$i]}" "${adds[$i]}" "${dels[$i]}"
  done
}

_gcm_build_message() {
  emulate -L zsh

  local -a staged new_files
  staged=(${(@f)$(git diff --cached --name-only 2>/dev/null)})
  [[ ${#staged} -eq 0 ]] && { print "nothing staged" >&2; return 1; }

  new_files=(${(@f)$(git diff --cached --name-only --diff-filter=A 2>/dev/null)})

  local -A seen
  local -a candidates

  for f in $staged; do
    local base scope is_new=0
    base=$(basename "$f" | sed 's/\.[^.]*$//')
    local dir
    dir=$(dirname "$f")
    [[ "$dir" == "." ]] && scope="$base" || scope="${dir:t}"
    (( ${new_files[(I)$f]} > 0 )) && is_new=1

    case "$f" in
      *[Tt]est*|*.test.*|*.spec.*)
        candidates+=("test(${scope}): ")
        ;;
      *.md)
        candidates+=("docs(${scope}): ")
        ;;
      *.sql)
        candidates+=("chore(db): ")
        ;;
      *.sh|*.yml|*.yaml|*.nix|*.toml|Makefile)
        (( is_new )) \
          && candidates+=("feat(${scope}): " "chore(${scope}): " "fix(${scope}): ") \
          || candidates+=("chore(${scope}): " "feat(${scope}): " "fix(${scope}): ")
        ;;
      *)
        (( is_new )) \
          && candidates+=("feat(${scope}): " "fix(${scope}): " "refactor(${scope}): ") \
          || candidates+=("fix(${scope}): " "feat(${scope}): " "refactor(${scope}): ")
        ;;
    esac
  done

  local -a uniq
  local -A dup
  for c in $candidates; do
    [[ -z "${dup[$c]}" ]] && { dup[$c]=1; uniq+=("$c"); }
  done

  local selected
  selected=$(printf '%s\n' "${uniq[@]}" \
    | fzf --prompt="commit> " --height=40% --reverse) || return 1
  [[ -z "$selected" ]] && return 1

  local subject=""
  vared -p "subject: " subject
  [[ -z "$subject" ]] && return 1

  typeset -g _GCM_MSG="${selected}${subject}"
}

gc() {
  emulate -L zsh
  git add -A
  gs
  print ""
  if ! _gcm_build_message; then
    git reset HEAD 2>/dev/null
    return 1
  fi
  git commit -m "$_GCM_MSG"
}

gca() {
  emulate -L zsh
  git add -A
  print ""
  if ! _gcm_build_message; then
    git reset HEAD 2>/dev/null
    return 1
  fi
  git commit --amend --reset-author -m "$_GCM_MSG"
}

gp() {
  emulate -L zsh
  setopt err_return pipe_fail
  _ensure_npm_path

  local repo_root
  repo_root=$(git rev-parse --show-toplevel 2>/dev/null || true)
  [[ -z "$repo_root" ]] && { print "gp: not a git repository" >&2; return 1; }

  if ! git -C "$repo_root" diff --cached --quiet; then
    print "gp: staged changes exist. Run gc first." >&2; return 1
  fi

  local git_cmd=(git -C "$repo_root")
  local branch
  branch=$($git_cmd symbolic-ref -q --short HEAD || true)
  [[ -z "$branch" ]] && { print "gp: detached HEAD" >&2; return 1; }

  if $git_cmd rev-parse --symbolic-full-name @{u} >/dev/null 2>&1; then
    local ahead behind
    ahead=$($git_cmd rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
    behind=$($git_cmd rev-list --count HEAD..@{u} 2>/dev/null || echo "0")

    # gca() による1件のズレ（ローカル1件先行、リモート1件先行）を検知
    if (( ahead == 1 && behind == 1 )); then
      print -n "History split detected (ahead 1, behind 1). Force push? (y/N): "
      read -r REPLY
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        $git_cmd push --force-with-lease --no-verify || return 1
        return 0
      else
        print "Push cancelled."
        return 1
      fi
    elif (( behind > 0 )); then
      # 通常の背後コミットがある場合は pull
      $git_cmd pull --no-rebase || return 1
    fi
    
    $git_cmd push --no-verify || return 1
  else
    local remote_name
    remote_name=$($git_cmd remote | head -n 1 || true)
    [[ -z "$remote_name" ]] && { print "gp: no remote" >&2; return 1; }
    $git_cmd push --no-verify -u "$remote_name" "$branch" || return 1
  fi
}

deploy() {
  emulate -L zsh
  setopt err_return pipe_fail
  _ensure_npm_path

  if ! command -v fzf >/dev/null 2>&1; then
    print "deploy: fzf not found" >&2; return 127
  fi

  local TAB=$'\t'
  local selected
  selected=$(
    printf "%s\n" \
      "ykts${TAB}$HOME/github-public/astro${TAB}ykts-astro${TAB}cloudflare-pages" \
      "trading-lab${TAB}$HOME/github-public/trading-lab${TAB}trading-lab${TAB}cloudflare-pages" \
      "xserver${TAB}$HOME/github-public/astro-xserver${TAB}-${TAB}xserver" |
    fzf \
      --exact --height 70% --reverse --border \
      --delimiter="$TAB" --with-nth=1,4 \
      --prompt="deploy> " \
      --header="enter: deploy  esc: cancel" \
      --preview="printf 'name: %s\nrepo: %s\nproject: %s\ntarget: %s\n\n' {1} {2} {3} {4}; git -C {2} status --short --branch 2>/dev/null | sed -n '1,40p'" \
      --preview-window="right:60%:wrap"
  ) || return 0

  local name repo project target
  IFS="$TAB" read -r name repo project target <<< "$selected"

  if [[ ! -d "$repo/.git" ]]; then
    print "deploy: $repo is not a git repository" >&2; return 1
  fi

  local env_file="$repo/.env.deploy"
  [[ -f "$env_file" ]] && export $(cat "$env_file")

  local git_cmd=(git -C "$repo")
  local msg default_msg
  default_msg="chore: auto-commit $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
  if (( $# > 0 )); then
    msg="$*"
  else
    print -n "commit message [enter to use auto]: "
    read -r msg
    [[ -z "$msg" ]] && msg="$default_msg"
  fi

  case "$name" in
    ykts|trading-lab)
      (cd "$repo" && npm run build) || return 1
      (cd "$repo" && ./node_modules/.bin/wrangler pages deploy dist --project-name "$project" --branch main --commit-dirty=true) || return 1
      ;;
    xserver)
      (cd "$repo" && npm run build) || return 1
      rsync -avz --delete -e "ssh -p <PORT>" "$repo/dist/" "<YOUR_XSERVER_USER>@<YOUR_XSERVER_HOST>:~/<YOUR_XSERVER_DOMAIN>/public_html/" || return 1
      ;;
    *)
      print "deploy: unknown target: $name" >&2; return 1
      ;;
  esac

  $git_cmd add -A
  if ! $git_cmd diff --cached --quiet; then
    $git_cmd commit --no-verify -m "$msg"
  fi

  local branch
  branch=$($git_cmd symbolic-ref -q --short HEAD || true)
  [[ -z "$branch" ]] && { print "deploy: detached HEAD" >&2; return 1; }

  if $git_cmd rev-parse --symbolic-full-name @{u} >/dev/null 2>&1; then
    $git_cmd pull --no-rebase || return 1
    $git_cmd push --no-verify || return 1
  else
    local remote_name
    remote_name=$($git_cmd remote | head -n 1 || true)
    [[ -n "$remote_name" ]] && $git_cmd push --no-verify -u "$remote_name" "$branch" || return 1
  fi
}

lucide() {
  emulate -L zsh
  local astro_dir="$HOME/github-public/astro"
  local lucide_ts="$astro_dir/src/lib/lucide.ts"

  [[ ! -f "$lucide_ts" ]] && { echo "lucide: $lucide_ts not found"; return 1; }

  print -n "icon name: "
  read -r REPLY
  local nm="$REPLY"
  [[ -z "$nm" ]] && { echo "lucide: cancelled"; return 0; }

  local svg_file="$astro_dir/node_modules/lucide-static/icons/$nm.svg"
  [[ ! -f "$svg_file" ]] && { echo "lucide: '$nm' not found in lucide-static"; return 1; }
  grep -q "\"$nm\":" "$lucide_ts" && { echo "lucide: '$nm' is already registered"; return 0; }

  local pc
  pc=$(perl -0777 -ne 'print $1 if /<svg[^>]*>(.*?)<\/svg>/s' "$svg_file" | tr -d '\n' | sed 's/^ *//')
  sed -i '' "s|^};$|  \"$nm\": \`$pc\`,\n};|" "$lucide_ts"
  echo "lucide: added '$nm'"
}
