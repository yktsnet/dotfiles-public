#!/usr/bin/env bash
# ~/memory/ 配下の各メモリファイル（frontmatter の name / description）を正として
# MEMORY.md インデックスを再生成する。SessionStart フックから呼ばれる。
set -euo pipefail

mem="$HOME/memory"
out="$mem/MEMORY.md"
[ -d "$mem" ] || exit 0

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for type in user feedback project reference; do
  dir="$mem/$type"
  [ -d "$dir" ] || continue
  entries=""
  for f in "$dir"/*.md; do
    [ -e "$f" ] || continue
    name="$(grep -m1 '^name:' "$f" | sed 's/^name:[[:space:]]*//')"
    desc="$(grep -m1 '^description:' "$f" | sed 's/^description:[[:space:]]*//')"
    [ -n "$name" ] || name="$(basename "$f" .md)"
    entries+="- [${name}](${type}/$(basename "$f")) — ${desc}"$'\n'
  done
  if [ -n "$entries" ]; then
    printf '## %s\n%s\n' "$type" "$entries" >>"$tmp"
  fi
done

# 変更があるときだけ書き換える
if ! cmp -s "$tmp" "$out" 2>/dev/null; then
  cp "$tmp" "$out"
fi
