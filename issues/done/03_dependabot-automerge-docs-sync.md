## PR記録: feat: Dependabot 自動マージ体制を公開版に反映（repo-standardize + cicd-guide 日英）
issue: 03 (03_dependabot-automerge-docs-sync.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/16
Merged: c1523b08fc26586a84b5994bec7b8808b360284a

## 変更内容
private 側（~/dotfiles）で確立した Dependabot 運用（minor/patch は CI グリーンで自動マージ、major は保留、レジストリ系 ecosystem に cooldown 7日）を、公開リポの repo-standardize skill と cicd-guide に反映した。

- `.claude/skills/repo-standardize/reference/dependabot-base.yml`（新規）: private 版と同一内容でコピー
- `.claude/skills/repo-standardize/reference/dependabot-auto-merge.yml`（新規）: private 版と同一内容でコピー
- `docs-agents/cicd-guide.md`: 「## 6. 依存更新（Dependabot）」節を新設（既存の「担当分離との接続」は §7 に繰り下げ）。private 側 cicd.md §6 の運用ルールを移植し、公開ガイドとして手順・判断基準のみを記載（private 環境の適用実績・リポ名列挙は含めない）
- `docs-agents/cicd-guide.en.md`: 上記日本語節の英訳を同位置（§6）に追加、既存 §6 は §7 に繰り下げ
- `.claude/skills/repo-standardize/SKILL.md`: 雛形表に2行（dependabot-base.yml / dependabot-auto-merge.yml）、決定的チェックリストに1行を追加。参照は公開リポの実ファイル名 `cicd-guide.md §6` を指すよう調整（private 版は `cicd.md §6`）

## 静的確認結果
- reference/ の YAML 2枚: private 版との `diff` で差分なし（内容同一）を確認
- SKILL.md: private 版との `diff` で、追加した3箇所が `cicd.md §6` → `cicd-guide.md §6` の参照置換のみで、他の差分がないことを確認
- cicd-guide.md / cicd-guide.en.md: 新設した §6 の行数が日英で一致（22行）、既存 §6→§7 の繰り下げも日英で対応していることを確認
- `nix flake check`: darwinConfigurations.macbook で ✅（評価エラーなし。既存の非関連 deprecation warning のみ）
- `git diff --name-only --cached` が issue の「対象」フィールドと完全一致:
  - .claude/skills/repo-standardize/SKILL.md
  - .claude/skills/repo-standardize/reference/dependabot-auto-merge.yml
  - .claude/skills/repo-standardize/reference/dependabot-base.yml
  - docs-agents/cicd-guide.en.md
  - docs-agents/cicd-guide.md

## 検証手順
本 Issue はドキュメント・雛形の移植のみで実行系の変更を伴わないため、追加の実機検証は不要。次に repo-standardize skill を使う新規/既存リポで、追加した dependabot 雛形2枚とチェックリスト項目が意図通り機能することを確認する。

---

## Dependabot 自動マージ体制の公開版反映（repo-standardize 雛形 + cicd-guide 日英）
id: 03
branch-slug: dependabot-automerge-docs-sync
github_issue: 17
status: close
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
