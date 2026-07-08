# dotfiles-public ディレクトリ構造

どこに何があるか。コードの書き方（規約）は `conventions.md` を参照。
本ファイルは「このリポジトリ自体」の構造を示す。

## トップレベル

```
dotfiles-public/
├── flake.nix          # Flake エントリ（inputs: nixpkgs / home-manager / nix-darwin / disko / chaotic）
├── flake.lock         # 入力のロック（編集しない）
├── devices/           # デバイス別の NixOS / nix-darwin 構成
│   ├── gui/           # GUI デバイス（macOS 等）
│   └── headless/      # ヘッドレス VPS
├── home-manager/      # ユーザ環境
│   ├── config/        # 各種 dotfiles 設定
│   └── modules/       # 再利用モジュール
├── zsh/
│   └── functions/     # Issue 駆動ワークフローのシェルマクロ（issue / issue-finish 等）
├── apps/              # アプリ共通の env 定義（env-context.nix）
├── docs/              # 環境ドキュメント（tui_environment.md 等）
├── docs-agents/       # AI Agent 向けガイド（cicd / harness / issue-driven / readme / repo-guide）
├── secrets-agents/    # 機密辞書（実値・公開しない / 読み書き禁止）
├── context/           # 本リポの Agent 向けコンテキスト（本ファイル群）
└── issues/            # ローカル Issue 管理（done/ に完了分と PR 控え）
```

## レイヤー構成

- **Flake 層**: `flake.nix` が全デバイス構成と home-manager を束ねるエントリ。
- **デバイス層**: `devices/`。GUI / headless で分け、共通モジュールを import。
- **ユーザ環境層**: `home-manager/`。TUI ツールチェーン（Neovim・Yazi・Tmux 等）と dotfiles を宣言的に管理。
- **ワークフロー層**: `zsh/functions/`。`issue` / `issue-abort` / `issue-finish` 等のマクロ。
- **ガイド層**: `docs-agents/`。新規リポの組成・ハーネス・CI/CD・README・Issue プロセスの基準。
- **機密層**: `secrets-agents/`。実値辞書。公開せず、Agent からは読み書きしない。

## issues/

- `{NN}_{slug}.md`: 実装対象 Issue。`status: open` のものを Agent が処理。
- `00_template.md`: Issue ひな形。
- `done/`: マージした PR の記録。`issue-finish` が PR のタイトル・URL・本文を Issue と同名のファイルで書き出す。Issue ファイル自体は `status: close` のまま同ディレクトリに残る。
