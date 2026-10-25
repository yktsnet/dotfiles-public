#!/usr/bin/env bash
# SessionStart hook: マージ済みの claude/* を畳み、main を取り直す。
#
# 畳む処理は i() の _aiagent_reap が持つが、i() を開き直さないと走らず、マージ後に
# ブランチ・worktree・main の遅れが残る。セッションを開くたびに同じ関数を呼んで拾う。
# 判定を書き分けないよう、関数は aiagent.sh を source して使う。
#
# 元のチェックアウトが main に居るときだけ動く（_aiagent_reap が main 以外では何もしない）。
# 実行者の worktree で開いたセッションは、自分のブランチを畳まない。
# 対象は i() が横断するリポ（AIAGENT_REPO_ROOTS）だけで、ほかのリポには触らない。
set -u

dir="${CLAUDE_PROJECT_DIR:-$PWD}"
funcs="${AIAGENT_FUNCS:-$HOME/dotfiles-public/home-manager/modules/zsh/functions/aiagent.sh}"
[ -r "$funcs" ] || exit 0
command -v zsh >/dev/null 2>&1 || exit 0
command -v gh >/dev/null 2>&1 || exit 0

# ネットワークが無いときに gh・fetch で起動を待たせない
perl -e 'alarm shift; exec @ARGV' 40 zsh -c '
  source "$1" || exit 0
  cd "$2" 2>/dev/null || exit 0
  root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
  (( ${${(f)"$(_aiagent_repos)"}[(Ie)$root]} )) || exit 0
  [[ -n "$(git for-each-ref --format=x "refs/heads/claude/*")" ]] || exit 0
  _aiagent_reap && (( REPLY )) && _aiagent_pull_main >/dev/null
' _ "$funcs" "$dir" 2>&1 | sed 's/^/reap-merged-branches: /'
