## aiagent.sh: 必須チェック対応のマージ待機ロジックを private 側から同期
id: 04
skill: pr-workflow
branch-slug: aiagent-merge-wait-sync
github_issue: 19
status: close
type: fix
対象:
- zsh/functions/aiagent.sh（`_aiagent_finish()` 内 L107 付近の `gh pr merge` ブロック）
内容: `_aiagent_finish()` の `gh pr merge "$pr_num" --merge` は、main に必須ステータスチェック（ruleset）があるリポで CI 完了前のマージが拒否されて中断する（本リポ PR #16 で発生）。private 側（~/dotfiles Issue 15）で修正した「即時マージ→失敗時 auto-merge + マージ完了待ち」のロジックを本リポの公開ミラーに移植する。**前提: ~/dotfiles 側の修正がマージ済みであること**（正本は private 側。本 Issue は移植のみ）。
確認: `zsh -n zsh/functions/aiagent.sh`。移植後、private 側の該当ブロックとの差分が sed 書式差等の既知の差異のみであることを diff で目視確認する
---
## 移植時の注意

- 正本は `~/dotfiles/zsh/neo/aiagent.sh`（ただし Builder は本リポの worktree 内で作業するため、正本の内容は本 Issue 記載の要件と PR #16 の経緯から再構成せず、user が正本の該当ブロックを Issue 起動時に提示するか、詳細を本ファイルに追記してから起動する）。
- 要件の要点: (1) 即時 `gh pr merge --merge` をまず試行、(2) 失敗時のみ `--auto` を有効化して CI 完了とマージ完了（state=MERGED）をポーリングで待つ、(3) タイムアウトあり、(4) CI fail 時はマージせず中断。
- 機密の実値は含まれないブロックだが、コメント等に固有接続情報を書かないこと。
