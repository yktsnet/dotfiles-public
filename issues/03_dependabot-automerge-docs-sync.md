## Dependabot 自動マージ体制の公開版反映（repo-standardize 雛形 + cicd-guide 日英）
id: 03
branch-slug: dependabot-automerge-docs-sync
github_issue:
status: open
type: feat
対象:
- .claude/skills/repo-standardize/SKILL.md（雛形表とチェックリストに Dependabot 項目を追加）
- .claude/skills/repo-standardize/reference/dependabot-base.yml (新規)
- .claude/skills/repo-standardize/reference/dependabot-auto-merge.yml (新規)
- docs-agents/cicd-guide.md（「依存更新（Dependabot）」の節を追加）
- docs-agents/cicd-guide.en.md（同節の英語版）

内容: private 側（~/dotfiles）で確立した Dependabot 運用 — minor/patch は CI グリーンで自動マージ、major は保留、レジストリ系 ecosystem に cooldown 7日 — を、公開リポの repo-standardize skill と cicd-guide に反映する。private 側に正本が既にあるため、本 Issue は移植と公開リポ向けの表記調整が主作業。

確認: SKILL.md 内の参照が公開リポの実ファイル名（cicd-guide.md。private の cicd.md ではない）を指していること。cicd-guide.md と cicd-guide.en.md の節構成・表の行数が一致していること。reference/ の YAML 2枚が private 版と内容同一であること（diff で確認）。

---

## 正本（コピー元）

すべて同一マシンの private dotfiles にある。

- 運用ルールと構成の本文: `~/dotfiles/docs-agents/cicd.md` の「## 6. 依存更新（Dependabot）」節
- 雛形2枚: `~/dotfiles/.claude/skills/repo-standardize/reference/dependabot-base.yml` と `dependabot-auto-merge.yml`
- SKILL.md の追記済み差分: `~/dotfiles/.claude/skills/repo-standardize/SKILL.md`（雛形表の2行とチェックリスト1行）

## reference/ 雛形2枚

private 版をそのままコピーする。内容の改変はしない。

## .claude/skills/repo-standardize/SKILL.md

private 版 SKILL.md との diff を取り、雛形表の2行とチェックリスト1行を同位置に追加する。
ただし行中の `cicd.md §6` という参照は、公開リポでは `cicd-guide.md` の該当節名に置き換える（節番号は下記の追加位置により決まるため、追加後の実番号に合わせる）。

## docs-agents/cicd-guide.md

`~/dotfiles/docs-agents/cicd.md` §6 の内容を移植する。挿入位置は cicd-guide.md の既存構成を読んで判断してよいが、CI の節より後・担当分離の節より前が自然。移植時の調整点:

- 文中の `repo-standardize` の `reference/` への言及はそのまま有効（公開リポに同 skill があるため）
- 「9リポに適用済み」のような private 環境の適用実績・リポ名の列挙は書かない。公開ガイドとして手順と判断基準のみを書く
- 節番号・目次スタイルは cicd-guide.md の既存慣行に合わせる

## docs-agents/cicd-guide.en.md

上記で追加した日本語節の英訳を、en 版の同位置に追加する。既存 en 版の文体・用語（他節の訳語）に合わせる。

## 実装順序

reference/ 雛形 → cicd-guide.md → cicd-guide.en.md → SKILL.md（参照節名が確定してから）。
