#!/usr/bin/env bash
# jp-proofread-stop.sh に transcript を与えて、終了を止めないこと、前回から変わった日本語の行の
# 範囲だけを渡して裏で起動すること、同じ版や走っている最中には起動しないことを確かめる。
# 校正の本体は記録するだけのスタブに差し替える。
#
#   bash .claude/hooks/tests/jp-proofread-stop.test.sh
HOOK="${1:-$(dirname "$0")/../jp-proofread-stop.sh}"
HOOK=$(cd "$(dirname "$HOOK")" && pwd)/$(basename "$HOOK")
fails=0
work=$(mktemp -d "$HOME/.jp-proofread-test.XXXXXX")
cache=$(mktemp -d)
trap 'rm -rf "$work" "$cache"' EXIT
export XDG_CACHE_HOME="$cache"
state_dir="$cache/claude/jp-proofread"

calls="$work/calls"
cat >"$work/runner.sh" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$calls"
EOF
chmod +x "$work/runner.sh"
export JP_PROOFREAD_RUNNER="$work/runner.sh"

printf '# 請求\n\n締めを直す。\n' >"$work/ja.md"
printf '# Billing\n\nFix it.\n' >"$work/en.md"
printf 'const a = "日本語";\n' >"$work/code.ts"
mkdir "$work/repo"
git -C "$work/repo" init -q
printf '# 手順\n\n一行目。\n二行目。\n三行目。\n' >"$work/repo/doc.md"
git -C "$work/repo" add doc.md
git -C "$work/repo" -c user.email=t@t -c user.name=t commit -qm init

transcript="$work/t.jsonl"
for f in ja.md en.md code.ts repo/doc.md; do
  jq -cn --arg p "$work/$f" '{type:"assistant",message:{content:[{type:"tool_use",name:"Write",input:{file_path:$p}}]}}'
done >"$transcript"

run() { # run <session>
  jq -n --arg s "$1" --arg t "$transcript" \
    '{session_id:$s,transcript_path:$t,stop_hook_active:false}' | bash "$HOOK"
}

# 起動は裏に回るので、スタブが書き終えるのを少し待ってから数える
count() {
  sleep 0.5
  [ -f "$calls" ] && wc -l <"$calls" | tr -d ' ' || echo 0
}

check() { # check <名前> <期待> <実際>
  if [ "$2" = "$3" ]; then
    printf 'ok   %s\n' "$1"
  else
    printf 'FAIL want=%s got=%s  %s\n' "$2" "$3" "$1"
    fails=$((fails + 1))
  fi
}

out=$(run s1)
check "終了を止めない" "" "$out"
check "日本語の新しい .md は全体を渡して起動し、HEAD と同じ版は起動しない" 1 "$(count)"
check "新しいファイルは全行を範囲にする" "s1 $work/ja.md 1-3" "$(sed -n 1p "$calls")"
if grep -q 'en.md\|code.ts' "$calls"; then
  echo "FAIL 英語の .md とコードを対象に含めた"
  fails=$((fails + 1))
fi

run s1 >/dev/null
check "起動済みの版では起動しない" 1 "$(count)"

printf '\n追記した。\n' >>"$work/ja.md"
run s1 >/dev/null
check "書き換えたら、変わった行だけで起動する" "s1 $work/ja.md 4-5" "$(sed -n 2p "$calls")"

printf 'English only.\n' >>"$work/ja.md"
run s1 >/dev/null
check "変わった行に日本語が無ければ起動しない" 2 "$(count)"
run s1 >/dev/null
check "日本語の無い変更も、次からは比べる相手に含める" 2 "$(count)"

sed -i.bak 's/二行目。/二行目を直した。/' "$work/repo/doc.md"
run s1 >/dev/null
count >/dev/null
check "追跡しているファイルは HEAD と比べ、変えた行だけを渡す" "s1 $work/repo/doc.md 4-4" "$(sed -n 3p "$calls")"

printf '\nさらに追記。\n' >>"$work/ja.md"
sleep 30 &
live=$!
printf '%s\n' "$work/ja.md" >"$state_dir/s1.running.$live"
run s1 >/dev/null
check "同じファイルの校正が走っている間は起動しない" 3 "$(count)"
ls "$state_dir"/snap/s1/*.dirty >/dev/null 2>&1 || { echo "FAIL 走っている間の書き換えに印を付けていない"; fails=$((fails + 1)); }
kill "$live" 2>/dev/null
rm -f "$state_dir/s1.running.$live"

run s2 >/dev/null
check "別のセッションは別に数える" 5 "$(count)"

printf '\nもう一度。\n' >>"$work/ja.md"
JP_PROOFREAD_CHILD=1 run s1 >/dev/null
check "校正役の実行の中では起動しない" 5 "$(count)"

# Bash で書き換えたファイルは、コマンドに現れたパスを cwd と cd の先から解決して拾う。
# 呼び出しより前から変わっていたファイル（doc.md）は、パスが現れても拾わない
touch -t 200001010000 "$work/repo/doc.md"
ts=$(date -u -v-1S +%Y-%m-%dT%H:%M:%S.000Z 2>/dev/null || date -u -d '-1 second' +%Y-%m-%dT%H:%M:%S.000Z)
printf '# 追加\n\nBash で書いた。\n' >"$work/repo/bash.md"
mkdir -p "$work/sub"
printf '# 下\n\n絶対パスで書いた。\n' >"$work/sub/abs.md"
bash_transcript="$work/b.jsonl"
{
  jq -cn --arg ts "$ts" --arg c "$work" --arg cmd "cd repo && python3 - <<'EOF'
open('bash.md','a').write('x')
EOF" '{type:"assistant",cwd:$c,timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:$cmd}}]}}'
  jq -cn --arg ts "$ts" --arg c "/" --arg cmd "cat $work/repo/doc.md; sed -i '' s/a/b/ $work/sub/abs.md" \
    '{type:"assistant",cwd:$c,timestamp:$ts,message:{content:[{type:"tool_use",name:"Bash",input:{command:$cmd}}]}}'
} >"$bash_transcript"
: >"$calls"
jq -n --arg t "$bash_transcript" '{session_id:"s3",transcript_path:$t,stop_hook_active:false}' | bash "$HOOK"
count >/dev/null
check "cd の先から相対パスを解決して拾う" 1 "$(grep -c "s3 $work/repo/bash.md 1-3" "$calls")"
check "絶対パスを拾う" 1 "$(grep -c "s3 $work/sub/abs.md 1-3" "$calls")"
check "読んだだけで HEAD と同じファイルは起動しない" 0 "$(grep -c 'doc.md' "$calls")"

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
