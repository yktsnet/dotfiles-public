## 保証運用（保証節・保証台帳・テンプレート正本一本化）をワークフロー文書に反映する
id: 07
branch-slug: guarantee-workflow-docs-sync
github_issue: 26
status: close
type: feat
対象:
- docs-agents/issue-driven-workflow.md
- docs-agents/issue-driven-workflow.en.md
- docs-agents/test-policy.md (新規)
- docs-agents/test-policy.en.md (新規)
- issues/00_template.md（削除）
- issues/00_template.en.md（削除）
内容: 私物dotfiles側で導入した保証運用（Issueの「保証」節をuserがdraft→openで裁可・保証台帳 docs/guarantees.md・Issueテンプレート正本のスキル側一本化）を、公開ワークフロー文書に反映する。テスト方針文書 test-policy.md を新設し、ドリフトしていた issues/00_template.md は正本一本化に伴い削除する。
確認: 目視確認（全対象がMarkdown）

---

### 保証

- 保証: なし（ドキュメントのみの変更。裏付けるテストは存在しない）

### 背景

私物dotfilesのIssue 19で以下を導入した。本リポの docs-agents はワークフローの公開版のため追従する。

1. Issueテンプレートに「保証」節（この変更で新たに宣言する保証・維持する保証を自然言語で列挙）を追加し、user が draft→open の裁可で保証節を必ず読む運用にした（open は保証裁可済みを意味する）
2. テスト方針を docs-agents/test-policy.md として明文化した
3. 各リポにコピー配布していた issues/00_template.md を廃止し、テンプレート正本を new-issue スキルが読む単一ファイルに一本化した

### 仕様

#### issue-driven-workflow.md / .en.md

- 「Issue フォーマット」節: フィールド一覧の後に「保証」節を追記し、テンプレートの引用例を新形式（`### 保証` を含む）に更新する
- 「ライフサイクル」節: `open` の意味に「user が保証節を裁可済み」を含める。相談者の書き出し既定が `draft` になったことを反映する
- 「プロジェクト構成」節: ツリーから `issues/00_template.md` を除去し、テンプレート正本はグローバルスキル側（new-issue が参照）にある旨を一文添える
- 担当分離の表: user の作業に「Issue保証節の裁可」を加える
- 英語版は日本語版と同内容に同期する（readme-i18n の規範に従う）

#### test-policy.md / .en.md（新規）

私物dotfiles側の test-policy.md と同内容で作成する（公開に際して固有情報は含まれないことを確認する）。骨子:

- テストは変更可能性の担保。実行者（AI）が壊したことに自分で気づくための装置であり、注意し続ける人間を前提にしない
- 保証（何が壊れてはいけないか）はIssueの保証節で人間が裁可し、テストの実装は実行者が書く
- 濃淡はリスクベース: 公開API・契約面は厚く、内部実装は薄く、UI・見た目は user の手動検証に回す
- fix には回帰テストを同梱する
- 外部依存はDIで受け、テストは fake で差し替える
- 保証台帳 `docs/guarantees.md`: 契約面の保証の箇条書き＋対応テスト表。初版は契約棚卸しで敷設し、以後はIssueの保証節と同一PRで更新する

#### issues/00_template.md / .en.md の削除

- 正本一本化により本リポのコピーは読まれなくなったため削除する。本Issue自体が新テンプレート形式で書かれていることが移行の確認を兼ねる
