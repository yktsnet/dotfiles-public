#!/usr/bin/env bash
# aiagent.sh の _aiagent_wt_clean が、その worktree を対象に走っている校正を待つこと、
# 上限を過ぎたら畳まずに知らせること、他の worktree の校正や落ちた実行の印では待たないことを確かめる。
# sleep は zsh の関数で差し替え、待ちの回数だけを数える。
#
#   bash .claude/hooks/tests/aiagent-wt-clean.test.sh
SRC="${1:-$(dirname "$0")/../../../home-manager/modules/zsh/functions/aiagent.sh}"
SRC=$(cd "$(dirname "$SRC")" && pwd)/$(basename "$SRC")
fails=0
work=$(mktemp -d)
cache="$work/cache"
mkdir -p "$cache/claude/jp-proofread"
trap 'kill $live 2>/dev/null; rm -rf "$work"' EXIT
state="$cache/claude/jp-proofread"

wt="$work/wt"
other="$work/other"
for d in "$wt" "$other"; do git init -q "$d"; done

sleep 300 &
live=$!

# 引数: 印の中身の worktree / 印の pid / 何回目の sleep で印を消すか（0 は消さない）
run() {
  local target="$1" pid="$2" clear_at="$3"
  rm -f "$state"/*.running.*
  [ -n "$target" ] && printf '%s/doc.md\n' "$target" >"$state/s1.running.$pid"
  XDG_CACHE_HOME="$cache" MARK="$state/s1.running.$pid" CLEAR_AT="$clear_at" zsh -c '
    source "$1"
    n=0
    sleep() { (( n++ )); (( CLEAR_AT > 0 && n >= CLEAR_AT )) && rm -f "$MARK"; }
    _aiagent_wt_clean "$2"
    print -r -- "rc=$? sleeps=$n"
  ' _ "$SRC" "$wt" 2>&1
}

check() { # check <名前> <出力に含まれるべき文字列>
  if printf '%s' "$out" | grep -qF -- "$2"; then printf 'ok   %s\n' "$1"; else printf 'FAIL %s\n' "$1"; printf '%s\n' "$out"; fails=$((fails + 1)); fi
}

out=$(run "" 0 0)
check "印が無ければ待たない" "rc=0 sleeps=0"

out=$(run "$wt" 999999 0)
check "プロセスが居ない印では待たない" "rc=0 sleeps=0"

out=$(run "$other" "$live" 0)
check "別の worktree の校正では待たない" "rc=0 sleeps=0"

out=$(run "$wt" "$live" 3)
check "自分の worktree の校正が終わるまで待つ" "Waiting for proofreading in $wt"
check "終わったら畳んでよい" "rc=0 sleeps=3"

out=$(run "$wt" "$live" 0)
check "上限を過ぎたら畳まずに知らせる" "Proofreading is still running in $wt"
check "上限を過ぎたら失敗で返す" "rc=1 sleeps=36"

printf 'x\n' >"$wt/dirty.txt"
out=$(run "" 0 0)
check "未コミットの変更が残っていれば畳まない" "rc=1 sleeps=0"

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
