#!/usr/bin/env bash
# check-refs.py の判定を確かめる。最小のリポを一時に作り、壊した写しごとに終了コードと出力を見る。
set -u
script="$(cd "$(dirname "$0")/.." && pwd)/scripts/check-refs.py"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail=0
# 基準のリポを作り直して cd する
setup() {
  rm -rf "$tmp/r" && mkdir -p "$tmp/r" && cd "$tmp/r" || exit 1
  git init -q
  mkdir -p .claude/hooks .claude/skills/foo issues/done docs
  echo '{"hooks":{"command":"$CLAUDE_PROJECT_DIR/.claude/hooks/a.sh"}}' > .claude/settings.json
  : > .claude/hooks/a.sh
  printf '| [foo](foo/index.md) |\n' > .claude/skills/README.md
  : > .claude/skills/foo/index.md
  printf '[ok](docs/x.md) [url](https://example.com/nope.md) [anchor](#h) [sec](docs/x.md#h)\n' > README.md
  : > docs/x.md
}
# run want_rc want_output_substring label
run() {
  git add -A >/dev/null 2>&1
  out=$(python3 "$script" 2>&1); rc=$?
  if [ "$rc" != "$1" ]; then echo "FAIL [$3] want rc=$1, got rc=$rc: $out"; fail=1; return; fi
  case "$out" in *"$2"*) ;; *) echo "FAIL [$3] output lacks '$2': $out"; fail=1 ;; esac
}

setup; run 0 "" clean

setup; echo '[x](does/not/exist.md)' >> README.md
run 1 "README.md:2 -> does/not/exist.md" broken-link

setup; echo '[x](nope.md#a)' >> docs/x.md
run 1 "docs/x.md:1 -> nope.md#a" broken-link-with-anchor

setup; printf '```\n[x](nope.md)\n```\n`[y](nope2.md)`\n' >> README.md
run 0 "" fence-and-code-span-skipped

setup; echo '[x](nope.md)' > issues/done/01_a.md
run 0 "" issues-done-skipped

setup; echo '{"command":"$CLAUDE_PROJECT_DIR/.claude/hooks/a.sh","c2":".claude/hooks/ghost.sh"}' > .claude/settings.json
run 1 "missing in .claude/hooks/: ghost.sh" hook-registered-without-file

setup; : > .claude/hooks/b.sh
run 1 "not registered in settings.json: b.sh" hook-file-unregistered

setup; mkdir .claude/skills/bar
run 1 "not linked from .claude/skills/README.md: bar" skill-unlisted

exit $fail
