# zsh

Issue 駆動ワークフロー（[new-issue](../../../.claude/skills/new-issue/SKILL.md)）を実行するシェル関数と、その配線。

## 構成

| パス | 内容 |
|---|---|
| `functions/` | シェル関数の実体（`.sh`）。OS 非依存の唯一の実装。 |
| `common.nix` | 共通ベース。`functions/*.sh` を読み込む。 |
| `darwin.nix` | **Mac (nix-darwin) 用**エントリポイント。`common.nix` を読み込む。 |
| `nixos.nix` | **NixOS 用**エントリポイント。`common.nix` + Linux 固有差分（ssh-agent）。 |

シェル関数の実装は 1 箇所（`functions/`）に集約し、2 つの OS 向けエントリポイントが
同じ実装を読み込む。これにより Mac と NixOS で関数の二重管理を避ける。

## 関数

| ファイル | 主な関数 |
|---|---|
| `functions/aiagent.sh` | `issue` `issue-abort` `issue-finish` `issue-status`（Claude Code 用 Issue 駆動） |
| `functions/menu.sh` | `_pick` `_confirm`（選択 UI と y/N 確認の共通実装） |
| `functions/os.sh` | `_is_darwin` `_sed_i` `_open` `_linux_only`（OS 差を吸収するシム） |

実行者の変更のレビューは、実行者のセッションの中で `pr-workflow` が [crit](https://github.com/tomasz-tomczyk/crit) を開いて済ませる（`home-manager/modules/crit.nix`）。

`functions/` は稼働環境の実装を汎用化したスナップショットであり、稼働側に追従させない。ワークフローの振る舞いの正は [new-issue](../../../.claude/skills/new-issue/SKILL.md) にある。

### 公開範囲

稼働環境のシェル関数は、Issue 駆動のほかにも git の補助・ops・ドキュメント変換など多数のモジュールを持つ。ここに収めているのは**そのうち Issue 駆動ワークフローの実行に要る3本**だけである。稼働側は台帳として `issues/` のほかに Backlog.md も扱うが、公開側は `issues/` だけを扱う。

## 配線

| デバイス | import するエントリポイント |
|---|---|
| `devices/macbook` | `darwin.nix` |
| `devices/common`（Linux） | `nixos.nix` |
