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
