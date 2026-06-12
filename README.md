# Nix-Powered Workspace for AI-Agent Collaborative Development

macOS と Linux 間で開発環境の差異を排除し、AIコーディングエージェント（Claude Code / Jules）と人間がロール（役割）を分離して協調開発を行うための、Issue駆動型（Issue-Driven）宣言的開発ワークスペース。

---

## Philosophy & Core Architecture

AIエージェントの自律的な編集能力を最大限に活かしつつ、人間の設計意図から逸脱したコード生成（エージェントの暴走）を防ぐため、「設計・実装・検証」を分離したIssue駆動型開発フローを採用。

```
[ WebChat (設計) ] ──> [ Markdown Issue (要件定義) ] ──> [ AI Agent (実装) ] ──> [ User (検証・マージ) ]
```

### 1. ロールの分離 (Role Separation)
人間、対話型AI、自律型AIエージェントの各強みに応じて担当範囲を厳格に定義。

* **WebChat (設計・対話型AI)**:
  ユーザーと対話しながら仕様策定および設計ファイルの作成を行う。検証手順は記述しない。
* **AI Agent (実装・自律型AI)**:
  作成されたIssueファイルをインプットとしてコード編集、静的エラー確認、PR作成までを自律実行。本番環境での破壊的なコマンド実行は禁止。
* **User (検証・人間)**:
  エージェントが作成したPRの検証手順に従い、動作確認とメインブランチへのマージを担当。

### 2. 環境差を排除しエージェントを支える Nix の役割
自律型エージェントにコード作成やテスト実行を任せるためには、動作させるローカルマシンの状態依存（環境差）を排除することが不可欠。
本リポジトリでは Nix Flakes および Home Manager をベースのインフラとして採用。MacBook（macOS）と Linux デスクトップにわたり、エージェントが利用するツールチェーン（Neovim, Yazi, Git, LSP等）や実行バイナリ、環境変数をコードとして完全に同一化。これにより、環境の差異によるエージェントの「コマンド未検出」「実行時エラー」を防止し、異なるOS間でのシームレスなAI協調開発の基盤を担保。

---

## Agent Profiles & Branch Management

起動するAIエージェントの実行環境の特性に応じて、ブランチ管理と指示ファイルを最適化。詳しいワークフローの挙動は [docs/issue_driven_workflow.md](docs/issue_driven_workflow.md) を参照。

| エージェント | 実行環境 | ブランチ管理 | 永続指示ファイル |
|---|---|---|---|
| **Claude Code (Code)** | ローカルマシン環境 | ローカルブランチを自動生成・操作 | `CLAUDE.md` |
| **Jules** | クラウド上のサンドボックス | ローカルブランチは生成せずリモート完結 | `AGENTS.md` |

---

## Project Structure

`issue-init`（または `jules-init`）の実行により、リポジトリルートに共通のディレクトリ構造および選択したエージェントに対応する指示ファイルを生成。

```text
{app_root}/
├── CLAUDE.md        # Claude Code用のシステム指示ファイル
├── AGENTS.md        # Jules用のシステム指示ファイル
├── context/         # 共通のコーディングルールや構成ドキュメント
│   ├── conventions.md
│   └── structure.md
└── issues/          # 開発タスク（Issue）ファイル群
    ├── 00_template.md  # 2桁の連番ID、branch-slug、対象ファイル等を定義するテンプレート
    └── {NN}_{slug}.md  # 設計されたタスクファイル
```

---

## Core Workflows (Zsh Functions)

Zshに統合された以下のシェルマクロ群により、チケット管理からエージェント起動、マージ後の後片付けまでをキーボード駆動でシームレスに処理。

* **`issue-init` / `jules-init`** (環境初期化):
  開発リポジトリをAI協調開発用に初期化。共通コンテキストディレクトリの生成、および対象エージェント用の指示ファイル（`CLAUDE.md` / `AGENTS.md`）を自動配備。
* **`issue` / `jules`** (チケット起動):
  `status: open` 状態のIssueファイルを `fzf` でプレビューしながら選択。
  * **Codeの場合**: 自動で専用ローカルブランチ `claude/{id}-{slug}` を作成・チェックアウトし、Claude CLI を起動。
  * **Julesの場合**: ローカルブランチは作らず、直接クラウド上のセッションへタスクを投入。
* **`issue-abort` / `jules-abort`** (開発中断):
  現在進行中のエージェントタスクを中断し、編集途中の状態をクリアしてメインブランチへ安全に復帰。
* **`issue-finish` / `jules-finish`** (PRマージとクローズ):
  作成されたPRを `gh` で検索・選択し、自動的にメインブランチへマージ。ローカルおよびリモートの作業ブランチをクリーンアップし、対象のローカルIssueファイルを `status: close` に書き換え、メインブランチへ自動的にプッシュ。

---

## TUI Toolchain & Development Environment

エージェントと人間が同一環境で作業を行うための、Nixで一元化されたTUI（Text User Interface）環境。

### 1. Neovim (IDE & Editor)
`lazy.nvim` プラグインマネージャをベースに構築された高度にモジュール化された設定。
* **LSP & Autocompletion**: 自動補完（cmp-nvim-lsp）および主要LSPがインストールされ、静的型チェックが動作。
* **Formatting**: `conform.nvim` により、保存時に自動整形が走りコードの品質を担保。
* **Theme**: `Poimandres` テーマを採用し、視認性と美しさを両立。
* **File Management**: `yazi.nvim` 統合により、エディタ内からファイラーへのシームレスな移行を実現。

### 2. Yazi (Terminal File Manager)
Ranger から移行し、Rust製ファイラー `Yazi` を採用。
* **Declartive Config**: キーバインド、テーマ（Poimandres）、およびプラグインをHome Manager側で宣言的に管理。
* **Fast Navigation**: パス移動とファイル選択が超高速化。ディレクトリ終了時のカレントディレクトリ同期（Zshラッパー関数 `y`）を搭載。

### 3. Tmux (Terminal Multiplexer)
セッションとペインの効率的な管理。
* **Clipboard Sync (OSC 52)**: SSHやコンテナ等のリモート・ローカル環境の差分を解消し、クリップボード同期を透過的に実現。
* **Vi-Style Copy Mode**: コピーモード内での vi-style キーバインド（v, y）および pbcopy / wl-copy とのシームレスな同期。
* **Aesthetics**: Poimandres カラーパレットに基づき、ウィンドウタブやペインボーダーのスタイルを構築。Alt + 矢印キーでの高速ペイン切り替えに対応。

---

## Tech Stack
* **System & Environment:** NixOS, nix-darwin, Nix Flakes, Home Manager
* **AI Orchestration & API:** Claude Code CLI, GitHub CLI (`gh`)
* **Terminal & Editor:** Zsh, Yazi (TUI File Manager), Neovim, Tmux
* **Languages & Automation:** Python 3.12, Zsh Script
