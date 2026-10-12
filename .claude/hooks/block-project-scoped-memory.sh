#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|Bash): プロジェクトスコープの memory ディレクトリへの書き込みを拒否する。
#
# ハーネスのシステムプロンプトは永続メモリの置き場として
# ~/.claude/projects/<project>/memory/ を指示してくるが、この環境の正本は ~/memory/ である。
# 両者は互いを知らないため、放置するとプロジェクト側に劣化した重複メモリが溜まり、
# 一覧に出ないまま永久に発見されない。
#
# シェル経由（cat > 等）だと Write を通らず素通りするため Bash も対象にする。
# 判定の形は gate-memory-write.sh と揃えてある。
payload=$(cat)
home="${HOME}"
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""')

deny() {
  jq -n --arg dst "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: ("~/.claude/projects/*/memory/ はこの環境では使わない。永続メモリの正本は ~/memory/ 直下で、サブディレクトリも索引ファイルも持たない。書く前に memory-write スキルを読み、user の承認と、skill / docs に書き場が無いことの確認を先に済ませること。書く場合の宛先は " + $dst + "。")
    }
  }'
  exit 0
}

if [ "$tool_name" = Bash ]; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
  # 読み取り（cat / grep / ls）は素通しし、書き込み側のみ捕捉する
  printf '%s' "$cmd" \
    | grep -Eq '(>>?|tee|cp|mv|install|rm|sed -i|perl -pi)[^|&;]*/\.claude/projects/[^[:space:]]*/memory/' \
    || exit 0
  deny "${home}/memory/<name>.md"
fi

file_path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')

case "$file_path" in
  "$home"/.claude/projects/*/memory/*)
    deny "${home}/memory/$(basename "$file_path")" ;;
esac

exit 0
