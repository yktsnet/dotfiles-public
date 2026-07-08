## PR記録: feat: aiagent.sh の issue open コミットをブランチ同乗化（private 側から同期）
issue: 05 (05_aiagent-open-commit-in-pr-sync.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/20
Merged: 9cb089eee88485fb504515c74bcc6f92e7eed16e

## 変更内容
private 側（~/dotfiles Issue 16）で実装した「`chore(issues): open` コミットを main 直積みからワークツリーブランチ同乗に変更」を公開ミラーへ移植した。

- `_aiagent_run()`: main 上での `chore(issues): open` コミット処理を削除し、`git worktree add` 後に issue ファイル1本だけを worktree へコピーしてブランチ上でコミットするよう変更。main 側では untracked のまま残す。
- `_aiagent_finish()`: PR 作成前の `git push origin main || return 1` とそのコメントを削除。
- `_aiagent_finish()`: squash マージ後の `git pull --prune` 直前に、head_branch の id に一致し untracked（`??`）な issue ファイルを削除する処理を追加（マージ後に origin 由来の tracked ファイルとして戻るため）。`issues_dir` の定義を関数冒頭へ前倒しし、後方の重複定義を削除。

これにより main は Issue 1件あたり「squash された実装（issue ファイル込み）」＋「close chore」の2コミットになり、open 分の main 直 push（保護ルールバイパス）が解消される。

## 静的確認結果
- `zsh -n zsh/functions/aiagent.sh`: OK（構文エラーなし）
- caller/import整合性: `_aiagent_run` / `_aiagent_finish` はいずれも `issue()` / `issue-finish()` から呼ばれる既存の唯一の呼び出し元であり、シグネチャ変更なし。`issues_dir` は `_aiagent_finish` 内で1箇所定義・複数箇所参照する形に統一。`issue_file_rel` は `_aiagent_run` 内でのみ使用する新規ローカル変数で、既存変数との衝突なし。`issue-abort` は変更していない。
- `git diff --name-only --cached`: zsh/functions/aiagent.sh（issue の対象と完全一致）

## 検証手順
実マージを伴う動作確認は user が次回の issue()〜issue-finish で実施する。
