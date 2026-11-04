#!/usr/bin/env bash
# aiagent.sh の _aiagent_retire_wt が、ブランチの先頭を PR の head と比べて worktree を片付けることを確かめる。
# gh は関数で差し替え、PR の state と head を返させる。
#
#   bash .claude/hooks/tests/aiagent-retire-wt.test.sh
SRC="${1:-$(dirname "$0")/../../../home-manager/modules/zsh/functions/aiagent.sh}"
SRC=$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")
fails=0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

repo="$work/repo"
git init -q -b main "$repo"
git -C "$repo" -c user.name=t -c user.email=t@t commit -q --allow-empty -m init

# setup <名前>: origin の追跡ブランチを持たないブランチと worktree を作る
setup() {
  wt="$work/wt-$1"
  git -C "$repo" worktree add -q -b "claude/$1" "$wt" main
}

run() { # run <state> <head>
  (cd "$repo" && zsh -c '
    source "$1"
    gh() { printf "%s\t%s\n" "$GH_STATE" "$GH_HEAD"; }
    _aiagent_retire_wt "$2" "$3"
  ' _ "$SRC" "$wt" "$branch" 2>&1)
}

check() { # check <名前> <条件の終了コード>
  if [ "$2" -eq 0 ]; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; printf '%s\n' "$out"; fails=$((fails + 1)); fi
}

setup match; branch=claude/match
head=$(git -C "$repo" rev-parse "$branch")
out=$(GH_STATE=MERGED GH_HEAD=$head run)
[ ! -d "$wt" ]; check "追跡ブランチが無くても head が一致すれば消す" $?

setup open; branch=claude/open
head=$(git -C "$repo" rev-parse "$branch")
out=$(GH_STATE=OPEN GH_HEAD=$head run)
[ ! -d "$wt" ]; check "OPEN でも head が一致すれば消す" $?

setup ahead; branch=claude/ahead
head=$(git -C "$repo" rev-parse "$branch")
git -C "$wt" -c user.name=t -c user.email=t@t commit -q --allow-empty -m extra
out=$(GH_STATE=OPEN GH_HEAD=$head run)
[ -d "$wt" ]; check "head に無いコミットがあれば残す" $?
printf '%s' "$out" | grep -qF "has commits not in the PR."; check "残した理由を出す" $?

setup closed; branch=claude/closed
head=$(git -C "$repo" rev-parse "$branch")
out=$(GH_STATE=CLOSED GH_HEAD=$head run)
[ -d "$wt" ]; check "CLOSED なら残す" $?

setup dirty; branch=claude/dirty
head=$(git -C "$repo" rev-parse "$branch")
printf 'x\n' >"$wt/dirty.txt"
out=$(GH_STATE=MERGED GH_HEAD=$head run)
[ -d "$wt" ]; check "未コミットの変更があれば残す" $?

git -C "$repo" rev-parse -q --verify claude/match >/dev/null; check "ブランチは消さない" $?

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
