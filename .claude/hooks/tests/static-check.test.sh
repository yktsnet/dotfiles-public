#!/usr/bin/env bash
# static-check.sh にペイロードを流して、規約違反が exit 2 で止まり、
# 正常ファイルや対象外パスで誤検知しないことを確かめる。
#
#   bash .claude/hooks/tests/static-check.test.sh
HOOK="${1:-$(dirname "$0")/../static-check.sh}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
fails=0

judge() { # judge <file_path>
  local p rc
  p=$(jq -n --arg f "$1" '{tool_name:"Edit",tool_input:{file_path:$f}}')
  printf '%s' "$p" | bash "$HOOK" >/dev/null 2>&1
  rc=$?
  if [ "$rc" -eq 2 ]; then echo fail; elif [ "$rc" -eq 0 ]; then echo ok; else echo "rc=$rc"; fi
}

report() { # report <期待> <結果> <説明>
  if [ "$2" = "$1" ]; then
    printf '  ok   %-5s %s\n' "$2" "$3"
  else
    printf '  FAIL %-5s (期待 %s) %s\n' "$2" "$1" "$3"; fails=$((fails + 1))
  fi
}

make_file() { # make_file <relpath> <content>
  local path="$TMP/$1"
  mkdir -p "$(dirname "$path")"
  printf '%s\n' "$2" > "$path"
  printf '%s' "$path"
}

echo "== zsh 規約: 止める =="
f=$(make_file "home-manager/modules/zsh/functions/bad1.sh" 'foo() { uname -s; }')
report fail "$(judge "$f")" "zsh/functions の uname"

f=$(make_file "home-manager/modules/zsh/functions/bad2.sh" 'foo() { [[ "$OSTYPE" == darwin* ]]; }')
report fail "$(judge "$f")" "zsh/functions の \$OSTYPE"

f=$(make_file "home-manager/modules/zsh/functions/bad3.sh" 'foo() { sed -i "s/a/b/" x; }')
report fail "$(judge "$f")" "zsh/functions の sed -i"

f=$(make_file "home-manager/modules/zsh/functions/bad4.sh" 'foo() { xdg-open https://example.com; }')
report fail "$(judge "$f")" "zsh/functions の xdg-open"

echo "== zsh 規約: 通す =="
f=$(make_file "home-manager/modules/zsh/functions/good.sh" 'foo() { _is_darwin && _open https://example.com; }')
report ok "$(judge "$f")" "os.sh のシムを使う"

f=$(make_file "home-manager/modules/zsh/functions/os.sh" '_is_darwin() { [[ "$(uname -s)" == Darwin ]]; }')
report ok "$(judge "$f")" "os.sh 自体は除外"

f=$(make_file "home-manager/modules/zsh/functions/comment.sh" '# uname は os.sh に閉じ込める
foo() { _is_darwin; }')
report ok "$(judge "$f")" "コメント行の uname"

f=$(make_file "home-manager/modules/zsh/functions/tests/t.sh" 'uname -s')
report ok "$(judge "$f")" "tests 配下は除外"

f=$(make_file "scripts/run.sh" '#!/usr/bin/env bash
uname -s')
report ok "$(judge "$f")" "zsh/functions 外のシェルスクリプトは対象外"

if [ "$fails" -eq 0 ]; then echo "全て期待どおり"; else echo "FAIL $fails 件"; fi
exit $((fails > 0))
