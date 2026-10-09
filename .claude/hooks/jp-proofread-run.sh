#!/usr/bin/env bash
# jp-proofread-stop.sh が裏で起動する校正の本体。フックとしては登録しない。
#   jp-proofread-run.sh <session_id> <file> <開始-終了,...>
#
# jp-proofreader をヘッドレス実行で1回だけ走らせ、渡した行の範囲だけを直させる。モデルは
# エージェント定義の model: が決める（--agent はそれに従う）。
# 結果はセッションごとの result ファイルに置き、jp-proofread-notice.sh が次のターンで拾う。
# 何も直さなかった回は result を作らない（伝えることが無いのに会話側の文脈を増やさない）。
set -uo pipefail

session="$1"
file="$2"
ranges="$3"
[ -f "$file" ] || exit 0

state_dir="${XDG_CACHE_HOME:-$HOME/.cache}/claude/jp-proofread"
state="$state_dir/$session"
snap="$state_dir/snap/$session/$(printf '%s' "$file" | cksum | awk '{print $1 "-" $2}')"
running="$state.running.$$"
log="$state.log"
mkdir -p "$state_dir" "$(dirname "$snap")" || exit 1

start=$(mktemp) || exit 1
printf '%s\n' "$file" >"$running"
trap 'rm -f "$running" "$start"' EXIT
cp "$file" "$start"

dir=$(dirname "$file")
root=$(git -C "$dir" rev-parse --show-toplevel 2>/dev/null) || root=$dir

# 校正役の config dir は、会話側の CLAUDE_CONFIG_DIR があればそれを、無ければ既定を使う
config_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"

# 規範は1本だけ渡す。リポ直下の docs/ops/doc-style.md、無ければリポ内で追跡している同名のもの、
# それも無ければ jp-writing。両方を読ませると中身の重なる約20KBを毎回読むことになる
style=""
if [ -f "$root/docs/ops/doc-style.md" ]; then
  style="$root/docs/ops/doc-style.md"
else
  rel=$(git -C "$root" ls-files '*docs/ops/doc-style.md' 2>/dev/null | head -1)
  [ -n "$rel" ] && style="$root/$rel"
fi
[ -n "$style" ] || style="$config_dir/skills/jp-writing/SKILL.md"

add_dirs=(--add-dir "$dir" --add-dir "$(dirname "$style")")

prompt="次のファイルを校正する。直すのは指定した行の範囲だけで、前後は文脈として読んでよい。
ファイルを Edit で直接直し、最後に報告を返す。
- ファイル: $file
- 行の範囲: $ranges"
prompt="$prompt
- 規範の正本: $style"

# 校正役は裏に回して待つ。コマンド置換の中で走らせると pid が取れず、このスクリプトを止めても
# 校正役だけが残って、走っている印が消えた後もファイルを書き換える
outf="$state.out.$$"
trap 'rm -f "$running" "$start" "$outf"' EXIT
cd "$state_dir" || exit 1

# 表現を直すだけの役に要らないものを読ませない。リポの外から起動してリポの CLAUDE.md を外し、
# --tools でツールの定義を2つに絞り、MCP の接続先と hook を止める。重さの大半は文書の量ではなく、
# この固定費と往復の回数にある。--bare は OAuth を読まないので使えない。
# 思考は止める。表現を直すだけなら要らず、実測では2行の校正が約40秒から約13秒に縮み、直し漏れも減った
# --tools・--allowedTools・--add-dir は値を複数取るので、プロンプトは引数でなく標準入力で渡す
printf '%s' "$prompt" | JP_PROOFREAD_CHILD=1 MAX_THINKING_TOKENS=0 CLAUDE_CONFIG_DIR="$config_dir" claude -p \
  --agent jp-proofreader \
  --permission-mode acceptEdits \
  --tools "Read,Edit" \
  --allowedTools "Read,Edit" \
  --strict-mcp-config \
  --settings '{"disableAllHooks":true}' \
  --no-session-persistence \
  --output-format text \
  "${add_dirs[@]}" >"$outf" 2>&1 &
child=$!
trap 'kill "$child" 2>/dev/null; exit 143' TERM INT HUP
wait "$child"
rc=$?
out=$(cat "$outf")

{
  printf '=== %s exit=%s config=%s\n' "$(date '+%F %T')" "$rc" "$config_dir"
  printf '%s %s\n' "$file" "$ranges"
  printf '%s\n\n' "$out"
} >>"$log"

# 渡した範囲の外が変わっていれば、走っている間に会話側も書き換えている。直した後の版を写しに
# すると、その書き換えを校正せずに済ませてしまうので、起動時の版を写しに残して次の Stop で拾わせる
outside=$(diff -U0 "$start" "$file" | awk -v r="$ranges" '
  BEGIN { n = split(r, rs, ",") }
  /^@@/ {
    split($2, a, ",")
    s = substr(a[1], 2) + 0
    len = (2 in a) ? a[2] + 0 : 1
    e = (len > 0) ? s + len - 1 : s
    inside = 0
    for (i = 1; i <= n; i++) {
      split(rs[i], b, "-")
      if (s >= b[1] && e <= b[2]) inside = 1
    }
    if (!inside) { print "x"; exit }
  }')
if [ -f "$file" ] && [ -z "$outside" ] && [ ! -f "$snap.dirty" ]; then
  cp "$file" "$snap"
fi

changed=0
cmp -s "$start" "$file" || changed=1

# 拾う側と取り合わないよう、書き終えてから mv で置く
tmp="$state.tmp.$$"
if [ "$rc" -ne 0 ]; then
  {
    printf '裏の校正役が失敗した（exit %s）。対象: %s\n' "$rc" "$file"
    printf '出力は %s にある。\n' "$log"
  } >"$tmp"
elif [ "$changed" -eq 1 ]; then
  {
    printf '裏の校正役（jp-proofreader）が次のファイルを直した。\n- %s\n' "$file"
    printf '\n校正役の報告:\n%s\n' "$out"
  } >"$tmp"
else
  exit 0
fi
mv "$tmp" "$state.result.$$"
