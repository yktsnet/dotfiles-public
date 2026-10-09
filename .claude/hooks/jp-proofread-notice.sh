#!/usr/bin/env bash
# UserPromptSubmit hook: 裏の校正（jp-proofread-run.sh）の結果を、user が始めたターンに
# 相乗りさせて会話側のモデルへ渡す。校正の完了で会話側を起こさないための受け口である。
#
# 渡すのは、直したファイルと校正役の報告、失敗、まだ走っている対象の3つ。何も直さなかった回は
# run 側が result を作らないので、ここでも何も出さない。走っている対象は知らせるだけで、
# 会話側の編集を止めない。止めると、校正の数分のあいだ作業が進まない。
set -uo pipefail

[ -n "${JP_PROOFREAD_CHILD:-}" ] && exit 0

input=$(cat)
session=$(printf '%s' "$input" | jq -r '.session_id // empty')
[ -n "$session" ] || exit 0

state="${XDG_CACHE_HOME:-$HOME/.cache}/claude/jp-proofread/$session"

msg=""
for r in "$state".result.*; do
  [ -f "$r" ] || continue
  msg="${msg:+$msg
}$(cat "$r")"
  cat "$r" >>"$state.reported"
  rm -f "$r"
done

running=()
for m in "$state".running.*; do
  [ -f "$m" ] || continue
  # 落ちた実行の印は消す（pid は印のファイル名の末尾）
  if kill -0 "${m##*.}" 2>/dev/null; then
    while IFS= read -r p; do running+=("$p"); done <"$m"
  else
    rm -f "$m"
  fi
done
if [ "${#running[@]}" -gt 0 ]; then
  msg="${msg:+$msg

}裏の校正役が次のファイルを見ている。編集は続けてよい（校正役は Edit しか持たないので上書きは起きず、
書き換えた分は終わった後の Stop で拾い直す）。
$(printf -- '- %s\n' "${running[@]}")"
fi

[ -n "$msg" ] || exit 0
msg="$msg

user への返答に、校正の結果を一言添える。"
jq -n --arg c "$msg" '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $c}}'
