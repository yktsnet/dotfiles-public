#!/usr/bin/env bash
# relay-target-repo-hooks.sh の判定を確かめる。宛先と起動元のリポを一時的に作り、宛先に deny と
# フックを置いて流す。コマンドは実行せず、フックの判定だけを見る。
set -u
hook="$(cd "$(dirname "$0")/.." && pwd)/relay-target-repo-hooks.sh"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

mk() { git init -q -b main "$1" && git -C "$1" commit -q --allow-empty -m init; }
here="$tmp/here"; there="$tmp/there"
mk "$here"; mk "$there"
mkdir -p "$there/.claude/hooks"
cat > "$there/.claude/settings.json" <<'JSON'
{"permissions":{"deny":["Bash(git push * deploy*)","Bash(gh workflow run *)"]},
 "hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"$CLAUDE_PROJECT_DIR/.claude/hooks/no-touch.sh"}]}]}}
JSON
# 宛先のフック: cwd が宛先の中で、touch を打ったら止める（cwd と CLAUDE_PROJECT_DIR が渡るかも見る）
cat > "$there/.claude/hooks/no-touch.sh" <<'SH'
#!/usr/bin/env bash
in=$(cat)
case "$in" in *touch*) ;; *) exit 0 ;; esac
[ -f "$CLAUDE_PROJECT_DIR/.claude/settings.json" ] || exit 0
printf 'no touch\nin this repo\n' >&2; exit 2
SH
chmod +x "$there/.claude/hooks/no-touch.sh"
git -C "$there" add .claude && git -C "$there" commit -q -m hooks
git -C "$there" worktree add -q -b work/x "$tmp/there-wt"

fail=0
check() { # want project_dir cwd command
  input=$(python3 -c 'import json, sys; print(json.dumps({"tool_name": "Bash", "cwd": sys.argv[1], "tool_input": {"command": sys.argv[2]}}))' "$3" "$4")
  out=$(printf '%s' "$input" | CLAUDE_PROJECT_DIR="$2" "$hook" 2>/dev/null)
  case "$out" in *'"permissionDecision": "deny"'*) got=deny ;; *) got=allow ;; esac
  if [ "$got" != "$1" ]; then
    echo "FAIL want $1, got $got: [$3] $4"
    fail=1
  fi
}

# 宛先の deny
check deny  "$here" "$here" "cd $there && git push origin deploy"
check deny  "$here" "$here" "git -C $there status; cd $there && gh workflow run ci.yml"
# 宛先のフック（複数行の理由も1行に寄せて返す）
check deny  "$here" "$here" "cd $there && touch a"
check deny  "$here" "$here" "cd $tmp/there-wt && touch a"
# 読むだけ・起動したリポの中・宛先が同じリポの worktree
check allow "$here" "$here" "git -C $there log --oneline -3"
check allow "$here" "$here" "touch a"
check allow "$there" "$there" "touch a"
check allow "$there" "$tmp/there-wt" "cd $tmp/there-wt && touch a"
# heredoc の本文と引用符の中は宛先にしない
check allow "$here" "$here" "cat <<EOF
cd $there && gh workflow run ci.yml
EOF"
check allow "$here" "$here" "echo 'cd $there && touch a'"
# 宛先が settings.json を持たない
check allow "$there" "$there" "cd $here && touch a"

[ $fail -eq 0 ] && echo "ok"
exit $fail
