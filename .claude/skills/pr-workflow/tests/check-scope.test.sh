#!/usr/bin/env bash
# check-scope.sh が、ブランチの変更と Issue の `対象` の一致・過不足を正しく判定することを確かめる。
# 一時ディレクトリにリポを作り、origin/main 相当の ref を置いて流す。
#
#   bash .claude/skills/pr-workflow/tests/check-scope.test.sh
SCRIPT="${1:-$(dirname "$0")/../scripts/check-scope.sh}"
SCRIPT=$(cd "$(dirname "$SCRIPT")" && pwd)/$(basename "$SCRIPT")
fails=0
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid
export GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid

# 新しいリポを作り、基点のコミットを origin/main として置く
newrepo() {
  repo="$work/r$((++n))"
  git init -q "$repo"
  git -C "$repo" config commit.gpgsign false
  printf 'base\n' >"$repo/base.txt"
  git -C "$repo" add -A
  git -C "$repo" commit -qm base
  git -C "$repo" update-ref refs/remotes/origin/main HEAD
  git -C "$repo" switch -qc work
}

put() { # put <パス> : ファイルを作ってステージする
  mkdir -p "$repo/$(dirname "$1")"
  printf '%s\n' "$RANDOM" >"$repo/$1"
  git -C "$repo" add "$1"
}

issue() { # issue <本文> : Issue ファイルを書く
  printf '%s\n' "$1" >"$work/issue.md"
}

run() { out=$(cd "$repo" && bash "$SCRIPT" "$work/issue.md" 2>&1); rc=$?; }

expect() { # expect <名前> <期待rc> [出力に含まれるべき文字列...]
  local name="$1" want="$2"
  shift 2
  local ok=1
  [ "$rc" -eq "$want" ] || ok=0
  local s
  for s in "$@"; do printf '%s' "$out" | grep -qF -- "$s" || ok=0; done
  if [ "$ok" -eq 1 ]; then printf 'ok   %s\n' "$name"; else printf 'FAIL %s (rc=%s)\n%s\n' "$name" "$rc" "$out"; fails=$((fails + 1)); fi
}

absent() { # absent <名前> <出力に含まれてはならない文字列>
  if printf '%s' "$out" | grep -qF -- "$2"; then printf 'FAIL %s\n%s\n' "$1" "$out"; fails=$((fails + 1)); else printf 'ok   %s\n' "$1"; fi
}

# --- 一致 ---
newrepo
put a.sh
put dir/b.md
issue $'対象: a.sh, dir/b.md\n内容: x'
run
expect "1行のカンマ区切りで一致すれば0で無言" 0
[ -z "$out" ] && printf 'ok   %s\n' "一致のときは出力が無い" || { printf 'FAIL 一致のときは出力が無い\n%s\n' "$out"; fails=$((fails + 1)); }

issue $'対象:\n- a.sh\n- dir/b.md\n内容: x'
run
expect "箇条書きで一致すれば0" 0

issue $'対象: `a.sh`, `dir/b.md`\n内容: x'
run
expect "バッククォートは無視する" 0

issue $'対象: a.sh (新規), dir/b.md（削除）\n内容: x'
run
expect "パスの後ろの注記は無視する" 0

issue $'対象: a.sh (新規, 追記あり), dir/b.md\n内容: x'
run
expect "注記の中のカンマで分割を誤らない" 0

issue $'対象:\n- a.sh（新規）\n- dir/b.md（「運用の前提」の説明, 補足）\n内容: x'
run
expect "箇条書きの注記（全角括弧・カンマ入り）を無視する" 0

# --- 対象外の行が混ざらない ---
issue $'対象: a.sh, dir/b.md\n対象外: c.txt\n内容: x'
run
expect "対象外の行のパスは対象に数えない" 0

issue $'対象:\n- a.sh\n- dir/b.md\n対象外: c.txt\n内容: x'
run
expect "箇条書きの直後の対象外を対象に数えない" 0

# --- 足りない ---
issue $'対象: a.sh, dir/b.md, extra-missing.txt\n内容: x'
run
expect "宣言したのに変更が無いパスは非0で missing に出す" 1 "missing" "extra-missing.txt"
absent "足りないだけのとき extra の見出しを出さない" "extra (changed"

# --- 余計 ---
issue $'対象: a.sh\n内容: x'
run
expect "宣言に無い変更は非0で extra に出す" 1 "extra" "dir/b.md"
absent "余計なだけのとき missing の見出しを出さない" "missing (declared"

# --- 両方 ---
issue $'対象: a.sh, ghost.txt\n内容: x'
run
expect "足りないと余計を分けて両方出す" 1 "missing" "ghost.txt" "extra" "dir/b.md"

# --- 削除 ---
newrepo
git -C "$repo" rm -q base.txt
issue $'対象: base.txt（削除）\n内容: x'
run
expect "削除したファイルも対象と照合する" 0

# --- issues/ は比べない ---
newrepo
put a.sh
put issues/99_x.md
put issues/done/98_y.md
issue $'対象: a.sh\n内容: x'
run
expect "issues/ 配下の変更は比べない" 0

# --- ステージ済み・コミット済み・未ステージ ---
newrepo
put a.sh
git -C "$repo" commit -qm c1
put dir/b.md
issue $'対象: a.sh, dir/b.md\n内容: x'
run
expect "コミット済みとステージ済みの両方を見る" 0

printf 'dirty\n' >>"$repo/a.sh"
printf 'new\n' >"$repo/untracked.txt"
run
expect "作業ツリーの未ステージの変更は見ない" 0

# 対象に無い追跡済みファイルを未ステージで変えても見ない
newrepo
put a.sh
printf 'dirty\n' >>"$repo/base.txt"
issue $'対象: a.sh\n内容: x'
run
expect "対象に無い追跡済みファイルの未ステージの変更は見ない" 0

# --- 箇条書きのブロックは対象の後で終わる ---
newrepo
put a.sh
issue $'対象:\n- a.sh\n内容: x\n\n---\n\n### 保証\n- 新たに宣言する保証:\n  - foo bar\n- other.txt'
run
expect "対象の後ろの別の箇条書きを対象に数えない" 0

# --- 分岐元から見る ---
newrepo
put a.sh
git -C "$repo" commit -qm c1
git -C "$repo" switch -q --detach origin/main
printf 'o\n' >"$repo/o.txt"
git -C "$repo" add o.txt
git -C "$repo" commit -qm advance
git -C "$repo" update-ref refs/remotes/origin/main HEAD
git -C "$repo" switch -q work
issue $'対象: a.sh\n内容: x'
run
expect "origin/main が先へ進んでいても、分岐元から見た差分で比べる" 0

# --- 入力の誤り ---
newrepo
issue $'内容: x'
run
expect "対象が読めなければ2で報告する" 2 "対象"

out=$(cd "$repo" && bash "$SCRIPT" "$work/none.md" 2>&1); rc=$?
expect "Issue ファイルが無ければ2" 2 "usage"

if [ "$fails" -eq 0 ]; then
  echo "すべて通過"
else
  echo "失敗 ${fails} 件"
  exit 1
fi
