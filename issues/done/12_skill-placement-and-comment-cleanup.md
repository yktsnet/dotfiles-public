## PR記録: feat(skills): skill配置基準とcomment-cleanupを公開する
issue: 12 (12_skill-placement-and-comment-cleanup.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/38
Merged: 4534a92e378931eff678a72c31af2e92f49a56c7

## 変更内容
- `.claude/skills/skill-dev/SKILL.md` を新規作成。skillの配置先（global の `~/dotfiles/.claude/skills/` か repo-local か）を判断する基準を公開する。裁可済みの例外として `disable-model-invocation: true` を付けずに公開する（自動発火してこそ意味がある2skillのため）。
- `.claude/skills/module-dev/SKILL.md` を新規作成。`docs-agents/module-guide.md` への薄い入口。参照パスを本リポの相対パスに直した。同じく自動発火のまま公開する。
- `.claude/skills/comment-cleanup/SKILL.md` を新規作成。§3「適用」の参照先を、私物 `~/dotfiles/.claude/CLAUDE.md` の章名から本リポの `docs-agents/issue-driven-workflow.md` に差し替え、私物固有の例示をリポ種別の一般形に書き換えた。それ以外（検出方法・分類基準・完了報告）はそのまま移植。
- `plugins/public-skills/skills/comment-cleanup/SKILL.md` を新規作成。`.claude/skills/comment-cleanup/SKILL.md` と同一内容。
- `plugins/public-skills/.claude-plugin/plugin.json`: description に「コメント整理」を追加、version を 0.2.0 → 0.3.0 に更新。
- `.claude-plugin/marketplace.json`: `plugins[0].description` を同じ方針で更新。
- `README.md` / `README.en.md`: plugin marketplace 案内の skill 数を6→7に直し、列挙に comment-cleanup を追加（この1文のみ変更）。

## 保証
- 新たに宣言する保証:
  - `plugins[0].description`（plugin.json・marketplace.json）と README 日英の skill 列挙が4箇所で一致する → 目視確認（本文参照）。テスト基盤なし（裁可済み・見送る、Issue本文の記載どおり）
  - `.claude/skills/comment-cleanup/SKILL.md` と `plugins/public-skills/skills/comment-cleanup/SKILL.md` が同一内容である → `diff` コマンドで確認（差分なしを確認済み）
  - 追加する3 skill の frontmatter が `name` と `description` を持つ → 目視確認（本文参照）
- 維持する保証:
  - 既存6 skill（readme-i18n / repo-about / jp-writing / jp-writing-code / vhs-demo / app-demo-gif）の収録・内容は無変更 → `git diff --name-only --cached` に該当ファイルが含まれないことで確認
  - `.claude/skills/` の既存 skill は無変更 → 同上
  - `/plugin marketplace add` → `/plugin install public-skills` の導入手順文言は無変更（skill数と列挙のみ変更）

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook ✅（既存の deprecated warning のみ、本変更に起因するエラーなし）
- `jq empty plugins/public-skills/.claude-plugin/plugin.json` / `jq empty .claude-plugin/marketplace.json`: 両方とも構文OK
- frontmatter確認: skill-dev / module-dev は `disable-model-invocation` を持たない（Issueで裁可された意図的例外）。comment-cleanup は `disable-model-invocation: true` を保持
- `diff .claude/skills/comment-cleanup/SKILL.md plugins/public-skills/skills/comment-cleanup/SKILL.md`: 差分なし
- plugin.json / marketplace.json / README.md / README.en.md の skill 列挙（6 skill + comment-cleanup = 7）が4箇所で一致することを確認
- `git diff --name-only --cached`:
  ```
  .claude-plugin/marketplace.json
  .claude/skills/comment-cleanup/SKILL.md
  .claude/skills/module-dev/SKILL.md
  .claude/skills/skill-dev/SKILL.md
  README.en.md
  README.md
  plugins/public-skills/.claude-plugin/plugin.json
  plugins/public-skills/skills/comment-cleanup/SKILL.md
  ```
  Issueの「対象」8ファイルと完全一致

## 検証手順
本Issueはドキュメント/skill定義の追加のみで実行系コマンドを伴わないため、Agent側の静的確認で完結。強いて言えば `/plugin install public-skills` 実行後にComment-cleanup skillが一覧に出ることの目視確認をuser側で行うと確実（必須ではない）。
