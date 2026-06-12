# jules.sh
# Jules エージェント用ワークフローコマンド群。
# claude.sh と同じく zsh/neo/ に置き、init.nix で source する。
#
# 関数一覧:
#   jules-init [public]    Jules 用ファイルを初期化 (CLAUDE.md ガードあり)
#   jules [public]         Issue 駆動: gh issue → fzf → Jules タスク投入
#   jules-sidecar [public] サイドカー: タスク選択 → Jules タスク投入 (ガードなし)
#   jules-finish [public]  マージ後: main pull でローカルに反映
#
# 引数なし → ~/dotfiles/apps/
# public   → ~/github-public/

# ── ヘルパー ──────────────────────────────────────────────────

_jules_apps_dir() {
  if [[ "$1" == "public" ]]; then
    echo "$HOME/github-public"
  else
    echo "$HOME/dotfiles/apps"
  fi
}

# 指定ディレクトリから GitHub リポ名を解決する。
# dotfiles/apps 配下 → yktsnet/dotfiles (monorepo)
# github-public 配下 → git remote origin から解決
_jules_resolve_repo() {
  local dir="${1:-$PWD}"
  local dotfiles_apps="$HOME/dotfiles/apps"
  local github_public="$HOME/github-public"

  if [[ "$dir" == "$dotfiles_apps"/* ]]; then
    echo "yktsnet/dotfiles"
  elif [[ "$dir" == "$github_public"/* ]]; then
    local origin
    origin=$(git -C "$dir" remote get-url origin 2>/dev/null) || {
      echo "Error: cannot get git remote origin in $dir" >&2
      return 1
    }
    # https://github.com/owner/repo.git  or  git@github.com:owner/repo.git
    echo "$origin" \
      | sed -E 's|.*github\.com[:/]||; s|\.git$||'
  else
    echo "Error: $dir is not under dotfiles/apps or github-public" >&2
    return 1
  fi
}

# dotfiles monorepo の場合は apps/{app}/ を scope とする。
# github-public の場合は scope 空 (リポルート)。
_jules_scope() {
  local apps_dir="$1"
  local app="$2"
  if [[ "$apps_dir" == "$HOME/dotfiles/apps" ]]; then
    echo "apps/${app}/"
  else
    echo ""
  fi
}

# ── jules-init ────────────────────────────────────────────────
# Jules 用にリポを初期化する。CLAUDE.md があればエラー終了。
# 作成するもの:
#   AGENTS.md
#   context/conventions.md
#   context/structure.md
#   .github/ISSUE_TEMPLATE/jules-task.md

jules-init() {
  emulate -L zsh
  local apps_dir=$(_jules_apps_dir "$1")

  local app
  app=$(ls -d "$apps_dir"/*/ | xargs -n1 basename | fzf --prompt="Select repo: ") || return 0

  local base="$apps_dir/$app"

  # CLAUDE.md ガード
  if [[ -f "$base/CLAUDE.md" ]]; then
    echo "Error: $app has CLAUDE.md → ClaudeCode 担当。Jules では初期化しない。"
    return 1
  fi

  mkdir -p \
    "$base/context" \
    "$base/.github/ISSUE_TEMPLATE"

  # AGENTS.md
  local agents_md="$base/AGENTS.md"
  if [[ ! -f "$agents_md" ]]; then
    cat > "$agents_md" <<'EOF'
# AGENTS.md

## Project overview
<!-- プロジェクトの概要を書く -->

## Scope
<!-- Jules が触っていいファイル・ディレクトリを明記する -->

## Conventions
@context/conventions.md

## Structure
@context/structure.md

## Constraints
- Do not modify files outside the declared scope above.
- Do not add dependencies without explicit instruction.
- PR description must include: what changed, why, and how to verify.
EOF
    echo "Created: AGENTS.md"
  else
    echo "Skip (exists): AGENTS.md"
  fi

  # context/
  for f in "$base/context/conventions.md" "$base/context/structure.md"; do
    [[ -f "$f" ]] || { touch "$f"; echo "Created: ${f#$base/}" }
  done

  # GitHub Issue テンプレート
  local tmpl="$base/.github/ISSUE_TEMPLATE/jules-task.md"
  if [[ ! -f "$tmpl" ]]; then
    cat > "$tmpl" <<'EOF'
---
name: Jules Task
about: Jules に投げる実装タスク
labels: jules
---

## 対象
<!-- 変更・新規作成するファイルを列挙 -->

## 内容
<!-- 何をするか。目的と概要のみ -->

## 確認
<!-- Jules が PR 提出前に行うべき静的確認。不要なら "目視確認" と明記 -->
EOF
    echo "Created: .github/ISSUE_TEMPLATE/jules-task.md"
  else
    echo "Skip (exists): .github/ISSUE_TEMPLATE/jules-task.md"
  fi

  echo "Initialized: $app"
}

# ── jules ─────────────────────────────────────────────────────
# Issue 駆動ワークフロー。
# CLAUDE.md が存在する app は ClaudeCode 担当とみなしエラー終了。

jules() {
  emulate -L zsh
  local apps_dir=$(_jules_apps_dir "$1")

  local app
  app=$(ls -d "$apps_dir"/*/ | xargs -n1 basename | fzf --prompt="Select app: ") || return 0

  local app_dir="$apps_dir/$app"

  # CLAUDE.md ガード
  if [[ -f "$app_dir/CLAUDE.md" ]]; then
    echo "Error: $app has CLAUDE.md → ClaudeCode 担当。Jules では操作しない。"
    return 1
  fi

  # リポ解決
  local repo
  repo=$(_jules_resolve_repo "$app_dir") || return 1

  # GitHub Issue 一覧 (jules ラベル)
  local issue_json
  issue_json=$(gh issue list \
    --repo "$repo" \
    --label jules \
    --state open \
    --json number,title,body \
    --limit 30 2>/dev/null)

  if [[ -z "$issue_json" || "$issue_json" == "[]" ]]; then
    echo "No open issues with label 'jules' in $repo"
    return 0
  fi

  # fzf で issue 選択
  local selected
  selected=$(echo "$issue_json" \
    | python3 -c "
import json, sys
issues = json.load(sys.stdin)
for i in issues:
    print(f\"{i['number']}\t{i['title']}\")
" | fzf --prompt="Select issue: " --preview="echo {}") || return 0

  local issue_number
  issue_number=$(echo "$selected" | awk '{print $1}')

  # issue body を session prompt として使用
  local session
  session=$(echo "$issue_json" \
    | python3 -c "
import json, sys
num = int('$issue_number')
issues = json.load(sys.stdin)
for i in issues:
    if i['number'] == num:
        print(i['body'])
        break
")

  if [[ -z "$session" ]]; then
    echo "Error: could not extract issue body"
    return 1
  fi

  echo "Repo : $repo"
  echo "Issue: #${issue_number} $(echo "$selected" | cut -f2-)"
  print -n "Run Jules for this issue? [y/N]: "
  read -q
  local _ans=$?
  read -rs -k1 2>/dev/null || true
  echo
  (( _ans == 0 )) || return 0

  jules remote new --repo "$repo" --session "$session"
}

# ── jules-sidecar ─────────────────────────────────────────────
# サイドカーワークフロー。ガードなし。どの app にも打てる。
# apps/zsh/jules_tasks.py からタスクを選択して Jules に投入する。

jules-sidecar() {
  emulate -L zsh
  local apps_dir=$(_jules_apps_dir "$1")

  local _tasks_py="$HOME/dotfiles/apps/zsh/jules_tasks.py"

  local app
  app=$(ls -d "$apps_dir"/*/ | xargs -n1 basename | fzf --prompt="Select app: ") || return 0

  local app_dir="$apps_dir/$app"

  # リポ解決
  local repo
  repo=$(_jules_resolve_repo "$app_dir") || return 1

  # scope 解決
  local scope
  scope=$(_jules_scope "$apps_dir" "$app")

  # タスク選択
  local selected
  selected=$(python3 "$_tasks_py" list \
    | fzf --prompt="Select task: " --with-nth=2.. --delimiter='\t') || return 0

  local task_index
  task_index=$(echo "$selected" | awk -F'\t' '{print $1}')

  # prompt 生成 (scope 置換済み)
  local session
  if [[ -n "$scope" ]]; then
    session=$(python3 "$_tasks_py" prompt "$task_index" --scope "$scope")
  else
    session=$(python3 "$_tasks_py" prompt "$task_index")
  fi

  echo "Repo : $repo"
  echo "Scope: ${scope:-"(repo root)"}"
  echo "Task : $(echo "$selected" | cut -f2-)"
  print -n "Run Jules? [y/N]: "
  read -q
  local _ans=$?
  read -rs -k1 2>/dev/null || true
  echo
  (( _ans == 0 )) || return 0

  jules remote new --repo "$repo" --session "$session"
}

# ── jules-finish ──────────────────────────────────────────────
# マージ後に main を pull してローカルに反映する。
# Jules はクラウド側でブランチを作るためローカルブランチ掃除は不要。

jules-finish() {
  emulate -L zsh
  local apps_dir=$(_jules_apps_dir "$1")

  local app
  app=$(ls -d "$apps_dir"/*/ | xargs -n1 basename | fzf --prompt="Select app: ") || return 0

  pushd "$apps_dir/$app" > /dev/null || return 1
  git checkout main
  git pull --prune
  popd > /dev/null
  echo "Done: $app"
}
