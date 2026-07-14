## PR記録: feat: 保証運用をワークフロー文書に反映する
issue: 07 (07_guarantee-workflow-docs-sync.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/25
Merged: dd57aac893502215a3569a28de1bdcf69875c686

## 変更内容
私物dotfiles側で導入した保証運用（Issueの「保証」節をuserがdraft→openで裁可・保証台帳 docs/guarantees.md・Issueテンプレート正本のスキル側一本化）を、公開ワークフロー文書に反映した。

- docs-agents/issue-driven-workflow.md / .en.md:
  - 「Issue フォーマット」節にテンプレートの `### 保証` 節を追記し、保証節の記法（自然言語で振る舞いを書く／テストなしは理由付きで明示）を一文追加
  - 「ライフサイクル」節の `draft → open` 遷移に「user が保証節を裁可」を明記し、`open` の意味に保証裁可済みを含めた
  - 「担当分離」の表に user の作業として「Issue保証節の裁可」を追加し、相談者がIssueを演じる場合の書き出し既定を `status: draft` に変更（user 裁可後に `open` へ）
  - 「プロジェクト構成」節のツリーから `issues/00_template.md` を除去し、テンプレート正本がグローバルスキル側（`~/.claude/skills/repo-standardize/reference/issue-template.md`、`new-issue` が参照）にある旨を追記
  - 英語版は日本語版と同内容に同期
- docs-agents/test-policy.md / .en.md（新規）: テスト方針を明文化。テストは変更可能性の担保／保証はIssueの保証節で人間が裁可・実装は実行者／濃淡はリスクベース／fixに回帰テスト同梱／外部依存はDI+fake／保証台帳 docs/guarantees.md の運用を記載
- issues/00_template.md / .en.md: テンプレート正本一本化に伴いドリフトしていたコピーを削除

## 保証
なし（ドキュメントのみの変更。裏付けるテストは存在しない）

## 静的確認結果
目視確認: 全対象がMarkdown。
- issue-driven-workflow.md / .en.md は互いに同内容で同期していることを確認
- test-policy.md / .en.md は私物dotfiles側 docs-agents/test-policy.md と同内容で、固有情報（実ドメイン・パス等）を含まないことを確認
- docs-agents 配下に `00_template` への参照が残っていないことを grep で確認
- `docs/guarantees.md` は本リポに未設置であり、本Issueの保証は「なし」のため台帳更新は不要
- `nix flake check` 実行、exit 0（既存の nixpkgs 非推奨警告のみで、本変更に起因するエラーなし）

git diff --name-only --cached:
docs-agents/issue-driven-workflow.en.md
docs-agents/issue-driven-workflow.md
docs-agents/test-policy.en.md
docs-agents/test-policy.md
issues/00_template.en.md
issues/00_template.md

## 検証手順
ドキュメントのみの変更のため、Agent側確認で完結。追加の実行確認は不要。
