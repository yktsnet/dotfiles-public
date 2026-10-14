#!/usr/bin/env bash
# aiagent.sh の _aiagent_wt_clean が、未コミットの変更が無い worktree は畳んでよいと返し、
# 残っていれば畳まずに失敗で返すことを確かめる。
#
#   bash .claude/hooks/tests/aiagent-wt-clean.test.sh
SRC="${1:-$(dirname "$0")/../../../home-manager/modules/zsh/functions/aiagent.sh}"
SRC=$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")
fails=0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

wt="$work/wt"
git init -q "$wt"

run() {
  zsh -c '
    source "$1"
    _aiagent_wt_clean "$2"
    print -r -- "rc=$?"
  ' _ "$SRC" "$wt" 2>&1
}

check() { # check <名前> <出力に含まれるべき文字列>
  if printf '%s' "$out" | grep -qF -- "$2"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; printf '%s\n' "$out"; fails=$((fails + 1)); fi
}

out=$(run)
check "未コミットの変更が無ければ畳んでよい" "rc=0"

printf 'x\n' >"$wt/dirty.txt"
out=$(run)
check "未コミットの変更が残っていれば畳まない" "rc=1"
check "残っている変更を示す" "dirty.txt"

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
