---
name: pr-workflow
description: Issueファイルに基づく実装からPR作成までの標準フロー
disable-model-invocation: true
---
以下の手順でissueを実行する。$ARGUMENTSにissueファイルのパスを渡す。
**前提: AIはコードを書いてPRを出すまでが担当。実行・確認・マージはuserが行う。**

0. リポの `CLAUDE.md` を読む（`context/conventions.md` があればそれも）
1. issueファイルを読む
2. `git branch --show-current` で `claude/{id}-{branch-slug}` 上にいることを確認する（ブランチとworktreeは issue() が作成済み）。違うブランチなら報告して止まる
3. `git status` で未コミットがあれば報告して止まる
4. 対象ファイルを読んで実装
5. issueの「確認」項目と、リポ CLAUDE.md の「静的チェック / 検証手段」に従い提出前確認を行う
   - コードを読んでcaller・import・整合性を確認する
   - 実行系・デプロイ系コマンド（rebuild / deploy / 本番起動）は実行しない
6. `git add {変更したファイル}`
   `git diff --name-only --cached` を実行する。
   出力がissueの「対象」フィールドと完全一致することを確認する。
   不一致があれば実装に戻る。
7. `git commit -m "{type}: {タイトル}"`
8. PRボディを `issues/.pr_body_draft.md` に書き出してPRを作成する。
   `issues/.pr_body_draft.md` の内容:
   ## 変更内容
   {issueの内容フィールドを展開}
   ## 静的確認結果
   {確認項目に対してコードを読んで確認した結果。git diff --name-only HEAD~1 の出力を含める}
   ## 検証手順
   {Agent側で完結しない確認（実行・デプロイ・目視）を、リポ CLAUDE.md の検証手順の雛形に従って記載。なければ省略}
   `gh pr create --base main --title "{type}: {タイトル}" --body-file issues/.pr_body_draft.md`
9. PRのURLを出力して終了
   ✅ PR created: {URL}
   Next: issue-finish → 検証手順を実施
