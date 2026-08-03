#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): ~/.claude 配下の Nix 管理対象ファイルへの直接編集を拒否する。
# home-manager/modules/claude.nix が rm -rf + コピーで dotfiles/.claude から
# 上書きデプロイするため、~/.claude 側への直接編集は次回 rebuild で消える。
file_path=$(jq -r '.tool_input.file_path // ""')
home="${HOME:-/Users/$(whoami)}"

case "$file_path" in
  "$home/.claude/settings.json"|"$home/.claude/CLAUDE.md"|"$home/.claude/hooks/"*|"$home/.claude/skills/"*)
    ;;
  *) exit 0 ;;
esac

dotfiles_path="${file_path/#$home\/.claude\//$home/dotfiles/.claude/}"

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"~/.claude/settings.json・CLAUDE.md・hooks/・skills/ は home-manager (home-manager/modules/claude.nix) が dotfiles/.claude から rm -rf + コピーで上書きデプロイする、Nix管理対象。直接編集しても次回 home-manager switch / darwin-rebuild switch で消える。代わりに ${dotfiles_path} を編集し、必要なら home-manager switch (または darwin-rebuild switch) でデプロイすること。"}}
EOF
