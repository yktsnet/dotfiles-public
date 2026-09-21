#!/usr/bin/env bash
# route-browser-to-crit.sh に Bash コマンドを与えて、deny / advise / silent の判定を確かめる。
#
#   bash .claude/hooks/tests/route-browser-to-crit.test.sh
HOOK="${1:-$(dirname "$0")/../route-browser-to-crit.sh}"
HOOK=$(cd "$(dirname "$HOOK")" && pwd)/$(basename "$HOOK")
fails=0

check() { # check <期待 deny|advise|silent> <コマンド>
  local want="$1" cmd="$2" out got
  out=$(jq -n --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK")
  if printf '%s' "$out" | grep -q '"permissionDecision":"deny"'; then
    got=deny
  elif printf '%s' "$out" | grep -q additionalContext; then
    got=advise
  else
    got=silent
  fi
  if [ "$got" = "$want" ]; then
    printf 'ok   %-6s %s\n' "$got" "$cmd"
  else
    printf 'FAIL want=%s got=%s  %s\n' "$want" "$got" "$cmd"
    fails=$((fails + 1))
  fi
}

# ブラウザで loopback を開く = 人間に見せる目的
check deny   'wslview http://localhost:3000'
check deny   'xdg-open http://127.0.0.1:8080/works.html'
check deny   'open http://localhost:5173'
check deny   'cd /tmp/app && wslview http://localhost:4000/dashboard'

# OAuth のコールバックは見せる目的ではない
check silent 'wslview http://localhost:8085/oauth/callback'
check silent 'xdg-open https://github.com/login/oauth/authorize'

# 外部 URL は対象外
check silent 'wslview https://example.com'

# crit 自身は素通し
check silent 'crit-live http://localhost:3000'
check silent 'CRIT_PORT=7779 crit live http://localhost:3000'

# dev server の起動は助言のみ
check advise 'npm run dev'
check advise 'pnpm dev'
check advise 'python3 -m http.server 8391'
check advise 'cd mock && python3 -m http.server 8391'
check advise 'npx vite --port 5173'
check advise 'php -S localhost:8000'

# 無関係なコマンド
check silent 'git status'
check silent 'curl -s http://localhost:3000'
check silent 'echo "open http://localhost:3000 in your browser"'

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
