#!/usr/bin/env bash
# トークンの持ち主が所有するリポのうち、docs/guarantees.md を持つものを探し、索引を書き出す。
# private リポまで拾うには、GH_TOKEN に全リポの Contents を読めるトークンを渡す。
set -euo pipefail

out="${GUARANTEES_OUT:-guarantees/README.md}"

rows=""
while IFS=$'\t' read -r full private branch url; do
  gh api "repos/${full}/contents/docs/guarantees.md?ref=${branch}" --silent 2>/dev/null || continue
  date=$(gh api "repos/${full}/commits?path=docs/guarantees.md&sha=${branch}&per_page=1" \
    --jq '.[0].commit.committer.date // empty' 2>/dev/null | cut -c1-10) || true
  vis=public; [ "$private" = true ] && vis=private
  rows+="| ${full#*/} | ${vis} | [docs/guarantees.md](${url}/blob/${branch}/docs/guarantees.md) | ${date} |"$'\n'
done < <(gh api --paginate "user/repos?affiliation=owner&per_page=100" \
  --jq '.[] | select((.archived or .fork) | not) | [.full_name, .private, .default_branch, .html_url] | @tsv' \
  | sort)

mkdir -p "$(dirname "$out")"
{
  echo "# 保証台帳"
  echo
  echo "各リポの \`docs/guarantees.md\` への索引。定期実行で作り直す。"
  echo
  echo "| リポ | 公開 | 台帳 | 最終更新 |"
  echo "|---|---|---|---|"
  printf '%s' "$rows"
} > "$out"
