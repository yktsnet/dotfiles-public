#!/usr/bin/env bash
# PreToolUse hook (Edit|Write|Bash): ~/.claude 配下の Nix 管理対象への直接編集を拒否する。
# home-manager/modules/claude.nix が rm -rf + コピーで dotfiles/.claude から
# 上書きデプロイするため、~/.claude 側への直接編集は次回 rebuild で消える。
# Edit|Write は file_path を、Bash は sed -i / tee / python heredoc 等のシェル経由の
# 書き込みを見る（cat / grep / diff 等の読み取りは通す）。
home="${HOME:-/Users/$(whoami)}"
input=$(cat)
tool_name=$(printf '%s' "$input" | jq -r '.tool_name // ""')

guarded="(settings\\.json|CLAUDE\\.md|hooks/|skills/)"
dotfiles_path="$home/dotfiles/.claude/ 配下の同じ相対パス"

case "$tool_name" in
  Bash)
    cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
    target="(~|\\\$HOME|${home})/\\.claude/${guarded}"
    write='(>>?[[:space:]]*[^|&;]|[[:space:]]-i([[:space:]]|$)|(^|[;&|`(])[[:space:]]*(sudo[[:space:]]+)?(tee|cp|mv|rm|ln|mkdir|touch|chmod|install|dd|truncate|patch|python3?|perl|ruby|node)([[:space:]]|$))'
    printf '%s' "$cmd" | grep -Eq "$target" || exit 0
    printf '%s' "$cmd" | grep -Eq "$write" || exit 0
    ;;
  *)
    file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')
    case "$file_path" in
      "$home/.claude/settings.json"|"$home/.claude/CLAUDE.md"|"$home/.claude/hooks/"*|"$home/.claude/skills/"*)
        dotfiles_path="${file_path/#$home\/.claude\//$home/dotfiles/.claude/}"
        ;;
      *) exit 0 ;;
    esac
    ;;
esac

cat <<EOF
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"~/.claude/settings.json・CLAUDE.md・hooks/・skills/ は home-manager (home-manager/modules/claude.nix) が dotfiles/.claude から rm -rf + コピーで上書きデプロイする、Nix管理対象。Edit/Write でもシェル経由でも直接書き換えない（次回 home-manager switch / darwin-rebuild switch で消える）。代わりに ${dotfiles_path} を編集し、デプロイは user に委ねること。読み取りは制限しない。"}}
EOF
