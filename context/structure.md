# dotfiles-public ディレクトリ構造

どこに何があるか。コードの書き方（規約）は `conventions.md` を参照。
本ファイルは「このリポジトリ自体」の構造を示す。

## トップレベル

```
dotfiles-public/
├── flake.nix          # Flake エントリ（inputs: nixpkgs / home-manager / nix-darwin / disko ほか）
├── flake.lock         # 入力のロック（編集しない）
├── devices/           # デバイス別の NixOS / nix-darwin 構成
│   └── gui/           # 開発機（NixOS・macOS）
├── home-manager/      # ユーザ環境
│   ├── config/        # 配置する設定ファイル（Claude Code の共通指示）
│   └── modules/       # 再利用モジュール
├── .claude/
│   ├── settings.json  # 権限（allow/deny）・attribution・フックの配線
│   ├── hooks/         # PreToolUse / SessionStart フック（deny で判定できない遮断・注入）
│   └── skills/        # ワークフロー用スキル（正本。home-manager が ~/.claude/skills へ配置）
├── zsh/
│   └── functions/     # Issue 駆動ワークフローのシェルマクロ（issue / issue-finish 等）
├── apps/              # 運用スクリプト（zsh/ の secret 暗号化・guarantees-index の台帳索引）
├── docs-agents/       # skill に属さない覚え書き（memo/）
├── secrets-agents/    # 機密辞書（実値・公開しない / 読み書き禁止）
├── context/           # 本リポの Agent 向けコンテキスト（本ファイル群）
└── issues/            # ローカル Issue 管理（done/ に完了分と PR 控え）
```

## レイヤー構成

- **Flake 層**: `flake.nix` が全デバイス構成と home-manager を束ねるエントリ。
- **デバイス層**: `devices/gui/`。開発機ごとの差分だけを置き、共通モジュールを import。
- **ユーザ環境層**: `home-manager/`。エージェント関連（Claude Code・メモリ・機密・tmux のセッション管理等）を宣言的に管理。
- **ワークフロー層**: `zsh/functions/`。`issue` / `issue-abort` / `issue-finish` 等のマクロ。
- **ハーネス層**: `.claude/`。`settings.json` の deny（前方一致で足りるもの）と `hooks/` の PreToolUse（コマンド構造・編集先の判定が要るもの）で遮断を二段に分ける。`skills/` が正本で、`home-manager/modules/claude.nix` が `~/.claude/` へ配置する。
- **運用スクリプト層**: `apps/zsh/`。シェル関数の実体になる Python（secret 暗号化）。
- **基準**: 判断の基準は、それを使う skill の `SKILL.md` が持つ（複数の skill が読むものだけ `reference/`）。導入順序と前提は README の Principles 節。公開の基準は `.claude/skills/README.md`。
- **機密層**: `secrets-agents/`。実値辞書。公開せず、Agent からは読み書きしない。

## issues/

- `{NN}_{slug}.md`: 実装対象 Issue。`status: open` のものを Agent が処理。
- `00_template.md`: Issue ひな形。
- `done/`: マージした PR の記録。`issue-finish` が PR のタイトル・URL・本文を Issue と同名のファイルで書き出す。Issue ファイル自体は `status: close` のまま同ディレクトリに残る。
