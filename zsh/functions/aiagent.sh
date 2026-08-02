_aiagent_confirm() {
  print -n "$1 [y/N]: "
  local ans
  read -r ans
  [[ "$ans" == [yY]* ]]
}

# sed -i の in-place 引数は BSD（macOS）と GNU（NixOS）で非互換なため吸収する
_aiagent_sed_inplace() {
  local expr="$1" file="$2"
  if sed --version >/dev/null 2>&1; then
    sed -i "$expr" "$file"
  else
    sed -i '' "$expr" "$file"
  fi
}

# main を origin/main に追従させる。
# 前提となる運用: main 上のローカル変更は Issue ドキュメント・settings 等の周辺ファイルのみで、
# コードの実体は常に claude/* ブランチ → PR 経由で origin に入る。この前提の下では
#   - 未コミット変更は --autostash で退避・復元してよい
#   - コミット済みローカル変更と origin の衝突は origin 側（squash マージ後の姿）を正としてよい
# ため、人手の解決を待たず機械的に同期を完了させる。
_aiagent_pull_main() {
  emulate -L zsh

  # draft issueファイル等が何らかの理由でintent-to-add(空blob)としてindexに乗ると、
  # 「main上のissueファイルは常にuntracked」という前提(_aiagent_run参照)が崩れ、
  # 直後のautostash用git stashが "Entry not uptodate. Cannot merge." で失敗する。
  # intent-to-addは`git diff --cached`には出ない(git仕様)ため、`git status --porcelain=v2`の
  # XY列が".A"(staged側は無変更・worktree側のみ追加)のエントリで検出し、untrackedへ戻す。
  local f
  for f in "${(@f)$(git status --porcelain=v2 2>/dev/null | awk '$2==".A"{ sub(/^([^ ]+ +){8}/,""); print }')}"; do
    [[ -n "$f" ]] && git reset -- "$f" >/dev/null
  done

  if ! git fetch --prune origin; then
    echo "git fetch failed. Fix manually."
    return 1
  fi

  # -X ours: rebase 中の "ours" は origin/main 側。衝突ハンクは origin を採用する
  if ! git rebase --autostash -X ours origin/main; then
    git rebase --abort 2>/dev/null
    echo "Failed to sync main with origin/main. Fix manually:"
    git status --short
    return 1
  fi
}

_aiagent_select_issue() {
  local base_dir="$1"
  local _entries=()
  local _f

  # カレントリポジトリの issues ディレクトリ直下のみを対象にする
  for _f in "${base_dir}/issues/"*.md(N); do
    head -n 15 "$_f" 2>/dev/null | grep -q '^status:[[:space:]]*open$' || continue
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

_aiagent_select_draft_issue() {
  local base_dir="$1"
  local _entries=()
  local _f

  for _f in "${base_dir}/issues/"*.md(N); do
    head -n 15 "$_f" 2>/dev/null | grep -q '^status:[[:space:]]*draft$' || continue
    _entries+=("$(basename "$_f")	${_f}")
  done

  if [[ ${#_entries[@]} -eq 0 ]]; then
    echo "No draft issues in ${base_dir}/issues" >&2
    return 1
  fi

  printf '%s\n' "${_entries[@]}" \
    | fzf --prompt="Select draft issue: " \
          --delimiter=$'\t' \
          --with-nth=1 \
          --preview='cat {2}'
}

# git の管理簿に居ない {repo}.wt/ 配下の残骸を消す（.wt は issue() 専用領域なので安全）
_aiagent_sweep_wt() {
  emulate -L zsh
  local git_root wt_base
  git_root=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  wt_base="${git_root}.wt"
  [[ -d "$wt_base" ]] || return 0
  local -a registered=(${(f)"$(git worktree list --porcelain | awk '$1=="worktree"{print $2}')"})
  local d
  for d in "$wt_base"/*(N/); do
    if (( ! ${registered[(Ie)$d]} )); then
      rm -rf "$d"
      echo "Removed stale worktree dir: $d"
    fi
  done
  rmdir "$wt_base" 2>/dev/null || true
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
  _aiagent_sweep_wt
  echo "Aborted: $branch"
}

_aiagent_open() {
  emulate -L zsh

  local base
  base=$(git rev-parse --show-toplevel) || return 1

  local selected
  selected=$(_aiagent_select_draft_issue "$base") || return 0

  local target_file
  target_file=$(echo "$selected" | cut -f2)

  _aiagent_sed_inplace "s/^status: draft$/status: open/" "$target_file"
  echo "Opened: $(basename "$target_file")"

  cd "$base" || return 1
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

  _aiagent_pull_main || return 1

  # ローカルの未マージ claude/* ブランチを選び、記録用に push → PR作成 → squash マージする
  # （Builder はリモートに触れないので、レビュー済みのものだけがここで初めて公開される）
  local pr_num pr_title pr_body pr_url pr_merge_sha
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
      pr_merge_sha=$(gh pr view "$pr_num" --json mergeCommit --jq '.mergeCommit.oid' 2>/dev/null)

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

      _aiagent_pull_main || return 1
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
  _aiagent_sweep_wt

  local merged_branch
  git branch --merged main --format='%(refname:short)' | grep "^claude/" | while read -r merged_branch; do
    [[ -n "$merged_branch" ]] && git branch -d "$merged_branch"
    [[ -n "$merged_branch" ]] && git push origin --delete "$merged_branch" 2>/dev/null || true
  done

  # id だけでなく branch-slug も一致させる（同一 id の派生 Issue を取り違えないため）
  if [[ -n "$head_branch" && "$head_branch" =~ ^claude/([0-9]+[a-z]?)-(.*)$ ]]; then
    local pid="${match[1]}"
    local branch_slug="${match[2]}"
    local f
    for f in "$issues_dir"/*.md; do
      [[ -f "$f" ]] || continue
      grep -q "^id: ${pid}$" "$f" || continue
      local file_slug
      file_slug=$(grep '^branch-slug:' "$f" | awk '{print $2}' | tr -d '\r\n[:space:]')
      [[ -n "$branch_slug" && "$file_slug" == "$branch_slug" ]] || continue
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
    local rec_id
    rec_id=$(grep '^id:' "$close_file" | awk '{print $2}')

    # 記録用 GitHub Issue（形だけ残す。作成→即クローズ。失敗してもフローは止めない）
    local gh_num
    gh_num=$(grep '^github_issue:' "$close_file" | awk '{print $2}' | tr -d '\r\n[:space:]')
    if [[ -z "$gh_num" ]]; then
      local rec_type rec_title issue_url
      rec_type=$(grep '^type:' "$close_file" | awk '{print $2}')
      rec_title=$(head -n 1 "$close_file" | sed 's/^##[[:space:]]*//')
      issue_url=$(gh issue create --title "${rec_type}: [#${rec_id}] ${rec_title}" --body-file "$close_file" 2>/dev/null)
      if [[ -n "$issue_url" ]]; then
        gh_num=$(echo "${issue_url##*/}" | tr -d '\r\n[:space:]')
        _aiagent_sed_inplace "s/^github_issue:.*$/github_issue: ${gh_num}/" "$close_file"
        echo "Record: GitHub Issue #${gh_num}"
      else
        echo "Warning: Failed to create record GitHub Issue. Continuing."
      fi
    fi
    if [[ -n "$gh_num" ]]; then
      gh issue close "$gh_num" 2>/dev/null || echo "Warning: Failed to close GitHub Issue #${gh_num}."
    fi

    _aiagent_sed_inplace "s/^status: open$/status: close/" "$close_file"

    # マージされたPRの内容は別ファイルとして issues/done/ に記録する（Issueファイル自体は移動しない）
    local commit_paths=("$close_file")
    if [[ -n "$pr_num" ]]; then
      mkdir -p "$issues_dir/done"
      local done_file="$issues_dir/done/$(basename "$close_file")"
      {
        echo "## PR記録: ${pr_title:-#$pr_num}"
        echo "issue: ${rec_id:-unknown} ($(basename "$close_file"))"
        echo "PR: ${pr_url:-#$pr_num}"
        [[ -n "$pr_merge_sha" ]] && echo "Merged: $pr_merge_sha"
        if [[ -n "$pr_body" ]]; then
          echo ""
          echo "$pr_body"
        fi
      } > "$done_file"
      commit_paths+=("$done_file")
    fi

    if git -C "$base" add "${commit_paths[@]}" \
      && git -C "$base" commit -m "chore(issues): close ${rec_id:-$(basename "$close_file")}" >/dev/null; then
      echo "Committed: ${commit_paths[*]}"
      git -C "$base" push || echo "Warning: Failed to push. Push manually."
    else
      echo "Warning: Failed to commit ${commit_paths[*]}. Commit manually."
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
    mkdir -p "$(dirname "${wt_dir}/${issue_file_rel}")"
    cp "$issue_file" "${wt_dir}/${issue_file_rel}"
    git -C "$wt_dir" add "$issue_file_rel"
    git -C "$wt_dir" commit -m "chore(issues): open $(basename "$issue_file")"
  fi

  # tmux内なら別ペインでBuilderの変更をライブ表示する（working tree・コミット済みを問わずmain比較で追従）
  if [[ -n "$TMUX" ]]; then
    tmux split-window -h -c "$wt_app_dir" "hunk diff main --watch"
  fi

  (
    cd "$wt_app_dir" || exit 1
    claude --model claude-sonnet-5 --system-prompt \
      "You are the Builder. Implement based on the Issue file and commit locally when done. Do NOT push, create PRs, or touch the remote. Do NOT design new Issues or modify issue files." \
      "/pr-workflow ${wt_dir}/${issue_file_rel}"
  )

  # tmux外だった場合のみ、実行者の終了後にmain未マージのコミットがあればhunkでレビューを開く
  # （tmux内は上で開いた別ペインが既にレビュー導線になっているため何もしない。open コミットのみなら開かない）
  if [[ -z "$TMUX" ]] && [[ -n "$(git log main.."$branch_name" --oneline 2>/dev/null | grep -v 'chore(issues): open')" ]]; then
    echo "Opening hunk review: ${branch_name} vs main"
    (cd "$wt_dir" && hunk diff main)
  fi
}

_aiagent_import_pr() {
  emulate -L zsh
  local pr_num=$1
  if [[ -z "$pr_num" ]]; then
    echo "Usage: issue-import-pr <PR_NUMBER>"
    return 1
  fi

  local base
  base=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$base" ]]; then
    echo "Error: Not a git repository."
    return 1
  fi

  local repo_name
  repo_name=$(git -C "$base" remote get-url origin 2>/dev/null | sed -E 's|https://github.com/([^/]+/[^/.]+)(\.git)?|\1|')
  if [[ -z "$repo_name" ]]; then
    echo "Error: Could not determine GitHub repository name."
    return 1
  fi

  local pr_title pr_body pr_url pr_merge_sha head_branch
  pr_title=$(gh pr view "$pr_num" --repo "$repo_name" --json title --jq '.title' 2>/dev/null)
  if [[ -z "$pr_title" ]]; then
    echo "Error: Failed to fetch PR #$pr_num from $repo_name."
    return 1
  fi

  pr_body=$(gh pr view "$pr_num" --repo "$repo_name" --json body --jq '.body' 2>/dev/null)
  pr_url=$(gh pr view "$pr_num" --repo "$repo_name" --json url --jq '.url' 2>/dev/null)
  pr_merge_sha=$(gh pr view "$pr_num" --repo "$repo_name" --json mergeCommit --jq '.mergeCommit.oid' 2>/dev/null || true)
  head_branch=$(gh pr view "$pr_num" --repo "$repo_name" --json headRefName --jq '.headRefName' 2>/dev/null)

  local pid="" branch_slug=""
  if [[ "$head_branch" =~ ^(claude/)?([0-9]+[a-z]?)-(.*)$ ]]; then
    pid="${match[2]}"
    branch_slug="${match[3]}"
  fi

  if [[ -z "$pid" || -z "$branch_slug" ]]; then
    echo "Error: Could not parse issue ID or branch slug from branch: $head_branch"
    return 1
  fi

  local issues_dir="$base/issues"
  local close_file=""
  local f
  for f in "$issues_dir"/*.md(N); do
    [[ -f "$f" ]] || continue
    local clean_pid=$(echo "$pid" | sed 's/^0//')
    if grep -qE "^id: (0?${clean_pid}|${pid})$" "$f"; then
      local file_slug
      file_slug=$(grep '^branch-slug:' "$f" | awk '{print $2}' | tr -d '\r\n[:space:]')
      if [[ -n "$branch_slug" && "$file_slug" == "$branch_slug" ]]; then
        close_file="$f"
        break
      fi
    fi
  done

  if [[ -z "$close_file" ]]; then
    echo "Error: Issue file not found for ID: $pid, slug: $branch_slug in: $issues_dir"
    return 1
  fi

  mkdir -p "$issues_dir/done"
  local done_file="$issues_dir/done/$(basename "$close_file")"

  {
    echo "## PR記録: ${pr_title}"
    echo "issue: ${pid} ($(basename "$close_file"))"
    echo "PR: ${pr_url}"
    [[ -n "$pr_merge_sha" ]] && echo "Merged: $pr_merge_sha"
    if [[ -n "$pr_body" ]]; then
      echo ""
      echo "$pr_body"
    fi
  } > "$done_file"

  _aiagent_sed_inplace "s/^status:.*$/status: close/" "$close_file"

  echo "Synced PR #$pr_num to $(basename "$done_file")"
}

issue() {
  emulate -L zsh
  _aiagent_run "$@"
}

issue-open() {
  emulate -L zsh
  _aiagent_open "$@"
}

issue-abort() {
  emulate -L zsh
  _aiagent_abort "$@"
}

issue-finish() {
  emulate -L zsh
  _aiagent_finish "$@"
}

issue-import-pr() {
  emulate -L zsh
  _aiagent_import_pr "$@"
}
