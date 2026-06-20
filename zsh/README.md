# zsh

Issue 駆動ワークフロー（[docs-agents/issue-driven-workflow.md](../docs-agents/issue-driven-workflow.md)）を支えるシェル関数群と、その配線。

## 設計意図

ノードごとに役割が異なり（Mac=開発 / Linux サーバ=運用）、その役割は概ね OS に紐づく。
そのため共通操作は `functions/` に集約し、役割固有の差分だけを OS 別エントリ
（`darwin.nix` / `nixos.nix`）で分岐させている。

## 構成

| パス | 内容 |
|---|---|
| `functions/` | シェル関数の実体（`.sh`）。OS 非依存の唯一の実装。 |
| `ui.nix` | プロンプト（pure prompt）。ホストごとに色を切り替える。 |
| `common.nix` | 共通ベース。`functions/*.sh` を読み込み、`ui.nix` を import。 |
| `darwin.nix` | **Mac (nix-darwin) 用**エントリポイント。`common.nix` + macOS 固有差分。 |
| `nixos.nix` | **x86 / NixOS（Mac 以外）用**エントリポイント。`common.nix` + Linux 固有差分。 |

シェル関数の実装は 1 箇所（`functions/`）に集約し、2 つの OS 向けエントリポイントが
同じ実装を読み込む。これにより Mac と NixOS で関数の二重管理を避ける。

## 関数

| ファイル | 主な関数 |
|---|---|
| `functions/aiagent.sh` | `issue` `issue-init` `issue-abort` `issue-finish`（Claude Code 用 Issue 駆動） |
| `functions/jules.sh` | `jules` `jules-init` `jules-abort` `jules-finish`（Jules 用 Issue 駆動） |
| `functions/git.sh` | `gs` `gc` `gca` `gp` `gpl` ほか git ショートカット |
| `functions/utils.sh` | `y`（Yazi 連携）`list` `dot` `disk` `ssh`（fzf 補完）ほか |

## 配線

| デバイス | import するエントリポイント |
|---|---|
| `devices/gui/macbook` | `zsh/darwin.nix` |
| `devices/gui`（Linux GUI） | `zsh/nixos.nix` |
| `devices/headless`（Linux サーバ） | `zsh/nixos.nix` |
