## PR記録: docs: docs-agents の2層構造を README と Skill に明示する
issue: 17 (17_docs-agents-two-tier.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/48
Merged: 6000153e6302e17680f7386955523f9906cfddb3

## 変更内容
`docs-agents/` の7ガイドは「リポごとに答えが変わる判断層」と「一度決めれば機械的に適用できる定型層」の2層に分かれており、Skill 側の分担も既にその線で割れている。この構造が設計であることを README と Skill に明示した。

- README.md / README.en.md の `## Agent Development Guides` 節: リード文を書き換え、7行フラットの表を「判断層」「定型層」の2小見出し・2表に分割。役割説明の文言は既存を流用。
- README.en.md: `test-policy.md` 行のリンク先を `docs-agents/test-policy.en.md` から `docs-agents/test-policy.md` に修正し、他6行との不揃いを解消。
- `.claude/skills/repo-standardize/SKILL.md`: 「0. 基準を読む」節に、定型層4本を機械的に適用する側であることを1文追加。
- `.claude/skills/repo-readme/SKILL.md`: 同節に、判断層に伴走する側であることを1文追加。
- `.claude/skills/module-dev/SKILL.md`: 冒頭の規範参照直前に、判断層に伴走する側であることを1文追加。

3 Skill とも frontmatter（name/description/manual）は変更していない。層の定義自体は転記せず、自己申告の1文のみ。

## 保証
なし（ドキュメントと Skill 説明文のみの変更。実行される処理・判定ロジックを変えない。本リポに `docs/guarantees.md` は存在せず、既存テスト `apps/lpt/tests/` は本 Issue の対象範囲に触れない）

## 静的確認結果
- 目視確認: README.md と README.en.md の記述内容（リード文の3要点・層の区分・所属行）が一致していることを確認
- 表のリンク先7件（repo-guide.md / module-guide.md / readme-guide.md / issue-driven-workflow.md / harness-guide.md / cicd-guide.md / test-policy.md）が `docs-agents/` に実在することを確認
- 3 Skill の frontmatter（name/description/manual）が変更されていないことを diff で確認
- `git diff --name-only --cached`:
  .claude/skills/module-dev/SKILL.md
  .claude/skills/repo-readme/SKILL.md
  .claude/skills/repo-standardize/SKILL.md
  README.en.md
  README.md
