#!/usr/bin/env bash
# トークンの持ち主が所有するリポのうち、保証台帳を持つものを探し、索引を書き出す。
# 台帳はディレクトリの docs/guarantees/README.md を見る。移行前のリポに残る1ファイルの docs/guarantees.md も拾う。
# private リポまで拾うには、GH_TOKEN に全リポの Contents を読めるトークンを渡す。
set -euo pipefail

out="${GUARANTEES_OUT:-guarantees/README.md}"

rows=""
while IFS=$'\t' read -r full private branch url; do
  path=""
  for p in docs/guarantees/README.md docs/guarantees.md; do
    if gh api "repos/${full}/contents/${p}?ref=${branch}" --silent 2>/dev/null; then path=$p; break; fi
  done
  [ -n "$path" ] || continue
  dir=${path%/README.md}
  date=$(gh api "repos/${full}/commits?path=${dir}&sha=${branch}&per_page=1" \
    --jq '.[0].commit.committer.date // empty' 2>/dev/null | cut -c1-10) || true
  vis=public; [ "$private" = true ] && vis=private
  rows+="| ${full#*/} | ${vis} | [${dir}](${url}/blob/${branch}/${path}) | ${date} |"$'\n'
done < <(gh api --paginate "user/repos?affiliation=owner&per_page=100" \
  --jq '.[] | select((.archived or .fork) | not) | [.full_name, .private, .default_branch, .html_url] | @tsv' \
  | sort)

mkdir -p "$(dirname "$out")"
{
  echo "# 保証台帳"
  echo
  echo "各リポの保証台帳（\`docs/guarantees/\`）への索引。定期実行で作り直す。"
  echo
  echo "| リポ | 公開 | 台帳 | 最終更新 |"
  echo "|---|---|---|---|"
  printf '%s' "$rows"
} > "$out"
