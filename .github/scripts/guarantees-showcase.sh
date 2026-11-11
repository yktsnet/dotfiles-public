#!/usr/bin/env bash
# yktsnet の public リポから保証台帳を集め、一覧の Markdown を書き出す。
# 出力に日時を入れない: 台帳が変わらない週に差分を出さないため。
set -euo pipefail

owner=yktsnet
out=${1:-${SHOWCASE_OUT:-docs/guarantees-showcase.md}}

fetch() { gh api -H 'Accept: application/vnd.github.raw' "repos/$owner/$1/contents/$2"; }

# 表のデータ行: `|` で始まる行から、表ごとの見出し行と区切り行を除く
count_rows() {
  awk '/^[[:space:]]*\|/ { rows++; if ($0 ~ /^[[:space:]]*\|[[:space:]:|-]+\|[[:space:]]*$/ && $0 ~ /-/) seps++ }
       END { print rows - 2 * seps }'
}

# `## Gaps` 節の項目: 箇条書きの先頭階層と表のデータ行
count_gaps() {
  awk '/^## / { in_gaps = ($0 ~ /^## Gaps[[:space:]]*$/); next }
       in_gaps && /^[-*] / { n++ }
       in_gaps && /^\|/ { rows++; if ($0 ~ /^\|[[:space:]:|-]+\|[[:space:]]*$/ && $0 ~ /-/) seps++ }
       END { print n + rows - 2 * seps }'
}

repos=$(gh api --paginate "users/$owner/repos?type=owner&per_page=100" \
  --jq '.[] | select(.private | not) | select(.archived | not) | select(.fork | not) | "\(.name) \(.default_branch)"' | sort)

rows=""
t_repos=0 t_guar=0 t_files=0 t_gaps=0
while read -r repo branch; do
  [[ -n "$repo" ]] || continue
  files=$(gh api "repos/$owner/$repo/contents/docs/guarantees?ref=$branch" --jq '.[] | select(.type == "file") | .name' 2>/dev/null) || continue
  grep -qx 'README.md' <<<"$files" || continue
  echo "Found ledger: $repo" >&2

  readme=$(fetch "$repo" "docs/guarantees/README.md?ref=$branch")
  if grep -m1 '^# ' <<<"$readme" | grep -q '(Draft)'; then state=Draft; else state=正式; fi
  gaps=$(count_gaps <<<"$readme")

  guar=0 nfiles=0
  while read -r f; do
    [[ -n "$f" ]] || continue
    [[ "$f" == README.md || "$f" == *.en.md || "$f" != *.md ]] && continue
    n=$(fetch "$repo" "docs/guarantees/$f?ref=$branch" | count_rows)
    guar=$((guar + n)) nfiles=$((nfiles + 1))
  done <<<"$files"

  updated=$(gh api "repos/$owner/$repo/commits?sha=$branch&path=docs/guarantees&per_page=1" --jq '.[0].commit.committer.date[0:10]')

  rows+="| [$repo](https://github.com/$owner/$repo/tree/$branch/docs/guarantees) | $guar | $nfiles | $gaps | $state | $updated |"$'\n'
  t_repos=$((t_repos + 1)) t_guar=$((t_guar + guar)) t_files=$((t_files + nfiles)) t_gaps=$((t_gaps + gaps))
done <<<"$repos"

mkdir -p "$(dirname "$out")"
cat >"$out" <<MD
# 保証台帳の一覧

保証駆動開発（GDD）では、何が壊れてはいけないか（保証）を人が先に承認し、それを固定するテストと実装はエージェントが書く。承認した保証は各リポの保証台帳 \`docs/guarantees/\` に、裏付けるテストと一緒に積み上がる。考え方は [Zenn: 保証駆動開発](https://zenn.dev/yktsnet/articles/202608-guarantee-driven-development) と [README の GDD の段落](../README.md#1-守る約束を先に書く) にある。この一覧は \`.github/scripts/guarantees-showcase.sh\` が週1回書き出すもので、手で直さない。

| リポ | 保証 | 対象ファイル | Gaps | 状態 | 最終更新 |
|---|---:|---:|---:|---|---|
${rows}| **合計（${t_repos} リポ）** | **${t_guar}** | **${t_files}** | **${t_gaps}** | | |
MD
echo "Wrote $out" >&2
