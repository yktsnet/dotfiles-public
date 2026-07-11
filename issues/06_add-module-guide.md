## docs-agents に module-guide を追加
id: 06
branch-slug: add-module-guide
github_issue: 23
status: close
type: feat
対象: docs-agents/module-guide.md (新規), docs-agents/module-guide.en.md (新規), README.md, README.en.md
内容: OSS モジュール型リポ（ポートフォリオ兼実用）の設計規範ガイドを docs-agents に追加し、README 両言語の Agent Development Guides 一覧に反映する
確認: 目視確認（jp-writing 規範準拠、既存ガイドとのヘッダ体裁一致、README 表とリード文の記述数の整合性）
---
## 詳細

### docs-agents/module-guide.md（新規）
- コピー元: `~/dotfiles/docs-agents/module-guide.md`（内容はそのまま。固有接続情報等の機密は含まれていないため機密マスク不要）
- ヘッダに他ガイド（`docs-agents/harness-guide.md` 等）と同じ言語切り替えリンクを付与する:
  ```
  [🇯🇵 日本語](module-guide.md) | [🇬🇧 English](module-guide.en.md)
  ```
- 見出し `# Module Guide` はソースのまま流用可（他ガイドの見出し体裁と一致）。

### docs-agents/module-guide.en.md（新規）
- `readme-i18n` skill の手順に準じ、上記 `module-guide.md` から英語版を生成する。
- ヘッダの言語切り替えリンクは日本語版と対になるよう配置する。

### README.md
- 「Agent Development Guides」セクション（35行目付近、`docs-agents/harness-guide.md#知識の配置基準` の少し下）のリード文「5ファイルをセットで AI に渡し」を「6ファイルをセットで AI に渡し」に修正する。
- 表（85〜90行目付近）に以下の行を追加する（既存行の文体・列構成に合わせる）:
  ```
  | [module-guide.md](docs-agents/module-guide.md) | OSS モジュール型リポの設計規範。型の判断・構造・デモ方式 |
  ```

### README.en.md
- README.md と同様に、リード文の「5 files」相当の記述数を修正し、表に対応する英語行を追加する:
  ```
  | [module-guide.md](docs-agents/module-guide.md) | Design guide for OSS module-style repos. Type decisions, structure, demo methods |
  ```

### 実装順序
1. `docs-agents/module-guide.md` を作成（ヘッダ付与）
2. `docs-agents/module-guide.en.md` を作成
3. README.md 更新
4. README.en.md 更新
