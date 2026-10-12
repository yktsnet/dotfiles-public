#!/usr/bin/env bash
# block-live-claude-config-edit.sh にペイロードを流して deny/allow を確かめる。
# 実際の書き込みは行わない。判定が「配布先パスがどこかにある」だけで発火して
# いた頃、本文中の `<timestamp>` の `>` をリダイレクトと誤認して正本側の編集まで
# 拒否していた。そのクラスの誤爆と、対応する見逃しを固定する。
#
#   bash .claude/hooks/tests/block-live-claude-config-edit.test.sh
HOOK="${1:-$(dirname "$0")/../block-live-claude-config-edit.sh}"
L="$HOME/.claude"          # 配布先（Nix 管理・直接編集は拒否）
D="/work/dotfiles-public/.claude" # 正本（編集してよい）
fails=0

run() { # run <期待 deny|allow> <説明> <コマンド>
  local want="$1" desc="$2" cmd="$3" got
  if jq -n --arg c "$cmd" '{tool_name:"Bash",tool_input:{command:$c}}' | bash "$HOOK" | grep -q '"deny"'; then got=deny; else got=allow; fi
  if [ "$got" = "$want" ]; then
    printf '  ok   %-5s %s\n' "$got" "$desc"
  else
    printf '  FAIL %-5s (期待 %s) %s\n' "$got" "$want" "$desc"; fails=$((fails + 1))
  fi
}

check() { # check <tool> <file_path> <期待>
  local got
  if jq -n --arg t "$1" --arg f "$2" '{tool_name:$t,tool_input:{file_path:$f}}' | bash "$HOOK" | grep -q '"deny"'; then got=deny; else got=allow; fi
  if [ "$got" = "$3" ]; then
    printf '  ok   %-5s %s %s\n' "$got" "$1" "$2"
  else
    printf '  FAIL %-5s (期待 %s) %s %s\n' "$got" "$3" "$1" "$2"; fails=$((fails + 1))
  fi
}

echo "== Bash: 止める =="
run deny "リダイレクトで settings.json を上書き" "echo x > $L/settings.json"
run deny "追記リダイレクト"                      "echo x >> $L/CLAUDE.md"
run deny "クォート付きリダイレクト"              "echo x > \"$L/settings.json\""
run deny "\$HOME 表記のリダイレクト"             'cat > "$HOME/.claude/settings.json" <<EOF
{}
EOF'
run deny "ヒアドキュメントを配布先へ流し込む"    "cat <<'EOF' > $L/hooks/new.sh
#!/bin/sh
EOF"
run deny "sed -i でフックを書き換え"             "sed -i 's/a/b/' $L/hooks/foo.sh"
run deny "perl -pi -e"                           "perl -pi -e 's/a/b/' $L/CLAUDE.md"
run deny "cp で skills へ配置"                   "cp /tmp/SKILL.md $L/skills/bar/SKILL.md"
run deny "install で配置"                        "install -Dm644 /tmp/x $L/hooks/x.sh"
run deny "ln -sf で差し替え"                     "ln -sf /tmp/x $L/skills/foo"
run deny "パイプ先の tee"                        "cat /tmp/a | tee $L/settings.json"
run deny "mkdir で skills にディレクトリ作成"    "mkdir -p $L/skills/newskill"
run deny "agents/ へリダイレクト"                "echo x > $L/agents/new.md"
run deny "rm -rf で skills を消す"               "rm -rf $L/skills/bar"
run deny "&& の後ろで rm -rf（末尾スラッシュなし）" "cd /tmp && rm -rf $L/hooks"
run deny "シェルにヒアドキュメントで削除させる"  "bash <<'EOF'
rm -rf $L/hooks
EOF"

echo "== Bash: 通す =="
run allow "配布先を読むだけ"                     "cat $L/settings.json"
run allow "2>/dev/null 付きの読み取り"           "cat $L/settings.json 2>/dev/null"
run allow "配布先を head で読む"                 "head -20 $L/settings.json"
run allow "配布先を ls"                          "ls $L/skills/"
run allow "配布先を含む find"                    "find $L/skills -name SKILL.md"
run allow "配布先のパスを grep の引数に書く"     "grep -rn '$L/hooks/' ."
run allow "配布先と正本を diff"                  "diff $L/settings.json $D/settings.json"
run allow "配布先から正本へ差分を取る"           "diff -r $L/skills $D/skills"
run allow "正本側を sed -i で編集"               "sed -i 's/a/b/' $D/settings.json"
run allow "正本側へリダイレクト"                 "echo x > $D/hooks/foo.sh"
run allow "本文に配布先パスが混じる python"      "python3 - <<'PY'
import pathlib
p = pathlib.Path('.claude/skills/sops-secrets/SKILL.md')
s = p.read_text()
s = s.replace('\`$L/hooks/foo.sh\` が残す', '例外はない')
p.write_text(s)
PY"
run allow "配布先を語る文書を正本へ書く"         "cat > $D/docs.md <<'EOF'
$L/hooks/ は home-manager が配る複製。install / cp / mv で直接触らない。
EOF"
run allow "配布先を語るコミットメッセージ"       "git commit -F - <<'EOF'
fix(hooks): $L/hooks/ の複製を配り直す

rm -rf + cp でデプロイされるため、$L/settings.json は直接編集しない。
EOF"

echo "== Edit / Write =="
check Edit  "$L/settings.json"            deny
check Edit  "$L/CLAUDE.md"                deny
check Edit  "$L/hooks/x.sh"               deny
check Write "$L/skills/x/SKILL.md"        deny
check Edit  "$D/settings.json"            allow
check Write "$D/hooks/x.sh"               allow
check Edit  "$L/projects/foo/memory/x.md" allow
check Edit  "$L/agents/x.md"              deny

if [ "$fails" -eq 0 ]; then echo "全て期待どおり"; else echo "FAIL $fails 件"; fi
exit $((fails > 0))
