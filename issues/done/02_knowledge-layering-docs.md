## PR記録: feat: 知識の配置基準をharness-guideに追加しREADMEに暗黙知の宣言化を追記
issue: 02 (02_knowledge-layering-docs.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/12
Merged: 282483e2ae3de364465d61adeab391dcc6af8b9a

## 変更内容
harness-guide に「知識をいつ skill にするか」の判断基準が欠けていたため、実運用（sops 手順書を skill 化し description に起動条件を書いたことで手渡しが不要になった例）から確立した基準を明文化した。

- `docs-agents/harness-guide.md`: §4「層2 — 指示ファイル」の `### Skills` 小節の後に `### 知識の配置基準` を追加。読み込みの契機による4分類の表、移住のトリガー、skill 骨格のコード片、skill 更新方針を記載。
- `README.md`: 「Philosophy & Core Architecture」に `### 4. 暗黙知の宣言化` を追記。課題→解の構成を既存3項目に揃え、詳細は harness-guide の新節へリンク。
- `docs-agents/harness-guide.en.md` / `README.en.md`: 上記2ファイルの追加分を英訳して同期。

## 静的確認結果
- `nix flake check`: 既存の警告（`programs.git.*` オプション名変更、x86_64-linux 省略）のみで、Markdown 変更に起因するエラーなし。
- 見出しID整合性を目視確認: README.md/en.md の新規リンク `docs-agents/harness-guide.md#知識の配置基準` / `#knowledge-placement-criteria` が harness-guide 側の新設見出し（`### 知識の配置基準` / `### Knowledge Placement Criteria`）の GitHub 生成アンカーと一致することを確認。
- 既存節の番号・参照は変更していない（新設は末尾追加のみ）。

```
$ git diff --name-only HEAD~1
README.en.md
README.md
docs-agents/harness-guide.en.md
docs-agents/harness-guide.md
```

## 検証手順
- GitHub 上で README.md / README.en.md の「4.」リンクから harness-guide.md / harness-guide.en.md の新節へ実際に遷移できることを目視確認する。
