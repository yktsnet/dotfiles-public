---
name: pr-workflow
description: Issue駆動開発における実装・検証・PR作成の標準フロー
disable-model-invocation: true
manual: true
---
以下の手順で割り当てられたIssueを実行する。
前提: Agentはコード編集とPR作成までを担当。実適用（rebuild / switch）・動作確認・マージはuserが行う。

0. `context/conventions.md` と `context/structure.md` を読み、技術スタックと規約・構造を把握する。
1. `issues/` ディレクトリ内の対象Issueファイル（status: open）を読み込む。
2. 実行環境（Claude Code または Jules）に応じたコンテキストを確認する。
   - Claude Codeの場合: ローカルブランチ `claude/{id}-{branch-slug}` 上にいることを認識。
   - Julesの場合: クラウドサンドボックス環境であり、ブランチ新規作成操作は不要であることを認識（現在のブランチでそのまま作業する）。
3. 対象ファイルに対して実装・修正を行う。
4. Issueの「確認」項目に従い静的チェックを実施する。
   - Nix を変更した場合: `nix flake check`（評価エラーの検出）。
   - Zsh を変更した場合: `zsh -n <file>` で構文チェック。
   - `nixos-rebuild` / `darwin-rebuild` / `home-manager switch` 等の実適用、`flake.lock` の編集、`secrets-agents/` の読み書き、`ssh` / `rsync` は禁止。
5. PRボディと控えファイルの作成。
   - `.git/pr_body.md` に以下の内容を書き出す。
   - 同内容を `issues/done/{id}_{branch-slug}_pr.md` にもコピーして作成する。
   - 情報セキュリティ: PR本文・コミットメッセージ・控えファイルに固有の接続情報（ドメイン実値・公開ポート・Tunnel UUID・本番絶対パス・Tailscale IP / SSHユーザ名・WiFi SSID 等）を直書きしない。`secrets-agents/` の辞書で定義された `<PLACEHOLDER>` を用いる。デバイス名（`sv6` 等）・localhost・開発ポート・リポジトリ相対パスは可。

   ## 変更内容
   {Issueの内容フィールドを展開}

   ## 静的確認結果
   {確認項目に対して実行した結果。git diff --name-only の出力を含む}

   ## 検証手順
   {実装内容から判断した、userが各デバイスで実適用・確認するための手順}

6. コミット対象の確認。
   - `git add` ですべての変更ファイル（作成した控えファイル `issues/done/{id}_{branch-slug}_pr.md` を含む）をステージングする。
   - `git diff --name-only --cached` を実行し、想定通りのファイルがステージングされているか確認する。
7. コミットの実行。
   - `git commit -m "{type}: {タイトル}"` を実行。
8. リモートへのプッシュ。
   - 現在のブランチをリモートにプッシュする（例: `git push origin HEAD`）。
9. PRの作成。
   - `gh pr create --base main --title "{type}: {タイトル}" --body-file .git/pr_body.md` を実行。
10. 作成されたPRのURLを出力してタスクを終了。
