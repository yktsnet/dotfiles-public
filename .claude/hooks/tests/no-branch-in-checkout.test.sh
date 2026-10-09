#!/usr/bin/env bash
# no-branch-in-checkout.sh の判定を確かめる。元のチェックアウトと worktree を一時的に作って流す。
set -u
hook="$(cd "$(dirname "$0")/.." && pwd)/no-branch-in-checkout.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
repo="$tmp/repo"
wt="$tmp/wt"
remote="$tmp/remote.git"
git init -q -b main "$repo" && touch "$repo/f.txt" && git -C "$repo" add f.txt && git -C "$repo" commit -q -m init
git -C "$repo" branch day/old
git -C "$repo" worktree add -q -b task/1-x "$wt"
# リモート追跡ブランチだけがある名前（checkout が DWIM で作って切り替える）
git init -q --bare "$remote"
git -C "$repo" remote add origin "$remote"
git -C "$repo" push -q origin main:remote-only
git -C "$repo" fetch -q origin

fail=0
check() { # want cwd command
  input=$(python3 -c 'import json, sys; print(json.dumps({"tool_name": "Bash", "cwd": sys.argv[1], "tool_input": {"command": sys.argv[2]}}))' "$2" "$3")
  # EnterWorktree で移ったセッションと同じく、CLAUDE_PROJECT_DIR は元のチェックアウトを指したままにする
  out=$(printf '%s' "$input" | CLAUDE_PROJECT_DIR="$repo" "$hook" 2>/dev/null)
  case "$out" in *'"permissionDecision": "deny"'*) got=deny ;; *) got=allow ;; esac
  if [ "$got" != "$1" ]; then
    echo "FAIL want $1, got $got: [$2] $3"
    fail=1
  fi
}

# 止める: 作る・切り替える
check deny "$repo" 'git switch -c day/x'
check deny "$repo" 'git switch -c day/x origin/main'
check deny "$repo" 'git switch -cday/x'
check deny "$repo" 'git switch -C day/x'
check deny "$repo" 'git switch --create day/x'
check deny "$repo" 'git checkout -b day/x'
check deny "$repo" 'git checkout -bday/x'
check deny "$repo" 'git checkout -B day/x origin/main'
check deny "$repo" 'git checkout --orphan day/x'
check deny "$repo" 'git switch --orphan day/x'
check deny "$repo" 'git switch day/old'
check deny "$repo" 'git checkout day/old'
check deny "$repo" 'git switch -'
check deny "$repo" 'git checkout -'
check deny "$repo" 'git switch --detach HEAD'
check deny "$repo" 'git checkout --detach HEAD'
check deny "$repo" 'git checkout HEAD'
check deny "$repo" 'git checkout remote-only'
check deny "$repo" 'git checkout -t origin/remote-only'
check deny "$repo" 'git switch main && git switch -c day/q'
check deny "$repo" 'git pull; git checkout day/old'
check deny "$repo" 'true || git switch -c day/q'
check deny "$repo" 'git fetch | git switch -c day/q'
check deny "$repo" 'echo hi
git switch -c day/q'
check deny "$repo" '(git switch -c day/q)'
check deny "$repo" '{ git switch -c day/q; }'
check deny "$repo" 'GIT_TRACE=0 git switch -c day/q'
check deny "$repo" 'git -c core.pager=cat switch -c day/q'
check deny "$repo" '/usr/bin/git switch -c day/q'
check deny "$repo" 'git "switch" "-c" day/q'

# 止める: 元のチェックアウトを別の場所から指す
check deny "$wt" "git -C $repo switch -c day/z"
check deny "$tmp" "git -C $repo switch -c day/z"
check deny "$tmp" "git -C \"$repo\" switch -c day/z"
check deny "$tmp" "cd $repo && git switch -c day/z"
check deny "$wt" "cd $repo; git checkout -b day/z"
check deny "$repo" 'echo x && git -C . switch day/old'

# 通す: main へ戻る、ファイルを戻す
check allow "$repo" 'git switch main'
check allow "$repo" 'git checkout main'
check allow "$repo" 'git switch main && git pull'
check allow "$repo" 'git switch --discard-changes main'
check allow "$repo" 'git checkout -- f.txt'
check allow "$repo" 'git checkout HEAD -- f.txt'
check allow "$repo" 'git checkout HEAD f.txt'
check allow "$repo" 'git checkout f.txt'
check allow "$repo" 'git checkout -f main'
check allow "$repo" 'git restore f.txt'
check allow "$repo" 'git status'
check allow "$repo" 'git branch day/new'

# 通す: worktree
check allow "$repo" "git worktree add $tmp/w2 -b day/w2 main"
check allow "$wt" 'git switch -c day/y'
check allow "$wt" 'git checkout day/old'
check allow "$wt" 'git checkout -b day/y2'
check allow "$repo" "git -C $wt switch -c day/z"
check allow "$tmp" "git -C $wt switch -c day/z"
check allow "$repo" "cd $wt && git switch -c day/z"

# 通す: 文字列・heredoc の中、リポの外
check allow "$repo" 'gh pr create --title "git switch -c x"'
check allow "$repo" 'gh pr create --title "feat: a; git switch -c x"'
check allow "$repo" "git commit -m 'fix: git checkout -b x && git switch -c y'"
check allow "$repo" 'echo "a | git switch -c x"'
check allow "$repo" 'git commit -F - <<EOF
git switch -c x
EOF'
check allow "$repo" 'git commit -F - <<'"'EOF'"'
$ git checkout -b x
EOF'
check allow "$tmp" 'git switch -c day/outside'

# 解釈できない入力: git switch を含むなら通さない、含まなければ通す
check deny "$repo" 'git switch -c "unterminated'
check allow "$repo" 'echo "unterminated'

[ "$fail" = 0 ] && echo ok
exit "$fail"
