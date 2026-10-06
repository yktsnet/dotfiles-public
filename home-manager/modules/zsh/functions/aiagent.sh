# y/N 確認は menu.sh の _confirm、sed -i の OS 差は os.sh の _sed_i を使う
# （どちらも common.nix で本ファイルより先に読み込まれる）。

# リポ直下の issues/ を返す
_aiagent_get_issues_dirs() {
  local base_dir="$1"
  local git_root
  git_root=$(git -C "$base_dir" rev-parse --show-toplevel 2>/dev/null)
  echo "${git_root:-$base_dir}/issues"
}

# main を origin/main に追従させる。
# 前提となる運用: main 上のローカル変更は Issue ドキュメント・settings 等の周辺ファイルのみで、
# コードの実体は常に claude/* ブランチ → PR 経由で origin に入る。この前提の下では
#   - 未コミット変更は --autostash で退避・復元してよい
#   - コミット済みローカル変更と origin の衝突は origin 側（squash マージ後の姿）を正としてよい
# ため、人手の解決を待たず機械的に同期を完了させる。
# worktree で作業中に元リポの main を並行して直接編集するのは正当な使い方なので、
# main が分岐している前提で自動解決する。詰まっても運用側でなくここを疑う。
_aiagent_pull_main() {
  emulate -L zsh

  if ! git fetch --prune origin; then
    echo "git fetch failed. Fix manually."
    return 1
  fi

  # draft issueファイル等が何らかの理由でintent-to-add(空blob)としてindexに乗ると、
  # 「main上のissueファイルは常にuntracked」という前提(_aiagent_run参照)が崩れ、
  # 直後のautostash用git stashが "Entry not uptodate. Cannot merge." で失敗する。
  # intent-to-addは`git diff --cached`には出ない(git仕様)ため、`git status --porcelain=v2`の
  # XY列が".A"(staged側は無変更・worktree側のみ追加)のエントリで検出し、untrackedへ戻す。
  local f
  for f in "${(@f)$(git status --porcelain=v2 2>/dev/null | awk '$2==".A"{ sub(/^([^ ]+ +){8}/,""); print }')}"; do
    [[ -n "$f" ]] && git reset -- "$f" >/dev/null
  done

  # -X ours: rebase 中の "ours" は origin/main 側。衝突ハンクは origin を採用する
  if ! git rebase --autostash -X ours origin/main; then
    git rebase --abort 2>/dev/null
    echo "Failed to sync main with origin/main. Fix manually:"
    git status --short
    return 1
  fi
}

# 00_template.md は各 issues/ に置かれた雛型で、status: draft を持つが着手対象ではない。
# 候補にも件数にも混ぜない
_aiagent_is_template() {
  [[ "${1:t}" == "00_template.md" ]]
}

_aiagent_issue_status() {
  head -n 15 "$1" 2>/dev/null | awk '/^status:/ { print $2; exit }'
}

# カレントのリポの status: <draft|open> の件数
_aiagent_count_status() {
  emulate -L zsh
  local want="$1"
  local base
  base=$(git rev-parse --show-toplevel 2>/dev/null) || { echo 0; return }

  local n=0 f d
  for d in ${(f)"$(_aiagent_get_issues_dirs "$base")"}; do
    for f in "$d"/*.md(N); do
      _aiagent_is_template "$f" && continue
      [[ "$(_aiagent_issue_status "$f")" == "$want" ]] && (( n++ ))
    done
  done
  echo "$n"
}

# claude/* を取り出している worktree を「パス TAB ブランチ」で出す
_aiagent_worktrees() {
  emulate -L zsh
  git worktree list --porcelain 2>/dev/null \
    | awk '$1 == "worktree" { p = $2 } $1 == "branch" && $2 ~ /^refs\/heads\/claude\// { sub(/^refs\/heads\//, "", $2); print p "\t" $2 }'
}

# ブランチを取り出している worktree のパス。無ければ空
_aiagent_branch_wt() {
  git worktree list --porcelain 2>/dev/null \
    | awk -v r="refs/heads/$1" '$1 == "worktree" { p = $2 } $1 == "branch" && $2 == r { print p }'
}

# Issue ファイルから実行者のブランチの名前を組む。id が無ければ失敗する
_aiagent_issue_branch() {
  emulate -L zsh
  local id slug
  id=$(grep -m1 '^id:' "$1" | awk '{print $2}')
  [[ -n "$id" ]] || return 1
  slug=$(grep -m1 '^branch-slug:' "$1" | awk '{print $2}' | tr -d '\r\n[:space:]')
  print -r -- "claude/${id}${slug:+-${slug}}"
}

# カレントのリポの現在地。マージ済みは畳んだ後に呼ぶので、残る claude/* は PR 待ちか作業中
_aiagent_status() {
  emulate -L zsh
  local base
  base=$(git rev-parse --show-toplevel 2>/dev/null) || return 1

  print "${base:t}"
  printf '  %-9s%s\n' draft "$(_aiagent_count_status draft)" open "$(_aiagent_count_status open)"

  local -a wts=(${(f)"$(_aiagent_worktrees)"})
  printf '  %-9s%s\n' worktree "${#wts}"
  local w
  for w in "${wts[@]}"; do
    print "           ${w#*$'\t'}  (${w%%$'\t'*})"
  done

  local -a branches=(${(f)"$(git for-each-ref --format='%(refname:short)' 'refs/heads/claude/*')"})
  printf '  %-9s%s\n' branch "${#branches}"
  local b
  for b in "${branches[@]}"; do
    print "           ${b}  ($(git rev-list --count "main..$b") commits)"
  done
}

# git の管理簿に居ない {repo}.wt/ 配下の残骸を消す（.wt は i() 専用領域なので安全）
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

# worktree を畳んでよいかの判定。未コミットの変更が残っていれば畳まない
_aiagent_wt_clean() {
  emulate -L zsh
  local wt="$1"
  local dirty
  dirty=$(git -C "$wt" status --porcelain 2>/dev/null)
  if [[ -n "$dirty" ]]; then
    echo "Uncommitted changes in ${wt}:"
    echo "$dirty"
    echo "Commit or discard them, then run i again."
    return 1
  fi
}

# 実行者のブランチを捨てる。worktree が残っていれば一緒に消す。破棄なので既定は No
_aiagent_abort() {
  emulate -L zsh
  local branch="$1" wt
  wt=$(_aiagent_branch_wt "$branch")
  _confirm "Abort and delete ${branch}${wt:+ (${wt})}?" || return 0
  [[ -n "$wt" ]] && git worktree remove --force "$wt"
  git branch -D "$branch"
  _aiagent_sweep_wt
  echo "Aborted: $branch"
}

# PR を出し終えた Builder の worktree を畳む。マージは後から user が押すのでブランチは残し、
# マージ後に _aiagent_reap が消す。途中でやめたセッションの worktree は残す
_aiagent_retire_wt() {
  emulate -L zsh
  local wt="$1" branch="$2"

  local state
  state=$(gh pr view "$branch" --json state --jq '.state' 2>/dev/null)
  [[ "$state" == OPEN || "$state" == MERGED ]] || return 0
  # push 後のコミットは PR に載っていないので、worktree ごと消すと失う
  [[ "$(git rev-parse "$branch")" == "$(git rev-parse "refs/remotes/origin/${branch}" 2>/dev/null)" ]] || {
    echo "Kept ${wt}: ${branch} has commits not pushed to origin."
    return 0
  }
  _aiagent_wt_clean "$wt" || { echo "Kept ${wt}."; return 0 }
  git worktree remove --force "$wt" && echo "Removed worktree: ${wt}"
}

# squash マージ後の pull は、main に残る untracked の issue ファイルと衝突する
# （ブランチで open・close した版がマージで戻ってくる）ので、pull の前に消す。
# id は issues/ ごとに振られうるので、id ではなくブランチに同じパスがあるかで当てる
_aiagent_purge_untracked() {
  emulate -L zsh
  local base="$1" branch="$2"
  local f d rel
  for d in ${(f)"$(_aiagent_get_issues_dirs "$base")"}; do
    for f in "$d"/*.md(N); do
      [[ "$(git -C "$base" status --porcelain -- "$f")" == '??'* ]] || continue
      rel="${f#${base}/}"
      git -C "$base" cat-file -e "${branch}:${rel}" 2>/dev/null \
        || git -C "$base" cat-file -e "${branch}:${rel:h}/done/${rel:t}" 2>/dev/null \
        || continue
      rm -f "$f"
    done
  done
}

# カレントのリポのマージ済み claude/* を畳む。PR は実装役が出し、マージは user が GitHub で
# 押すので、次に i() を開いたときにここで拾う。squash マージはブランチのコミットを main の履歴に
# 残さず --merged で拾えないため、PR の状態で判定する。畳んだ本数を REPLY に返す
_aiagent_reap() {
  emulate -L zsh
  REPLY=0

  local base
  base=$(git rev-parse --show-toplevel 2>/dev/null) || return 0
  [[ "$(git branch --show-current)" == "main" ]] || return 0

  local -a branches
  branches=(${(f)"$(git for-each-ref --format='%(refname:short)' 'refs/heads/claude/*')"})

  local b state wt n=0
  for b in "${branches[@]}"; do
    state=$(gh pr view "$b" --json state --jq '.state' 2>/dev/null)
    [[ "$state" == MERGED ]] || continue
    wt=$(_aiagent_branch_wt "$b")
    if [[ -n "$wt" ]]; then
      if ! _aiagent_wt_clean "$wt"; then
        echo "Warning: kept ${b} (${wt})."
        continue
      fi
      git worktree remove --force "$wt"
    fi
    _aiagent_purge_untracked "$base" "$b"
    git branch -D "$b" >/dev/null
    git push origin --delete "$b" 2>/dev/null || true
    echo "Cleaned: $b"
    (( n++ ))
  done

  git worktree prune
  _aiagent_sweep_wt
  REPLY=$n
}

# i() が横断するリポ。要素それ自体が git リポならそのリポを、そうでなければ直下の git
# リポを対象にする（`{repo}.wt/` のように .git を持たないものは外れる）。未設定なら
# $HOME/dotfiles-public を1つだけ対象にする
_aiagent_repos() {
  emulate -L zsh
  local roots_str="${AIAGENT_REPO_ROOTS:-$HOME/dotfiles-public}"
  local -a roots=(${(z)roots_str})
  local r d
  for r in "${roots[@]}"; do
    if [[ -e "$r/.git" ]]; then
      print -r -- "$r"
    else
      for d in "$r"/*(N/); do
        [[ -e "$d/.git" ]] && print -r -- "$d"
      done
    fi
  done
}

# 全リポのマージ済み claude/* を畳む。ブランチの無いリポは gh を呼ばずに飛ばす
_aiagent_reap_all() {
  emulate -L zsh
  local repo
  for repo in ${(f)"$(_aiagent_repos)"}; do
    [[ -n "$(git -C "$repo" for-each-ref --format=x 'refs/heads/claude/*')" ]] || continue
    ( cd "$repo" && _aiagent_reap && (( REPLY )) && _aiagent_pull_main ) 2>&1 \
      | sed "s|^|${repo:t}: |"
  done
}

# i() の候補を「動作 TAB リポ TAB 対象 TAB 表示」で出す。対象は Issue ファイル・PR 番号・worktree。
# 並びは open（実装）→ draft（承認）→ PR（マージ）→ worktree（破棄）。破棄は選び間違えても確認で止まる
_aiagent_entries() {
  emulate -L zsh
  local -a runs drafts merges aborts
  local repo d f b pr
  for repo in ${(f)"$(_aiagent_repos)"}; do
    for d in ${(f)"$(_aiagent_get_issues_dirs "$repo")"}; do
      for f in "$d"/*.md(N); do
        _aiagent_is_template "$f" && continue
        case "$(_aiagent_issue_status "$f")" in
          open)
            # main 側のファイルはマージまで open のまま残る。ブランチがあれば実装中か PR 待ち
            b=$(_aiagent_issue_branch "$f") && git -C "$repo" show-ref --verify --quiet "refs/heads/${b}" && continue
            runs+=("run"$'\t'"$repo"$'\t'"$f"$'\t'"$(printf 'run      %-20s %s' "${repo:t}" "${f:t}")") ;;
          draft) drafts+=("approve"$'\t'"$repo"$'\t'"$f"$'\t'"$(printf 'approve  %-20s %s' "${repo:t}" "${f:t}")") ;;
        esac
      done
    done
    # PR を見に行くのは claude/* のブランチが残るリポだけ。gh の呼び出しは1リポ1回に収める
    if [[ -n "$(git -C "$repo" for-each-ref --format=x 'refs/heads/claude/*')" ]]; then
      for pr in ${(f)"$(cd "$repo" && gh pr list --state open --json number,title,headRefName \
        --jq '.[] | select(.headRefName | startswith("claude/")) | "\(.number)\t#\(.number) \(.title)"' 2>/dev/null)"}; do
        merges+=("merge"$'\t'"$repo"$'\t'"${pr%%$'\t'*}"$'\t'"$(printf 'merge    %-20s %s' "${repo:t}" "${pr#*$'\t'}")")
      done
    fi
    # worktree の無いブランチも並べる。PR をマージせずに閉じたブランチはここでしか拾えない
    for b in ${(f)"$(git -C "$repo" for-each-ref --format='%(refname:short)' 'refs/heads/claude/*')"}; do
      aborts+=("abort"$'\t'"$repo"$'\t'"$b"$'\t'"$(printf 'abort    %-20s %s' "${repo:t}" "$b")")
    done
  done
  (( ${#runs} + ${#drafts} + ${#merges} + ${#aborts} )) || return 0
  print -rl -- "${runs[@]}" "${drafts[@]}" "${merges[@]}" "${aborts[@]}"
}

# 球のあるリポだけ現在地を並べる
_aiagent_status_all() {
  emulate -L zsh
  local repo
  for repo in ${(f)"$(_aiagent_repos)"}; do
    (
      cd "$repo" || exit
      (( $(_aiagent_count_status draft) + $(_aiagent_count_status open) )) \
        || [[ -n "$(git for-each-ref --format=x 'refs/heads/claude/*')" ]] \
        || exit
      _aiagent_status
    )
  done
}

# 一度に起動できる本数。選ぶ判断を軽くするために絞る
_AIAGENT_CANDIDATES=3

_aiagent_builder_prompt() {
  local issues_dirs="$1"
  print -r -- "You are the Builder. Follow pr-workflow: implement and commit, then stop so the user can verify in this session, and fix what they point out with additional commits. Close this Issue and open the PR only after the user explicitly approves. Push only your own branch; never push to main, and never merge unless the user asks. Do NOT change the status of any other issue file. If you find work outside this Issue's scope, ask the user with AskUserQuestion whether to (a) file it as a new Issue, (b) fix it within this Issue, or (c) skip it. For (a), write it as status: draft following the local-issue skill's format into the main checkout's issues directory (${issues_dirs}), never into this worktree, then return to the original task. Do not stage or commit the draft."
}

# マージ済みの作業ブランチ（day/* 等）に居残っているだけなら main へ戻す。main 側の Issue は
# untracked なので持ち越せる。未マージか、追跡中のファイルに変更があれば戻さずに止める
_aiagent_back_to_main() {
  emulate -L zsh
  local cur="$1" state
  state=$(gh pr view "$cur" --json state --jq '.state' 2>/dev/null)
  if [[ "$state" != MERGED ]] \
    && ! { git fetch -q origin main 2>/dev/null && git merge-base --is-ancestor "$cur" origin/main; }; then
    echo "Not on main: ${cur} is not merged yet. Switch to main first."
    return 1
  fi
  if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
    echo "Not on main: ${cur} has uncommitted changes. Commit or stash them, then switch to main."
    return 1
  fi
  git switch -q main || return 1
  echo "Switched to main from merged ${cur}."
}

# 渡された Issue ファイル（同じリポの open）ごとに worktree を切って Builder を起動する。
# 1本なら前面で走らせ、終わったら worktree を畳む。複数なら tmux の隠しセッションに置く
_aiagent_run() {
  emulate -L zsh
  local -a files=("$@")
  (( ${#files} )) || return 0

  local git_root
  git_root=$(git rev-parse --show-toplevel) || return 1
  local cur
  cur=$(git branch --show-current)
  [[ "$cur" == "main" ]] || _aiagent_back_to_main "$cur" || return 1

  # 別の端末で進めた main から切らないと、PR が競合する
  _aiagent_pull_main || return 1

  # 複数起動は tmux の隠しセッションに置き、M-u のピッカーから入る。tmux の外では入口が無い
  if (( ${#files} > 1 )) && [[ -z "$TMUX" ]]; then
    echo "Launching multiple issues needs tmux. Run inside tmux, or select one."
    return 1
  fi

  # 起動前に全件を検証する。途中で止まって一部だけ worktree が残るのを避ける
  local -a branch_names wt_dirs
  local f branch_leaf
  for f in "${files[@]}"; do
    if ! branch_leaf=$(_aiagent_issue_branch "$f"); then
      echo "Issue is missing an id: $f"
      return 1
    fi
    branch_leaf="${branch_leaf#claude/}"

    if git show-ref --verify --quiet "refs/heads/claude/${branch_leaf}"; then
      echo "Branch claude/${branch_leaf} already exists. Abort or delete it first."
      return 1
    fi
    if [[ -e "${git_root}.wt/${branch_leaf}" ]]; then
      echo "Worktree ${git_root}.wt/${branch_leaf} already exists. Remove it first."
      return 1
    fi

    branch_names+=("claude/${branch_leaf}")
    wt_dirs+=("${git_root}.wt/${branch_leaf}")
  done

  _confirm "Run pr-workflow with Claude Code for ${(j:, :)${files[@]:t}}?" || return 0

  local -a issues_dirs=(${(f)"$(_aiagent_get_issues_dirs "$git_root")"})
  local system_prompt
  system_prompt=$(_aiagent_builder_prompt "${(j:, :)issues_dirs}")

  local -a claude_args=(--model claude-sonnet-5 --permission-mode auto)
  # スコープ外の draft は main 側の issues/ に置く（main では untracked が前提）。worktree の外なので許可を足す
  local d
  for d in "${issues_dirs[@]}"; do
    claude_args+=(--add-dir "$d")
  done

  # 後段の tmux セッションは関数ラッパを通らないので、config dir をここで決めて渡す。
  # CLAUDE_CONFIG_DIR が設定されていればそれを、無ければ既定（~/.claude.json は $HOME 直下）を使う
  local config_dir claude_bin
  config_dir="${CLAUDE_CONFIG_DIR:-$HOME}"
  claude_bin=$(whence -p claude)
  local trust_json="${config_dir}/.claude.json"
  # 隠しセッションへは、設定されているときだけ CLAUDE_CONFIG_DIR を渡す
  local -a config_env=()
  [[ -n "$CLAUDE_CONFIG_DIR" ]] && config_env=(env "CLAUDE_CONFIG_DIR=$CLAUDE_CONFIG_DIR")

  local i rel wt_dir branch_name session tmp_json
  for (( i = 1; i <= ${#files}; i++ )); do
    f=${files[$i]}
    rel="${f#${git_root}/}"
    wt_dir=${wt_dirs[$i]}
    branch_name=${branch_names[$i]}

    # worktree に隔離して実行（main のチェックアウトを汚さない・並列実行可）
    git worktree add "$wt_dir" -b "$branch_name" || return 1

    # issue ファイル（main 側では untracked のまま）をブランチにコピーしてコミットする。
    # 各ブランチ上でのみ open コミットを行うことで、main 直積みに伴う並行 Issue の混入や
    # 後発ブランチへの先発 open コミットの混入を防ぐ
    mkdir -p "$(dirname "${wt_dir}/${rel}")"
    cp "$f" "${wt_dir}/${rel}"
    git -C "$wt_dir" add "$rel"
    git -C "$wt_dir" commit -q -m "chore(issues): open ${f:t}"

    # ワークツリー等のディレクトリの信頼設定を足して、Claude Code の安全確認プロンプトをバイパスする。
    # CLAUDE_CONFIG_DIR を渡して起動するので、読まれるのは ~/.claude.json ではなく config dir 側の .claude.json。
    # jq が空を出したまま mv すると設定が消えるので、中身があるときだけ置き換える
    if [[ -f "$trust_json" ]]; then
      tmp_json=$(mktemp)
      if jq --arg r "$git_root" --arg w "$wt_dir" \
        '.projects[$r].hasTrustDialogAccepted = true | .projects[$w].hasTrustDialogAccepted = true' \
        "$trust_json" > "$tmp_json" && [[ -s "$tmp_json" ]]; then
        mv "$tmp_json" "$trust_json"
      else
        rm -f "$tmp_json"
      fi
    fi

    if (( ${#files} == 1 )); then
      (
        cd "$wt_dir" || exit 1
        claude "${claude_args[@]}" --system-prompt "$system_prompt" "/pr-workflow '${wt_dir}/${rel}'"
      )
      _aiagent_retire_wt "$wt_dir" "$branch_name"
    else
      # tmux に置いた Builder は終わりを待てないので、worktree はマージ後に _aiagent_reap が畳む。
      # tmux のセッション名に '.' と ':' は使えない
      session="claude-issue-${${branch_name#claude/}//[.:]/-}"
      tmux new-session -d -s "$session" -c "$wt_dir" -- \
        "${config_env[@]}" "$claude_bin" "${claude_args[@]}" \
        --system-prompt "$system_prompt" "/pr-workflow '${wt_dir}/${rel}'" \
        || { echo "Failed to start tmux session for ${branch_name}."; return 1 }
      echo "Started ${branch_name} in tmux session ${session} (M-u to attach)."
    fi
  done
}

# 実行者が出した PR を squash でマージし、そのまま畳んで main を追従させる。
# 実行者にはマージさせない（system prompt と pr-workflow で止めている）。人がここで押すのは流れのうち
_aiagent_merge() {
  emulate -L zsh
  local pr="$1"
  _confirm "Merge #${pr} ($(gh pr view "$pr" --json title --jq .title))?" || return 0
  if ! gh pr merge "$pr" --squash; then
    # 必須チェックが残っていると即時マージは拒まれる。auto-merge に切り替えてチェックの完了を待つ。
    # 落ちたら auto-merge を外す。有効のまま残すと、直しを push した時点で確認なしにマージされる
    echo "Immediate merge blocked (likely required checks). Switching to auto-merge."
    gh pr merge "$pr" --squash --auto || return 1
    if ! gh pr checks "$pr" --watch --fail-fast; then
      gh pr merge "$pr" --disable-auto
      echo "Required checks failed for PR #${pr}. Auto-merge disabled; merge aborted."
      return 1
    fi
    # auto-merge は GitHub 側で非同期に実行されるので、MERGED になるまで待つ（上限3分）
    local waited=0 state=""
    while (( waited < 180 )); do
      state=$(gh pr view "$pr" --json state --jq .state 2>/dev/null)
      [[ "$state" == "MERGED" ]] && break
      sleep 5
      (( waited += 5 ))
    done
    if [[ "$state" != "MERGED" ]]; then
      echo "Timed out waiting for PR #${pr} to merge after checks passed. Check manually."
      return 1
    fi
  fi
  _aiagent_reap
  _aiagent_pull_main
}

# AIAGENT_REPO_ROOTS が指すリポを横断して Issue と PR を選び、実装・承認・マージ・破棄する
# （Issue 駆動の入口）
i() {
  emulate -L zsh

  _aiagent_reap_all

  local -a items=(${(f)"$(_aiagent_entries)"})
  if (( ! ${#items} )); then
    _aiagent_status_all
    return 0
  fi
  items+=("status"$'\t'$'\t'$'\t'"status   show where everything is")

  # 複数選べるのは同じリポの run だけ。並行起動は1リポを前提にしている
  local -a sel
  sel=(${(f)"$(print -rl -- "${items[@]}" \
    | fzf --prompt="issue> " --delimiter=$'\t' --with-nth=4 \
          --multi="$_AIAGENT_CANDIDATES" --header="TAB: run up to ${_AIAGENT_CANDIDATES} from one repo" \
          --preview='if [ {1} = merge ]; then cd {2} && gh pr view {3} && echo && gh pr diff {3} --name-only; elif [ -f {3} ]; then cat {3}; fi')"})
  (( ${#sel} )) || { print "i: cancelled" >&2; return 1 }

  local action repo
  action=${sel[1]%%$'\t'*}
  repo=$(print -r -- "${sel[1]}" | cut -f2)
  if (( ${#sel} > 1 )) && [[ -n "$(print -rl -- "${sel[@]}" | awk -F'\t' -v r="$repo" '$1 != "run" || $2 != r')" ]]; then
    print "i: multiple selection is for run within one repo." >&2
    return 1
  fi
  local -a targets=(${(f)"$(print -rl -- "${sel[@]}" | cut -f3)"})

  [[ -n "$repo" ]] && { cd "$repo" || return 1 }
  case "$action" in
    run) _aiagent_run "${targets[@]}" ;;
    approve)
      _sed_i "s/^status: draft$/status: open/" "${targets[1]}"
      print "Opened: ${targets[1]:t}"
      _confirm "continue to implement?" && _aiagent_run "${targets[1]}"
      ;;
    merge)  _aiagent_merge "${targets[1]}" ;;
    abort)  _aiagent_abort "${targets[1]}" ;;
    status) _aiagent_status_all ;;
  esac
}
