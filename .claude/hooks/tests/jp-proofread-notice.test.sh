#!/usr/bin/env bash
# jp-proofread-notice.sh が、裏の校正の結果を1回だけ渡すこと、走っている対象を伝えること、
# 落ちた実行の印を片付けることを確かめる。
#
#   bash .claude/hooks/tests/jp-proofread-notice.test.sh
HOOK="${1:-$(dirname "$0")/../jp-proofread-notice.sh}"
HOOK=$(cd "$(dirname "$HOOK")" && pwd)/$(basename "$HOOK")
fails=0
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT
export XDG_CACHE_HOME="$cache"
state_dir="$cache/claude/jp-proofread"
mkdir -p "$state_dir"

run() { # run <session>
  jq -n --arg s "$1" '{session_id:$s,prompt:"x"}' | bash "$HOOK"
}

check() { # check <名前> <0|1 = 含む/含まない> <出力> <文字列>
  local has=1
  printf '%s' "$3" | grep -qF "$4" && has=0
  if [ "$has" = "$2" ]; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL %s\n' "$1"
    fails=$((fails + 1))
  fi
}

check "何も無ければ何も出さない" 0 "$(run s1 | wc -c | tr -d ' ')" "0"

printf '裏の校正役が次のファイルを直した。\n- /x/a.md\n' >"$state_dir/s1.result.111"
out=$(run s1)
check "結果を渡す" 0 "$out" "/x/a.md"
check "UserPromptSubmit の文脈として渡す" 0 "$out" '"hookEventName": "UserPromptSubmit"'
check "渡した結果は2度渡さない" 1 "$(run s1)" "/x/a.md"
check "別のセッションの結果は渡さない" 1 "$(printf 'r\n' >"$state_dir/s2.result.1"; run s1)" "r"

sleep 30 &
live=$!
printf '/x/b.md\n' >"$state_dir/s1.running.$live"
printf '/x/c.md\n' >"$state_dir/s1.running.999999"
out=$(run s1)
check "走っている対象を伝える" 0 "$out" "/x/b.md"
check "落ちた実行の対象は伝えない" 1 "$out" "/x/c.md"
[ -f "$state_dir/s1.running.999999" ] && { echo "FAIL 落ちた実行の印が残った"; fails=$((fails + 1)); }
kill "$live" 2>/dev/null

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
