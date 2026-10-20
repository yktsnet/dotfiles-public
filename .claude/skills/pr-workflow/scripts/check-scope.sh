#!/usr/bin/env bash
# ブランチの変更（コミット済みとステージ済み）のファイル一覧が、Issue の `対象` と一致するかを確かめる。
# 一致すれば無言で終了コード0。食い違えば足りないパスと余計なパスを分けて出して1。
#
#   check-scope.sh <Issue ファイル>
set -euo pipefail

issue="${1:-}"
if [ -z "$issue" ] || [ ! -f "$issue" ]; then
  echo "usage: check-scope.sh <issue-file>" >&2
  exit 2
fi

# `対象` の読み取り。1行のカンマ区切りと、次行からの `- ` 箇条書きの両方を受ける。
# 括弧書きの注記（半角・全角）は、全角を半角へ揃えてから先に落とす（ロケールに依らず動かすため）。注記の中のカンマで分割を誤らないため。
# `対象外:` は行頭の `対象:` に一致しないので混ざらない。
declared=$(awk '
  BEGIN { inblock = 0 }
  /^対象:/ { inblock = 1; sub(/^対象:/, ""); if ($0 ~ /[^ \t]/) print; next }
  inblock && /^[ \t]*- / { sub(/^[ \t]*- /, ""); print; next }
  inblock { exit }
' "$issue" \
  | sed -E 's/（/(/g; s/）/)/g; s/\([^)]*\)//g' \
  | tr ',' '\n' \
  | sed -E 's/`//g; s/^[[:space:]]+//; s/[[:space:]]+$//' \
  | awk 'NF { print $1 }' \
  | sort -u)

if [ -z "$declared" ]; then
  echo "error: no paths found under '対象' in $issue" >&2
  exit 2
fi

base=$(git merge-base origin/main HEAD)
actual=$(git diff --name-only --cached "$base" | grep -v '^issues/' | sort -u || true)

missing=$(comm -23 <(printf '%s\n' "$declared") <(printf '%s\n' "$actual") | awk 'NF')
extra=$(comm -13 <(printf '%s\n' "$declared") <(printf '%s\n' "$actual") | awk 'NF')

if [ -z "$missing" ] && [ -z "$extra" ]; then
  exit 0
fi

if [ -n "$missing" ]; then
  echo "missing (declared in the issue but not changed):"
  printf '%s\n' "$missing" | sed 's/^/  /'
fi
if [ -n "$extra" ]; then
  echo "extra (changed but not declared in the issue):"
  printf '%s\n' "$extra" | sed 's/^/  /'
fi
exit 1
