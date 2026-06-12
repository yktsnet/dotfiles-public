_aiagent_apps_dir() {
  if [[ "$1" == "public" ]]; then
    echo "$HOME/github-public"
  else
    echo "$HOME/dotfiles/apps"
  fi
}

_aiagent_branch_prefix() {
  echo "$1"
}

_aiagent_select_issue() {
  local base_dir="$1"
  local _entries=()
  local _f

  # カレントリポジトリの issues ディレクトリのみを対象にする
  for _f in "${base_dir}/issues/"*.md(N); do
    grep -q '^status: open' "$_f" 2>/dev/null || continue
    _entries+=("$(basename "$_f")	${_f}")
  done

  if [[ ${#_entries[@]} -eq 0 ]]; then
    echo "No open issues in ${base_dir}/issues" >&2
    return 1
  fi

  printf '%s\n' "${_entries[@]}" \
    | fzf --prompt="Select issue: " \
          --delimiter=$'\t' \
          --with-nth=1 \
          --preview='cat {2}'
}

_aiagent_init() {
  emulate -L zsh

  local base="$PWD"
  local app
  app=$(basename "$base")

  # 必要なディレクトリの作成
  mkdir -p \
    "$base/.claude/skills/pr-workflow" \
    "$base/context" \
    "$base/issues" \
    "$base/issues/done"
  touch "$base/issues/done/.gitkeep"

  # 必要なファイルの空作成
  local files=(
    "$base/.claude/skills/pr-workflow/SKILL.md"
    "$base/.claude/settings.json"
    "$base/context/conventions.md"
    "$base/context/structure.md"
    "$base/CLAUDE.md"
  )

  local f
  for f in $files; do
    [[ -f "$f" ]] || touch "$f"
  done

  # settings.json の初期化
  if [[ ! -s "$base/.claude/settings.json" ]]; then
    cat > "$base/.claude/settings.json" <<'EOF'
{
  "permissions": {
    "deny": []
  }
}
EOF
  fi

  # テンプレートファイルの生成
  local tmpl="$base/issues/00_template.md"
  if [[ ! -f "$tmpl" ]]; then
    cat > "$tmpl" <<'EOF'
## {タイトル}
id: {00}
skill: pr-workflow
branch-slug: {slug}
github_issue:
status: draft
type: {cleanup|fix|feat}
対象: {ファイルパス}
内容: {何をするか}
確認: {ClaudeCodeが提出前に静的チェックすべきこと}
---
## Issue作成ルール
### フィールド
- `id` : 2桁の連番。派生Issueは `08a`, `08b` 形式（元Issueをcloseして新規作成）
- `対象` : 変更・新規作成するファイルをすべて列挙する。新規は (新規) を付記
- `内容` : 目的と概要のみ。実装仕様は下のセクションに書く
- `確認` : ClaudeCodeが提出前に行う静的確認。例: lib変更時は影響callerをすべて列挙・修正済みであること。存在しないなら省略より `目視確認` と明示する
### ライフサイクル
- `status: draft` → 設計中
- `status: open`  → issue() で選択可能
- `status: close` → 完了済み（issue-finish で更新）
検証で問題が出た場合はそのIssueをcloseし、`{id}a` として新しいIssueを作成する。
元のIssueを再openしたりClaudeCodeのセッションに直接プロンプトを送ったりしない。
### 粒度
- ClaudeCodeが1セッションで完走できる量にする
- 対象ファイルの目安は7本以下
- 確認手段が2種類以上になる場合は分割を検討する
  - 例: hetで実行確認 と ブラウザ目視確認 → 別Issue
### 分割の判断基準
- バックエンドとフロントエンドは原則別PR
- 「バックエンドの結果を見てからフロントを作る」順序依存がある場合は必ず分割
- 同一レイヤーで独立してテスト・確認できるなら1つにまとめてよい
### 詳細セクション
- `内容` に収まらない仕様は `---` 以降に自由に展開する
- ファイルごとに見出しを立てる
- 実装順序が重要な場合は末尾に明記する
EOF
  fi

  echo "Initialized: $app"
}

_aiagent_abort() {
  emulate -L zsh
  local branch=$(git branch --show-current)

  if [[ ! "$branch" =~ ^claude/ ]]; then
    echo "Not on a claude/* branch: $branch"
    return 1
  fi

  print -n "Abort and delete $branch? [y/N]: "
  read -q || { echo; return 0 }
  echo

  git stash
  git worktree prune
  git checkout main
  git branch -D "$branch"
  echo "Aborted: $branch"
}

_aiagent_finish() {
  emulate -L zsh

  # 引数や固定パスを使わず、カレントディレクトリを基準にする
  local base="$PWD"

  local selected
  selected=$(_aiagent_select_issue "$base") || return 0

  local issue_file
  issue_file=$(echo "$selected" | cut -f2)

  local head_branch=""

  local open_prs
  open_prs=$(gh pr list --state open --json number,title,headRefName \
    --jq '.[] | select(.headRefName | startswith("claude/")) | "\(.number)\t\(.headRefName)\t\(.title)"' \
    2>/dev/null)

  if [[ -n "$open_prs" ]]; then
    echo "Open Claude PRs:"
    echo "$open_prs"
    print -n "PR number to merge (Enter to skip): "
    local pr_num
    read pr_num

    if [[ -z "$pr_num" ]]; then
      echo "Aborted: merge PR before running issue-finish."
      return 1
    fi

    head_branch=$(gh pr view "$pr_num" --json headRefName --jq '.headRefName' 2>/dev/null || true)
    gh pr merge "$pr_num" --merge || return 1
  else
    echo "No open Claude PRs."
  fi

  local stashed=0
  if ! git diff --quiet || [[ -n "$(git ls-files --others --exclude-standard)" ]]; then
    git stash push -u -m "pre-finish-pull" && stashed=1
  fi

  git checkout main || { (( stashed )) && git stash pop; return 1 }

  if ! git pull --prune; then
    echo "git pull failed. Fix manually."
    (( stashed )) && git stash pop
    return 1
  fi

  (( stashed )) && git stash pop

  local unmerged
  unmerged=$(git branch --no-merged main | grep "claude/")
  if [[ -n "$unmerged" ]]; then
    echo "Warning: unmerged claude branches:"
    echo "$unmerged"
  fi

  local merged_branch
  git branch --merged main --format='%(refname:short)' | grep "^claude/" | while read -r merged_branch; do
    [[ -n "$merged_branch" ]] && git branch -d "$merged_branch"
    [[ -n "$merged_branch" ]] && git push origin --delete "$merged_branch" 2>/dev/null || true
  done
  git worktree prune

  local close_file="$issue_file"
  local issues_dir="$base/issues"

  if [[ "$head_branch" =~ ^claude/([0-9]+[a-z]?)- ]]; then
    local pid="${match[1]}"
    local f
    for f in "$issues_dir"/*.md; do
      [[ -f "$f" ]] || continue
      grep -q "^id: ${pid}$" "$f" || continue
      grep -q '^status: open$' "$f" || continue
      close_file="$f"
      break
    done
    echo "Close target: $(basename "$close_file")"
  fi

  if [[ -n "$close_file" && -f "$close_file" ]]; then
    sed -i '' "s/^status: open$/status: close/" "$close_file"
    git add "$close_file"

    echo "Staged:"
    git diff --cached --name-only

    if ! git commit -m "chore(issues): close $(basename "$close_file")"; then
      echo "Commit failed. Keeping staged changes for inspection."
      return 1
    fi

    echo "Closed: $(basename "$close_file")"

    if ! git push origin main; then
      echo "git push failed. Fix manually (git pull --rebase && git push)."
      return 1
    fi
  fi

  echo "Done: $(basename "$base")"
}

_aiagent_run() {
  emulate -L zsh

  local base="$PWD"

  local selected
  selected=$(_aiagent_select_issue "$base") || return 0

  local issue_file
  issue_file=$(echo "$selected" | cut -f2)

  local id branch_slug branch_name
  id=$(grep '^id:' "$issue_file" | awk '{print $2}')
  branch_slug=$(grep '^branch-slug:' "$issue_file" | awk '{print $2}')

  if [[ -z "$id" || -z "$branch_slug" ]]; then
    echo "Issue is missing id or branch-slug: $issue_file"
    return 1
  fi

  local git_root rel_path
  git_root=$(git rev-parse --show-toplevel)
  rel_path=${PWD#${git_root}/}

  local issues_rel_path
  if [[ "$git_root" == "$PWD" ]]; then
    issues_rel_path="issues/"
  else
    issues_rel_path="${rel_path}/issues/"
  fi

  local dirty_outside_issues
  dirty_outside_issues=$(git status --short --porcelain | awk '{print $2}' \
    | grep -v "^${issues_rel_path}" | grep -v '^$')
  local dirty_issues
  dirty_issues=$(git status --short --porcelain | awk '{print $2}' \
    | grep "^${issues_rel_path}" | grep -v '^$')

  if [[ -n "$dirty_outside_issues" ]]; then
    echo "Uncommitted changes:"
    git status --short
    print -n "Stash before running issue? [y/N]: "
    read -q
    local _ans=$?
    read -rs -k1 2>/dev/null || true
    echo
    (( _ans == 0 )) && git stash push \
        -m "pre-issue: $(basename "$issue_file")" \
        -- ":(exclude)${issues_rel_path}" \
      || return 0
  elif [[ -n "$dirty_issues" ]]; then
    git add issues/
    git commit -m "chore(issues): update"
  fi

  branch_name="claude/${id}-${branch_slug}"

  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    echo "Branch ${branch_name} already exists. Abort or delete it first."
    return 1
  fi

  print -n "Run pr-workflow with Claude Code for $(basename "$issue_file")? [y/N]: "
  read -q
  local _ans2=$?
  read -rs -k1 2>/dev/null || true
  echo
  (( _ans2 == 0 )) || return 0

  claude --model sonnet --system-prompt \
    "You are the Builder. Implement based on the Issue file. Create a PR when done. Do NOT design new Issues or modify issue files." \
    "/pr-workflow $issue_file"

  local rc=$?
  return $rc
}

issue() {
  emulate -L zsh
  _aiagent_run "$@"
}

issue-init() {
  emulate -L zsh
  _aiagent_init "$@"
}

issue-abort() {
  emulate -L zsh
  _aiagent_abort "$@"
}

issue-finish() {
  emulate -L zsh
  _aiagent_finish "$@"
}

issue-answer() {
  emulate -L zsh
  local pre_issues_dir="$HOME/dotfiles/apps/cleaner/issues/pre-issues"

  local selected
  selected=$(grep -rl '^status: pending' "$pre_issues_dir"/*.md(N) 2>/dev/null \
    | fzf --prompt="Select pre-issue to answer: " --preview='cat {}') || return 0

  [[ -z "$selected" ]] && return 0

  sed -i '' "s/^status: pending$/status: answered/" "$selected"

  pushd "$HOME/dotfiles" > /dev/null || return 1
  git add "$selected"
  git commit -m "chore(cleaner): answer $(basename "$selected")"
  popd > /dev/null

  echo "Answered: $(basename "$selected")"
}

issue-pull() {
  rsync -avz sv6:~/dotfiles/apps/cleaner/issues/pre-issues/ \
    "$HOME/dotfiles/apps/cleaner/issues/pre-issues/"
  local pending=$(grep -rl '^status: pending' \
    "$HOME/dotfiles/apps/cleaner/issues/pre-issues/"*.md(N) 2>/dev/null \
    | grep -v '00_template.md')
  [[ -n "$pending" ]] && echo "New pre-issues:" && echo "$pending" | xargs -n1 basename
}
