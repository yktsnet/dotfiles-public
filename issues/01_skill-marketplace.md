## dotfiles-public を Claude Code plugin marketplace として配布可能にする
id: 01
branch-slug: skill-marketplace
github_issue: 3
status: close
type: feat
対象:
- .claude-plugin/marketplace.json (新規)
- plugins/public-skills/.claude-plugin/plugin.json (新規)
- plugins/public-skills/skills/readme-i18n/SKILL.md (新規、.claude/skills/readme-i18n/SKILL.md をコピー)
- plugins/public-skills/skills/repo-about/SKILL.md (新規、.claude/skills/repo-about/SKILL.md をコピー)
- plugins/public-skills/skills/jp-writing/SKILL.md (新規、.claude/skills/jp-writing/SKILL.md をコピー)
- plugins/public-skills/skills/jp-writing-code/SKILL.md (新規、.claude/skills/jp-writing-code/SKILL.md をコピー+パス修正)
- README.md (追記)
内容: dotfiles-public に Claude Code の plugin marketplace 機構を追加し、配布価値のある4 skill（readme-i18n, repo-about, jp-writing, jp-writing-code）を `public-skills` プラグインとして切り出す。`.claude/skills/` 配下の既存ファイルは触らない（自分の `skill()` zsh 関数がそちらを直接参照しているため）。切り出しは**コピー**であり移動ではない。
確認: `.claude-plugin/marketplace.json` と `plugins/public-skills/.claude-plugin/plugin.json` がJSONとして valid であること。各 SKILL.md のフロントマター（name/description）がコピー元と一致していること。目視確認。

---

## 対象外（明示的にスコープ外）

- `repo-standardize` / `repo-readme` / `new-issue` は `~/dotfiles/docs-agents/` や `~/dotfiles/secrets-agents/` への絶対パス依存が強く私的運用に紐づくため、今回は配布対象に含めない。
- README.en.md への同期は本Issueでは行わない（別途 `readme-i18n` skill 実行で対応可能なため）。

## `.claude-plugin/marketplace.json`（リポジトリルート、新規）

```json
{
  "name": "dotfiles-public",
  "owner": {
    "name": "yktsnet"
  },
  "plugins": [
    {
      "name": "public-skills",
      "source": "./plugins/public-skills",
      "description": "汎用性のある Claude Code Skills（README多言語化・GitHub About生成・日本語文章規範）"
    }
  ]
}
```

## `plugins/public-skills/.claude-plugin/plugin.json`（新規）

plugin.json は許可された8フィールドのみ（余分なキーがあるとCIで弾かれる）。skills は標準ディレクトリ（`plugins/public-skills/skills/`）に置くため `skills` フィールドは省略してよい。

```json
{
  "name": "public-skills",
  "version": "0.1.0",
  "description": "README多言語化・GitHub About生成・日本語文章規範の Skills 集"
}
```

## SKILL.md のコピー元と配置

以下4ファイルを `.claude/skills/{name}/SKILL.md` から `plugins/public-skills/skills/{name}/SKILL.md` へ**そのままコピー**する（frontmatter・本文とも変更なし）。

- `readme-i18n`
- `repo-about`
- `jp-writing`

`jp-writing-code` のみ、コピー時に本文中のパス参照を修正する。

- 修正前: `規範は ~/dotfiles/.claude/skills/jp-writing/SKILL.md の「規範」セクションに従う。毎回読みに行くこと。`
- 修正後: `規範は同一プラグイン内の ../jp-writing/SKILL.md の「規範」セクションに従う。毎回読みに行くこと。`

理由: `~/dotfiles/...` は user のローカル絶対パスで、marketplace 経由でインストールした第三者の環境には存在しない。同一プラグイン内での相対参照に置き換える。

## README.md 追記

「Core Workflows (Zsh Functions)」節の末尾（`skill` 項目の後）に、以下の趣旨の1〜2文＋コマンド例を追記する。

- このリポジトリは Claude Code の plugin marketplace としても利用可能であること
- 導入コマンド: `` `/plugin marketplace add yktsnet/dotfiles-public` `` → `` `/plugin install public-skills` ``
- 対象は `public-skills` プラグイン（readme-i18n, repo-about, jp-writing, jp-writing-code）のみで、他の私的運用skillは含まれないこと

文章量は既存の箇条書き項目と同程度（1項目分）に収め、新規セクションは立てない。
