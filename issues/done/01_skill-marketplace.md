## PR記録: feat: dotfiles-public を Claude Code plugin marketplace として配布可能にする
issue: 01 (01_skill-marketplace.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/2
Merged: daf5cfb1b6d7fb9f5ae081ffa6334e448e00205e

## 変更内容
dotfiles-public に Claude Code の plugin marketplace 機構を追加し、配布価値のある4 skill（readme-i18n, repo-about, jp-writing, jp-writing-code）を `public-skills` プラグインとして切り出した。`.claude/skills/` 配下の既存ファイルは変更していない（`skill()` zsh 関数がそちらを直接参照しているため）。切り出しはコピーであり移動ではない。

- `.claude-plugin/marketplace.json`（新規）: `public-skills` プラグインを1件登録
- `plugins/public-skills/.claude-plugin/plugin.json`（新規）: 許可された3フィールドのみで構成
- `plugins/public-skills/skills/{readme-i18n,repo-about,jp-writing}/SKILL.md`（新規）: コピー元と frontmatter・本文とも完全一致
- `plugins/public-skills/skills/jp-writing-code/SKILL.md`（新規）: コピー元から本文中のパス参照2箇所を `~/dotfiles/.claude/skills/jp-writing/SKILL.md` → `../jp-writing/SKILL.md`（同一プラグイン内相対参照）に修正
- `README.md`: 「Core Workflows (Zsh Functions)」節末尾に marketplace 導入コマンドを1項目追記

対象外（Issue内で明示的にスコープ外）: `repo-standardize` / `repo-readme` / `new-issue`（ローカル絶対パス依存が強いため）、README.en.md への同期。

## 静的確認結果
- `.claude-plugin/marketplace.json`、`plugins/public-skills/.claude-plugin/plugin.json` は `python3 -m json.tool` で valid JSON であることを確認。
- 各 SKILL.md のフロントマター（name/description）はコピー元と `diff` で完全一致を確認。
- `jp-writing`, `readme-i18n`, `repo-about` の SKILL.md は本文含めコピー元と完全一致（`diff` で差分なし）。
- `jp-writing-code` の SKILL.md はコピー元との差分が意図した2箇所のパス修正のみであることを `diff` で確認。
- Nix/Zsh ファイルの変更なしのため `nix flake check` / `zsh -n` は対象外。
- `git diff --name-only HEAD~1`:
```
.claude-plugin/marketplace.json
README.md
plugins/public-skills/.claude-plugin/plugin.json
plugins/public-skills/skills/jp-writing-code/SKILL.md
plugins/public-skills/skills/jp-writing/SKILL.md
plugins/public-skills/skills/readme-i18n/SKILL.md
plugins/public-skills/skills/repo-about/SKILL.md
```

## 検証手順
- ローカルまたは別環境で `/plugin marketplace add yktsnet/dotfiles-public` → `/plugin install public-skills` を実行し、4 skill（readme-i18n, repo-about, jp-writing, jp-writing-code）が一覧・起動できることを確認する。
- `jp-writing-code` を実行し、`../jp-writing/SKILL.md` への相対参照が同一プラグイン内で正しく解決されることを確認する。
