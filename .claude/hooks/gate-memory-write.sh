#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|Bash): ~/memory/ への書き込みに user の承認を挟む。
#
# 永続メモリは Agent が対話の流れで勝手に増やしがちで、そうして書かれたものは
# 判断軸も書式も通っていない。deny ではなく ask を返すのは、書くこと自体は正当な
# 操作であり、要るのは「user が OK したか」という一点だけだからである。
# 承認プロンプトそのものが、その裁可点として機能する。
#
# 正本は ~/memory/ だが実体は ~/dotfiles/memory/（memory.nix が ~/memory を張る先）なので、
# 両方の綴りを見る。
# シェル経由（cat > 等）だと Write を通らず素通りするため Bash も対象にする。
payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""')
home="${HOME:-/Users/$(whoami)}"

ask() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "ask",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

reason="~/memory/ への書き込みは user の承認が要る。永続メモリは最後の置き場であり、
skill（reference/ を含む）・リポの context/ に書き場があるならそちらが正本になる。
memory-write スキルを読み、要否の判断軸（そこにしか無いか・行動を変えるか）と
書式を確認したうえで、user に提案して承認を得ること。"

if [ "$tool_name" = "Bash" ]; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
  # 読み取り（cat / grep / ls）は素通しし、書き込み側のみ捕捉する。
  # 宛先がディレクトリそのもの（cp a.md $HOME/memory）でも末尾の / が無いだけで漏れないよう、語尾も見る
  printf '%s' "$cmd" | grep -Eq '(>>?|tee|cp|mv|install|rm|sed -i|perl -pi)[^|&;]*(/memory(/|[[:space:]"'"'"']|$)|~/memory)' || exit 0
  ask "$reason"
fi

file_path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')

case "$file_path" in
  "$home"/memory/*|"$home"/dotfiles/memory/*) ask "$reason" ;;
esac

exit 0
