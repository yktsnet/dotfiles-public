[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Nix-Powered Workspace for AI-Agent Collaborative Development

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

AIコーディングエージェント（Claude Code / Jules）と人間がロール（役割）を分離して協調開発を行うための、Issue駆動型（Issue-Driven）宣言的開発ワークスペース。
Nix Flakes と Home Manager により macOS / Linux 間の環境差を排除し、エージェントが常に同一のツールチェーンで動作する基盤を提供する。

---

## Philosophy & Core Architecture

AIエージェントの自律的な編集能力を最大限に活かしつつ、人間の設計意図から逸脱したコード生成（エージェントの暴走）を防ぐため、「設計・実装・検証」を分離したIssue駆動型開発フローを採用。

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

### 3. 機密情報・インフラ設定の分離 (Secrets & Configs Isolation)
公開リポジトリ側のコードやIssueファイルに、本番環境のIPやポート番号、実ホスト名などの具体的な機密情報（シークレット）を直接記述しないよう、ローカルの `secrets-agents/` ディレクトリに設計値を隔離してエージェントに参照させる。

---

## Agent Profiles & Branch Management

起動するAIエージェントの実行環境の特性に応じて、ブランチ管理と指示ファイルを最適化。詳しいワークフローの挙動は [docs-agents/issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) を参照。

| エージェント | 実行環境 | ブランチ管理 | 永続指示ファイル |
|---|---|---|---|
| **Claude Code** | ローカルマシン環境 | ローカルブランチを自動生成・操作 | `CLAUDE.md` |
| **Jules** | クラウド上のサンドボックス | ローカルブランチは生成せずリモート完結 | `AGENTS.md` |

---

## Project Structure

`issue-init`（または `jules-init`）の実行により、**対象の開発リポジトリ**に以下の共通ディレクトリ構造および選択したエージェントに対応する指示ファイルを生成する（本リポジトリ自体の構造ではない）。

```text
{対象リポジトリ}/
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
* **`skill`** (Claude Code Skill ランチャー):
  `.claude/skills/` 内の手動実行用スキル（SKILL.md の frontmatter に `manual: true` を持つもの）を `fzf` で一覧・プレビューし、選択したスキルを `claude /{skill-name}` で起動。

---

## TUI Toolchain & Development Environment

エージェントと人間が同一環境で作業を行うための、Nixで一元化されたTUI（Text User Interface）環境。

* **Neovim (IDE & Editor)**: `lazy.nvim` をベースにした高度にモジュール化された統合開発環境。LSPによる自動補完や静的型チェック、自動コード整形（conform.nvim）、Yaziとのシームレスな統合のほか、Oil.nvimによるバッファ型ファイル操作、フローティングターミナル（ToggleTerm）、そして自動セッション復元などを備え、開発効率を最大化。
* **Yazi (Terminal File Manager)**: Rust製の超高速ファイラー。fzf/ripgrep連携による高速検索や、終了時にシェルのカレントディレクトリを同期するラッパー関数を搭載。
* **Tmux (Terminal Multiplexer)**: プレフィックスキー不要のペイン切り替え・分割、OSC 52による透過的なクリップボード同期、True Color対応など、リモート・ローカルの差異を埋める設定。Neovimの分割ウィンドウと同一のショートカット（Alt + 矢印、Alt + /、Alt + -、Alt + x）でシームレスに操作可能。

詳細なキーバインドや構成については、[TUI Environment (docs/tui_environment.md)](docs/tui_environment.md) を参照してください。

---

## Agent Development Guides

新規リポで AI Agent 協調開発を始めるためのガイド群。5ファイルをセットで AI に渡し、標準的な開発環境を構築する。

| ガイド | 役割 |
|---|---|
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | プロセス層。Issue 起点の開発フロー・担当分離・シェル関数 |
| [harness-guide.md](docs-agents/harness-guide.md) | ハーネス層。`.claude/` 構成・settings.json・指示ファイル・検証手段 |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD 層。GitHub Actions・自動デプロイ・Cloudflare Tunnel |
| [readme-guide.md](docs-agents/readme-guide.md) | README の書き方。構成・言語規則・JUDGE.md 統合 |
| [repo-guide.md](docs-agents/repo-guide.md) | リポジトリ構成・機密管理・公開前チェックリスト |

