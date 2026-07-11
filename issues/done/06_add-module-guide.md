## PR記録: feat: docs-agents に module-guide を追加
issue: 06 (06_add-module-guide.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/22
Merged: 24cd8a1489a4ffdec5a520dfad506dab9f7ab4f0

## 変更内容
- docs-agents/module-guide.md（新規）: `~/dotfiles/docs-agents/module-guide.md` の内容をそのまま流用し、他ガイドと同形式の言語切り替えヘッダを付与。機密情報は含まれないためマスク不要。
- docs-agents/module-guide.en.md（新規）: 上記の英語版を新規作成。ヘッダの言語切り替えリンクを日本語版と対にした。
- README.md: 「Agent Development Guides」のリード文を「5ファイル」→「6ファイル」に修正し、表に module-guide.md の行を追加。
- README.en.md: 同様にリード文を「5 files」→「6 files」に修正し、対応する英語行を表に追加。

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook の評価が成功（既存の deprecated オプション警告のみで、今回の変更に起因するエラーなし）。
- 目視確認: module-guide.md はコピー元と本文差分なし（ヘッダ2行の追加のみ）。他ガイド（harness-guide.md 等）とヘッダ・見出し体裁が一致。README.md / README.en.md の表とリード文の記述数（6ファイル/6 files）が一致。
- git diff --name-only --cached:
  - README.en.md
  - README.md
  - docs-agents/module-guide.en.md
  - docs-agents/module-guide.md

## 検証手順
本 Issue はドキュメント追加のみで実行系の検証対象なし。目視レビューのみで問題ない。
