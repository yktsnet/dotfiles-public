#!/usr/bin/env bash
# jp-proofread-run.sh を、claude を差し替えたスタブで走らせる。行の範囲と規範のパスを渡すこと、
# CLAUDE_CONFIG_DIR の有無で config dir を選ぶこと、リポの外から起動すること、直した後の版を写しに置くこと、
# 走っている間に範囲の外が書き換えられたら写しを起動時の版のまま残すことを確かめる。
#
#   bash .claude/hooks/tests/jp-proofread-run.test.sh
RUN="${1:-$(dirname "$0")/../jp-proofread-run.sh}"
RUN=$(cd "$(dirname "$RUN")" && pwd)/$(basename "$RUN")
fails=0
work=$(mktemp -d "$HOME/.jp-proofread-test.XXXXXX")
cache=$(mktemp -d)
fakehome=$(mktemp -d)
trap 'rm -rf "$work" "$cache" "$fakehome"' EXIT
export XDG_CACHE_HOME="$cache"
state_dir="$cache/claude/jp-proofread"

# スタブの claude: 受けた条件を記録し、STUB_EDIT があれば対象ファイルに sed を当てる
mkdir "$work/bin"
cat >"$work/bin/claude" <<'EOF'
#!/usr/bin/env bash
{
  printf 'config=%s\n' "$CLAUDE_CONFIG_DIR"
  printf 'pwd=%s\n' "$(pwd -P)"
  printf 'args=%s\n' "$*"
  cat
  printf '\n'
} >"$STUB_LOG"
[ -n "${STUB_SLEEP:-}" ] && sleep "$STUB_SLEEP"
[ -n "${STUB_EDIT:-}" ] && sed -i.bak "$STUB_EDIT" "$STUB_FILE" && rm -f "$STUB_FILE.bak"
[ -n "${STUB_SIDE:-}" ] && printf '%s\n' "$STUB_SIDE" >>"$STUB_FILE"
echo "報告"
EOF
chmod +x "$work/bin/claude"
export PATH="$work/bin:$PATH"
export STUB_LOG="$work/stub.log"

check() { # check <名前> <0|1 = 真/偽> <コマンド...>
  local want="$2"; shift 2
  if "$@" >/dev/null 2>&1; then got=0; else got=1; fi
  if [ "$got" = "$want" ]; then printf 'ok   %s\n' "$NAME"; else printf 'FAIL %s\n' "$NAME"; fails=$((fails + 1)); fi
}

mkdir -p "$work/repo/docs/ops"
unset CLAUDE_CONFIG_DIR
git -C "$work/repo" init -q
printf '# 規範\n' >"$work/repo/docs/ops/doc-style.md"
printf '# 手順\n\n一行目することができる。\n二行目。\n' >"$work/repo/doc.md"
export STUB_FILE="$work/repo/doc.md"
snap="$state_dir/snap/s1/$(printf '%s' "$STUB_FILE" | cksum | awk '{print $1 "-" $2}')"
mkdir -p "$(dirname "$snap")"

STUB_EDIT='s/することができる/できる/' bash "$RUN" s1 "$STUB_FILE" 3-3
NAME="行の範囲を渡す"; check "" 0 grep -q '行の範囲: 3-3' "$STUB_LOG"
NAME="規範のパスを渡す"; check "" 0 grep -q "規範の正本: $work/repo/docs/ops/doc-style.md" "$STUB_LOG"
NAME="リポの外から起動する"; check "" 0 grep -qx "pwd=$(cd "$state_dir" && pwd -P)" "$STUB_LOG"
NAME="CLAUDE_CONFIG_DIR が無ければ既定の config dir"; check "" 0 grep -qx "config=$HOME/.claude" "$STUB_LOG"
NAME="直した後の版を写しに置く"; check "" 0 cmp -s "$snap" "$STUB_FILE"
NAME="直したら結果を残す"; check "" 0 ls "$state_dir"/s1.result.*
rm -f "$state_dir"/s1.result.*

printf '三行目。\n四行目。\n' >>"$STUB_FILE"
cp "$STUB_FILE" "$snap"
STUB_EDIT='s/二行目。/二行目を直した。/' STUB_SIDE='会話側が足した行。' bash "$RUN" s1 "$STUB_FILE" 4-4
NAME="範囲の外が書き換えられたら写しを起動時の版のまま残す"; check "" 1 grep -q '会話側が足した行' "$snap"

: >"$STUB_LOG"
rm -f "$state_dir"/s1.result.*
bash "$RUN" s1 "$STUB_FILE" 1-1
NAME="何も直さなかった回は結果を残さない"; check "" 1 ls "$state_dir"/s1.result.*

STUB_SLEEP=3 STUB_EDIT='s/一行目/止めた後に直した/' bash "$RUN" s1 "$STUB_FILE" 3-3 &
parent=$!
sleep 1
kill -TERM "$parent"
wait "$parent" 2>/dev/null
sleep 3
NAME="止めたら校正役も止まり、ファイルを書き換えない"; check "" 1 grep -q '止めた後に直した' "$STUB_FILE"
NAME="止めたら走っている印を消す"; check "" 1 ls "$state_dir"/s1.running.*

printf '# 別\n\n本文。\n' >"$work/repo/b.md"
CLAUDE_CONFIG_DIR="$fakehome/cfg" bash "$RUN" s1 "$work/repo/b.md" 3-3
NAME="CLAUDE_CONFIG_DIR があればそれを使う"; check "" 0 grep -qx "config=$fakehome/cfg" "$STUB_LOG"

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
