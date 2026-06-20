# jules.sh
# Jules エージェント用ワークフローコマンド群。
#
# 関数一覧:
#   jules-init      Jules 用ファイルを初期化 (CLAUDE.md ガードあり)
#   jules           Issue 駆動: カレントリポジトリの GitHub Issue からタスク選択 → Jules タスク投入
#   jules-abort     進行中のタスクを中断する案内を表示
#   jules-finish    マージ後: main に戻り pull してローカルに反映
#

# ── ヘルパー ──────────────────────────────────────────────────

# 指定ディレクトリから GitHub リポ名を解決する。
_jules_resolve_repo() {
  local dir="${1:-$PWD}"
  local origin
  origin=$(git -C "$dir" remote get-url origin 2>/dev/null) || {
    echo "Error: cannot get git remote origin in $dir" >&2
    return 1
  }
  # https://github.com/owner/repo.git  or  git@github.com:owner/repo.git
  echo "$origin" \
    | sed -E 's|.*github\.com[:/]||; s|\.git$||'
}

# ── jules-init ────────────────────────────────────────────────
# Jules 用にカレントリポジトリを初期化する。CLAUDE.md があればエラー終了。
# 作成するもの:
#   AGENTS.md
#   context/conventions.md
#   context/structure.md
#   .github/ISSUE_TEMPLATE/jules-task.md

jules-init() {
  emulate -L zsh
  local base="$PWD"

  # CLAUDE.md ガード
  if [[ -f "$base/CLAUDE.md" ]]; then
    echo "Error: CLAUDE.md exists -> ClaudeCode is responsible. Will not initialize for Jules."
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
  local f
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

  echo "Initialized: $(basename "$base")"
}

# ── jules ─────────────────────────────────────────────────────
# Issue 駆動ワークフロー。
# CLAUDE.md が存在するリポジトリは ClaudeCode 担当とみなしエラー終了。

jules() {
  emulate -L zsh
  local base="$PWD"

  # CLAUDE.md ガード
  if [[ -f "$base/CLAUDE.md" ]]; then
    echo "Error: CLAUDE.md exists -> ClaudeCode is responsible. Will not run Jules."
    return 1
  fi

  # リポ解決
  local repo
  repo=$(_jules_resolve_repo "$base") || return 1

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

# ── jules-abort ───────────────────────────────────────────────
# 進行中のタスクを中断する。Jules はローカルブランチを操作しないため、
# 主にクラウドセッション側の操作方法を案内します。

jules-abort() {
  emulate -L zsh
  echo "Jules works directly with cloud sandboxes and does not manage local branches."
  echo "To abort or clean up your cloud session, use: jules remote abort (or equivalent)"
}

# ── jules-finish ──────────────────────────────────────────────
# マージ後に main を pull してローカルに反映する。
# Jules はクラウド側でブランチを作るためローカルブランチ掃除は不要。

jules-finish() {
  emulate -L zsh
  local base="$PWD"

  git checkout main
  git pull --prune
  echo "Done: $(basename "$base")"
}
