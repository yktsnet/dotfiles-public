#!/usr/bin/env bash
# gate-memory-write.sh の判定を確かめる。書き込みは ask、読み取りと無関係なパスは無出力。
set -u
hook="$(cd "$(dirname "$0")/.." && pwd)/gate-memory-write.sh"
home=/Users/u

fail=0
check() { # want tool_name key value
  input=$(python3 -c 'import json, sys; print(json.dumps({"tool_name": sys.argv[1], "tool_input": {sys.argv[2]: sys.argv[3]}}))' "$2" "$3" "$4")
  out=$(printf '%s' "$input" | HOME="$home" "$hook" 2>/dev/null)
  case "$out" in *'"permissionDecision": "ask"'*) got=ask ;; "") got=silent ;; *) got=other ;; esac
  if [ "$got" != "$1" ]; then
    echo "FAIL want $1, got $got: [$2] $4"
    fail=1
  fi
}

# 承認を求める: Edit / Write（正本の綴りと実体の綴り）
check ask Write file_path "$home/memory/a.md"
check ask Edit file_path "$home/memory/sub/a.md"
check ask Write file_path "$home/dotfiles/memory/a.md"
check ask Edit file_path "$home/dotfiles/memory/a.md"

# 承認を求める: シェル経由の書き込み
check ask Bash command 'echo x >> ~/memory/a.md'
check ask Bash command 'echo x > $HOME/memory/a.md'
check ask Bash command 'cat > /Users/u/memory/a.md <<EOF'
check ask Bash command 'echo x | tee ~/memory/a.md'
check ask Bash command 'cp a.md ~/memory/a.md'
check ask Bash command 'mv a.md ~/memory/a.md'
check ask Bash command 'rm ~/memory/a.md'
check ask Bash command 'sed -i s/a/b/ ~/memory/a.md'
check ask Bash command 'cp a.md ~/memory'
check ask Bash command 'cp a.md $HOME/memory'
check ask Bash command 'cp a.md /Users/u/memory'
check ask Bash command 'mv a.md ~/dotfiles/memory'
check ask Bash command 'install -m 644 a.md $HOME/memory'
check ask Bash command 'cp a.md "$HOME/memory"'
check ask Bash command 'install -m 644 a.md ~/memory/a.md'
check ask Bash command 'perl -pi -e s/a/b/ ~/memory/a.md'

# 通す: 読み取り、無関係なパス
check silent Write file_path "$home/other/a.md"
check silent Edit file_path "$home/dotfiles/home-manager/a.nix"
check silent Write file_path "$home/memory-notes/a.md"
check silent Bash command 'cat ~/memory/a.md'
check silent Bash command 'ls ~/memory/'
check silent Bash command 'grep -r x ~/memory/'
check silent Bash command 'echo x > /tmp/a.md'
check silent Bash command 'cp a.md /tmp/memory-notes'
[ "$fail" = 0 ] && echo ok
exit "$fail"
