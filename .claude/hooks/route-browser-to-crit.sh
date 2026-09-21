#!/usr/bin/env bash
# PreToolUse hook (Bash): ローカルページを user に見せる動きを crit live へ回す。
#
# ブラウザを loopback URL で開くのは人間に見せる目的しか無いので拒否して crit-live へ誘導する。
# dev server の起動はエージェント自身の自動確認にも使うため、助言だけ返して通す。
# OAuth のコールバックは見せる目的ではないので対象外。
cmd=$(jq -r '.tool_input.command // ""')

loopback='https?://(localhost|127\.0\.0\.1)(:[0-9]+)?'
pre='(^|[;&|`]|\$\()[[:space:]]*(sudo[[:space:]]+)?(env[[:space:]]+)?([[:alnum:]@/_.~+-]*/)?'
opener='(wslview|xdg-open|sensible-browser|x-www-browser|open)[[:space:]]'

# crit 自身の起動は素通しする（crit が opener を呼ぶ経路で自己再帰させない）
if printf '%s' "$cmd" | grep -Eq '(^|[[:space:]])(crit-live|crit[[:space:]]+live)([[:space:]]|$)'; then
  exit 0
fi

if printf '%s' "$cmd" | grep -Eq "$pre$opener" \
  && printf '%s' "$cmd" | grep -Eq "$loopback" \
  && ! printf '%s' "$cmd" | grep -Eqi "$loopback[^[:space:]\"']*/(callback|oauth|auth|login)"; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"ローカルページを user に見せるときは生のブラウザ起動ではなく `crit-live <url>` を使う。crit のレビュー UI を被せ、user がページ上の要素を指してコメントを溜められる状態で渡すため。crit-live は Finish Review までブロックするので、そのまま待って `crit comments --json` で指摘を読む。対象ページに </body> が無いと pin モードが開かずコメントできない点に注意。user が「crit は不要」と明示した場合のみ、ブラウザを開かず URL をそのまま伝える。"}}
JSON
  exit 0
fi

server='((npm|pnpm|yarn|bun)[[:space:]]+(run[[:space:]]+)?(dev|start|serve|preview)|vite([[:space:]]|$)|(next|nuxt|astro|remix)[[:space:]]+dev|ng[[:space:]]+serve|python3?[[:space:]]+-m[[:space:]]+http\.server|php[[:space:]]+-S|(hugo|mkdocs)[[:space:]]+serve[r]?|jekyll[[:space:]]+serve|http-server([[:space:]]|$))'

# npx / bunx / dlx 経由の起動もコマンド位置として扱う
runner='((npx|bunx)[[:space:]]+(-y[[:space:]]+)?|(pnpm|yarn)[[:space:]]+dlx[[:space:]]+)?'

if printf '%s' "$cmd" | grep -Eq "$pre$runner$server"; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","additionalContext":"このサーバの表示を user に目視確認させるなら、URL をそのまま伝えず `crit-live <url>` を通すこと（ページ上の要素を指してコメントを溜められる）。エージェント自身の自動確認（curl 等）が目的なら何もしなくてよい。"}}
JSON
fi
exit 0
