#!/usr/bin/env bash
# Opus系モデルでだけ、簡潔さとスコープ厳守を追加指示する。
# 参照: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5
set -euo pipefail

input="$(cat)"
model="$(printf '%s' "$input" | jq -r '.model // empty')"

case "$(printf '%s' "$model" | tr '[:upper:]' '[:lower:]')" in
  *opus*)
    ;;
  *)
    exit 0
    ;;
esac

context='Keep responses focused, brief, and concise: keep disclaimers and caveats short, spend most of the response on the main answer, and give a high-level summary unless an in-depth explanation is specifically requested. Deliver what was asked, at the scope intended: make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in one sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it. Finish the whole task, and stop short of actions that are clearly beyond what was asked.'

jq -n --arg ctx "$context" '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx}}'
