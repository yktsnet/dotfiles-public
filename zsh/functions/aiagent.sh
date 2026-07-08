_aiagent_confirm() {
  print -n "$1 [y/N]: "
  local ans
  read -r ans
  [[ "$ans" == [yY]* ]]
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

_aiagent_abort() {
  emulate -L zsh

  local -a entries=()
  local key val wt_path="" wt_branch=""
  git worktree list --porcelain | while read -r key val; do
    case "$key" in
      worktree) wt_path="$val" ;;
      branch)
        wt_branch="${val#refs/heads/}"
        [[ "$wt_branch" == claude/* ]] && entries+=("${wt_branch}	${wt_path}")
        ;;
    esac
  done

  if [[ ${#entries[@]} -eq 0 ]]; then
    echo "No claude/* worktrees."
    return 0
  fi

  local selected
  selected=$(printf '%s\n' "${entries[@]}" \
    | fzf --prompt="Abort worktree: " --delimiter=$'\t' --with-nth=1)
  [[ -z "$selected" ]] && return 0

  local branch dir
  branch=$(echo "$selected" | cut -f1)
  dir=$(echo "$selected" | cut -f2)

  _aiagent_confirm "Abort and delete ${branch} (${dir})?" || return 0

  git worktree remove --force "$dir"
  git branch -D "$branch"
  echo "Aborted: $branch"
}

_aiagent_finish() {
  emulate -L zsh

  local base
  base=$(git rev-parse --show-toplevel)
  local issues_dir="$base/issues"
  local close_file=""
  local head_branch=""

  if [[ "$(git branch --show-current)" != "main" ]]; then
    git checkout main || return 1
  fi

  if ! git pull --prune; then
    echo "git pull failed. Fix manually."
    return 1
  fi

  # ローカルの未マージ claude/* ブランチを選び、記録用に push → PR作成 → squash マージする
  # （Builder はリモートに触れないので、レビュー済みのものだけがここで初めて公開される）
  local pr_num pr_title pr_body pr_url
  local branch_list
  branch_list=$(git branch --no-merged main --format='%(refname:short)' | grep '^claude/')

  if [[ -n "$branch_list" ]]; then
    head_branch=$(echo "$branch_list" \
      | fzf --prompt="Merge branch (esc to skip): " \
            --preview='git log --oneline main..{}; echo; git diff --stat main...{}')
    if [[ -n "$head_branch" ]]; then
      git log --oneline "main..${head_branch}"
      _aiagent_confirm "Push, create PR and merge ${head_branch}?" || head_branch=""
    fi
    if [[ -n "$head_branch" ]]; then
      pr_title=$(git log -1 --format='%s' "$head_branch")
      pr_body=$(git log -1 --format='%b' "$head_branch")
      git push -u origin "$head_branch" || return 1
      pr_url=$(printf '%s\n' "$pr_body" \
        | gh pr create --base main --head "$head_branch" --title "$pr_title" --body-file -) || return 1
      pr_num="${pr_url##*/}"
      if ! gh pr merge "$pr_num" --squash; then
        # 即時マージ失敗（必須ステータスチェック等）→ auto-merge にフォールバックし、CI完了とマージ完了を待つ
        echo "Immediate merge blocked (likely required status checks). Falling back to auto-merge."
        gh pr merge "$pr_num" --squash --auto || return 1
        if ! gh pr checks "$pr_num" --watch --fail-fast; then
          echo "Required checks failed for PR #${pr_num}. Merge aborted."
          return 1
        fi
        # auto-merge は checks 通過後に GitHub 側で非同期にマージされるため、MERGED になるまでポーリングする（上限3分）
        local wait_elapsed=0 pr_state=""
        while (( wait_elapsed < 180 )); do
          pr_state=$(gh pr view "$pr_num" --json state --jq '.state' 2>/dev/null)
          [[ "$pr_state" == "MERGED" ]] && break
          sleep 5
          (( wait_elapsed += 5 ))
        done
        if [[ "$pr_state" != "MERGED" ]]; then
          echo "Timed out waiting for PR #${pr_num} to merge after checks passed. Check manually."
          return 1
        fi
      fi
      # squash マージ後の pull は、main 側に残る untracked の issue ファイルと衝突する
      # （マージ後は origin 由来の tracked ファイルとして戻ってくるため、pull 前に退避する）
      local merge_pid=""
      [[ "$head_branch" =~ ^claude/([0-9]+[a-z]?)- ]] && merge_pid="${match[1]}"
      if [[ -n "$merge_pid" ]]; then
        local f
        for f in "$issues_dir"/*.md(N); do
          [[ -f "$f" ]] || continue
          grep -q "^id: ${merge_pid}$" "$f" || continue
          [[ "$(git status --porcelain -- "$f")" == '??'* ]] && rm -f "$f"
        done
      fi

      if ! git pull --prune; then
        echo "git pull failed after merge. Fix manually."
        return 1
      fi
      # squash マージは main の履歴にブランチのコミットが含まれず --merged で検出できないため、ここで明示的に掃除する
      local squashed_wt
      squashed_wt=$(git worktree list --porcelain \
        | awk -v b="refs/heads/${head_branch}" '$1 == "worktree" { p = $2 } $1 == "branch" && $2 == b { print p }')
      [[ -n "$squashed_wt" ]] && git worktree remove --force "$squashed_wt"
      git branch -D "$head_branch" || echo "Warning: failed to delete local branch ${head_branch}. Delete manually."
      git push origin --delete "$head_branch" 2>/dev/null || true
    fi
  else
    echo "No unmerged claude/* branches."
  fi

  local unmerged
  unmerged=$(git branch --no-merged main | grep "claude/")
  if [[ -n "$unmerged" ]]; then
    echo "Warning: unmerged claude branches:"
    echo "$unmerged"
  fi

  # マージ済み claude/* の worktree を先に外し、ブランチを削除
  local key val wt_path="" wt_branch=""
  git worktree list --porcelain | while read -r key val; do
    case "$key" in
      worktree) wt_path="$val" ;;
      branch)
        wt_branch="${val#refs/heads/}"
        if [[ "$wt_branch" == claude/* ]] \
          && git branch --merged main --format='%(refname:short)' | grep -qx "$wt_branch"; then
          git worktree remove --force "$wt_path"
        fi
        ;;
    esac
  done
  git worktree prune

  local merged_branch
  git branch --merged main --format='%(refname:short)' | grep "^claude/" | while read -r merged_branch; do
    [[ -n "$merged_branch" ]] && git branch -d "$merged_branch"
    [[ -n "$merged_branch" ]] && git push origin --delete "$merged_branch" 2>/dev/null || true
  done

  if [[ -n "$head_branch" && "$head_branch" =~ ^claude/([0-9]+[a-z]?)- ]]; then
    local pid="${match[1]}"
    local f
    for f in "$issues_dir"/*.md; do
      [[ -f "$f" ]] || continue
      grep -q "^id: ${pid}$" "$f" || continue
      grep -q '^status: open$' "$f" || continue
      close_file="$f"
      break
    done
    if [[ -n "$close_file" ]]; then
      echo "Close target (auto-detected): $(basename "$close_file")"
    fi
  fi

  if [[ -z "$close_file" ]]; then
    local selected
    selected=$(_aiagent_select_issue "$base") || return 0
    close_file=$(echo "$selected" | cut -f2)
  fi

  if [[ -n "$close_file" && -f "$close_file" ]]; then
    # 記録用 GitHub Issue（形だけ残す。作成→即クローズ。失敗してもフローは止めない）
    local gh_num
    gh_num=$(grep '^github_issue:' "$close_file" | awk '{print $2}' | tr -d '\r\n[:space:]')
    if [[ -z "$gh_num" ]]; then
      local rec_id rec_type rec_title issue_url
      rec_id=$(grep '^id:' "$close_file" | awk '{print $2}')
      rec_type=$(grep '^type:' "$close_file" | awk '{print $2}')
      rec_title=$(head -n 1 "$close_file" | sed 's/^##[[:space:]]*//')
      issue_url=$(gh issue create --title "${rec_type}: [#${rec_id}] ${rec_title}" --body-file "$close_file" 2>/dev/null)
      if [[ -n "$issue_url" ]]; then
        gh_num=$(echo "${issue_url##*/}" | tr -d '\r\n[:space:]')
        sed -i "s/^github_issue:.*$/github_issue: ${gh_num}/" "$close_file"
        echo "Record: GitHub Issue #${gh_num}"
      else
        echo "Warning: Failed to create record GitHub Issue. Continuing."
      fi
    fi
    if [[ -n "$gh_num" ]]; then
      gh issue close "$gh_num" 2>/dev/null || echo "Warning: Failed to close GitHub Issue #${gh_num}."
    fi

    sed -i "s/^status: open$/status: close/" "$close_file"
    git add "$close_file"

    echo "Staged:"
    git diff --cached --name-only

    if ! git commit -m "chore(issues): close $(basename "$close_file")"; then
      echo "Commit failed. Keeping staged changes for inspection."
      return 1
    fi

    if git push origin main; then
      echo "Closed: $(basename "$close_file")"
    else
      echo "Warning: git push failed. Push main manually."
    fi
  fi

  echo "Done: $(basename "$base")"
}

_aiagent_run() {
  emulate -L zsh

  local base="$PWD"
  local current_branch
  current_branch=$(git branch --show-current)
  if [[ "$current_branch" != "main" ]]; then
    echo "Not on main: $current_branch"
    return 1
  fi

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

  branch_name="claude/${id}-${branch_slug}"
  local wt_dir="${git_root}.wt/${id}-${branch_slug}"

  if git show-ref --verify --quiet "refs/heads/${branch_name}"; then
    echo "Branch ${branch_name} already exists. Abort or delete it first."
    return 1
  fi
  if [[ -e "$wt_dir" ]]; then
    echo "Worktree ${wt_dir} already exists. Remove it first."
    return 1
  fi

  _aiagent_confirm "Run pr-workflow with Claude Code for $(basename "$issue_file")?" || return 0

  # worktree に隔離して実行（main のチェックアウトを汚さない・並列実行可）
  git worktree add "$wt_dir" -b "$branch_name" || return 1

  local wt_app_dir="$wt_dir"
  [[ "$git_root" != "$PWD" ]] && wt_app_dir="${wt_dir}/${rel_path}"

  # issue ファイル（main 側では untracked のまま）をブランチにコピーしてコミットする。
  # 各ブランチ上でのみ open コミットを行うことで、main 直積みに伴う並行 Issue の混入や
  # 後発ブランチへの先発 open コミットの混入を防ぐ
  local issue_file_rel="${issue_file#${git_root}/}"
  if [[ -n "$(git status --porcelain -- "$issue_file")" ]]; then
    cp "$issue_file" "${wt_dir}/${issue_file_rel}"
    git -C "$wt_dir" add "$issue_file_rel"
    git -C "$wt_dir" commit -m "chore(issues): open $(basename "$issue_file")"
  fi

  (
    cd "$wt_app_dir" || exit 1
    claude --model sonnet --system-prompt \
      "You are the Builder. Implement based on the Issue file and commit locally when done. Do NOT push, create PRs, or touch the remote. Do NOT design new Issues or modify issue files." \
      "/pr-workflow ${wt_app_dir}/issues/$(basename "$issue_file")"
  )
}

issue() {
  emulate -L zsh
  _aiagent_run "$@"
}

issue-abort() {
  emulate -L zsh
  _aiagent_abort "$@"
}

issue-finish() {
  emulate -L zsh
  _aiagent_finish "$@"
}
