# about：About と topics を設定する

README.en.md（なければ README.md）を読み、GitHub の About（description）と topics を生成して適用する。

## 手順

1. **README の確認**
   - `README.en.md` があれば優先して読み、なければ `README.md` を読む。

2. **内容の生成**
   - **Description**: リポが何をするものかを1文で言う英文（100〜120文字程度）を生成する。
   - **Topics**: 技術スタック、用途、主要機能からキーワードを 5〜10 個抽出する。

3. **確認と適用**
   - 提案する description と topics をユーザーに提示して確認を得る。
   - 確認後、既存の topics を一度すべて削除（クリーンリセット）してから、`gh repo edit` を用いて設定を適用する。
     - 削除は `gh repo view --json repositoryTopics` で既存の topic を取得し、各 topic を `--remove-topic` で除去する。
