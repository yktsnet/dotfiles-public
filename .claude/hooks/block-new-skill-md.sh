#!/usr/bin/env bash
# PreToolUse hook (Write): 新規SKILL.mdの直接作成を拒否し、skill-creatorスキル経由を強制する。
# 既存SKILL.mdへの追記・修正（ファイルが既に存在する場合）はEditツール経由になるため対象外。
# ここで拒否するのはWriteで新規作成しようとするケースのみ。
file_path=$(jq -r '.tool_input.file_path // ""')

case "$file_path" in
  */SKILL.md|SKILL.md) ;;
  *) exit 0 ;;
esac

if [ -f "$file_path" ]; then
  exit 0
fi

cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"新規SKILL.mdの直接作成は禁止。anthropic-skills:skill-creator を呼び出して作成すること。このフリートでは以下をデフォルトにする（ユーザーから明示的に逆の指示が無い限り毎回聞き直さない）: (1) 作成前にglobal(~/dotfiles/.claude/skills)とrepo-local(このリポの.claude/skills)の両方を検索し、類似skillが無いか確認する。(2) frontmatterはdisable-model-invocation: trueを既定にし、明示呼び出し専用にする（自動発火させたい旨をユーザーが言った場合のみDescription Optimizationを行う）。(3) 手続き型・チェックリスト型skill（客観的に検証可能な出力を持たないもの）はテストケース作成・サブエージェント評価ループを省略し、ドラフトをそのまま使ってよい。"}}
EOF
