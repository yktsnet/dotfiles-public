#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): プロジェクトスコープの memory ディレクトリへの書き込みを拒否する。
#
# ハーネスのシステムプロンプトは永続メモリの置き場として
# ~/.claude/projects/<project>/memory/ を指示してくるが、この環境の正本は ~/memory/ であり、
# SessionStart の sync-memory-index.sh が ~/memory/{user,feedback,project,reference}/ から
# MEMORY.md を再生成している。両者は互いを知らないため、放置すると
# プロジェクト側に劣化した重複メモリが溜まり、索引にも載らず永久に発見されない。
#
# sync-memory-index.sh は「索引を正しく保つ」対策であって「正しい場所に書かせる」対策ではない。
# その穴をこのフックで塞ぐ。
file_path=$(jq -r '.tool_input.file_path // ""')
home="${HOME:-/Users/$(whoami)}"

case "$file_path" in
  "$home"/.claude/projects/*/memory/*) ;;
  *) exit 0 ;;
esac

base=$(basename "$file_path")

if [ "$base" = "MEMORY.md" ]; then
  suggested="$home/memory/MEMORY.md（ただし手で書かない。SessionStart の sync-memory-index.sh が各メモリの frontmatter から再生成する）"
else
  suggested="$home/memory/{user|feedback|project|reference}/$base"
fi

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"~/.claude/projects/*/memory/ はこの環境では使わない。永続メモリの正本は ~/memory/ で、型ごとのサブディレクトリ (user / feedback / project / reference) に1ファイル1事実で置く。代わりに ${suggested} へ書くこと。索引 ~/memory/MEMORY.md は SessionStart フックが自動生成するため手で編集しない。書く前に ~/memory/MEMORY.md を読み、既存メモリと重複しないか必ず確認すること。"}}
EOF
