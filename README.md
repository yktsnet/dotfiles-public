[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Nix-Powered Workspace for AI-Agent Collaborative Development

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

環境差はエージェントの自律実行を妨げる。エージェントは人間の確認を挟まず実行するため、破壊的な操作や機密の漏洩をそのまま通しかねない。
前者は Nix Flakes で macOS / Linux のツールチェーンを宣言的に統一して解消する。後者は Issue駆動のロール分離と、機密の隔離・操作の制限で抑える。

---

## Philosophy & Core Architecture

AIエージェントの自律的な編集能力を活かしつつ、その実行が人間の確認を経ないままメインブランチや本番に及ばないよう、「設計・実装・検証」を分離したIssue駆動型開発フローを採用。

### 1. ロールの分離 (Role Separation)
人間、対話型AI、自律型AIエージェントの各強みに応じて担当範囲を厳格に定義。

* **WebChat (設計・対話型AI)**:
  ユーザーと対話しながら仕様策定および設計ファイルの作成を行う。検証手順は記述しない。
* **AI Agent (実装・自律型AI)**:
  作成されたIssueファイルをインプットとしてコード編集、静的エラー確認、ローカルコミットまでを自律実行し、リモートには触れない。`rebuild` 等の破壊的コマンドや機密へのアクセスは `.claude/settings.json` の deny で構造的に遮断する。
* **User (検証・人間)**:
  エージェントのコミットをローカルでレビュー・動作確認し、`issue-finish` で公開（push・PR作成・マージ）を実行。レビューを通った変更だけがリモートに残る。

### 2. 環境差を排除しエージェントを支える Nix の役割
自律型エージェントにコード作成やテスト実行を任せるためには、動作させるローカルマシンの状態依存（環境差）を排除することが不可欠。
本リポジトリでは Nix Flakes および Home Manager をベースのインフラとして採用。MacBook（macOS）と Linux デスクトップにわたり、エージェントが利用するツールチェーン（Neovim, Yazi, Git, LSP等）や実行バイナリ、環境変数をコードとして同一化する。これにより、環境の差異によるエージェントの「コマンド未検出」「実行時エラー」を防ぐ。この同一性は CI（`nix flake check`）で継続的に検証している。

### 3. 機密情報・インフラ設定の分離 (Secrets & Configs Isolation)
公開リポジトリ側のコードやIssueファイルに、本番環境のIPやポート番号、実ホスト名などの具体的な機密情報（シークレット）を直接記述しないよう、ローカルの `secrets-agents/` ディレクトリに設計値を隔離してエージェントに参照させる。

### 4. 暗黙知の宣言化 (Making Tacit Knowledge Explicit)
運用知識が「どのファイルをいつ AI に渡すか」という人間の暗黙知に依存すると、対応できる人間が固定化し、AI 単独では運用を再現できなくなる。本リポジトリでは知識の置き場を読み込みの契機で決め、「〜するとき」と条件を言える手順は skill 化し、description に起動条件を宣言する。これにより人間による手渡しが不要になり、暗黙知がコミットされる規範に変わる。詳細は [harness-guide.md](docs-agents/harness-guide.md#知識の配置基準) を参照。

### 5. 保証の裁可 (Tests as Approved Guarantees)
エージェントがコードを書く開発では、ボトルネックは生成ではなく検証に移る。テストを「何が壊れてはいけないか」という人間の意図をエージェントに執行させる契約として扱い、保証の宣言（何が成り立つべきか）は user が Issue の保証節で裁可し、テストコードの実装はエージェントが書く、と分業する。仕様書は望む振る舞いを書くが強制力を持たず、実装は意図しない振る舞いを含む。テストと保証台帳（`docs/guarantees.md`）はその交差のうち約束すると決めた部分であり、破れば落ちることで人間の常時監視を不要にする。詳細は [test-policy.md](docs-agents/test-policy.md) を参照。

---

## Agent Profiles & Branch Management

起動するAIエージェントの実行環境の特性に応じて、ブランチ管理と指示ファイルを最適化。詳しいワークフローの挙動は [docs-agents/issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) を参照。

| エージェント | 実行環境 | ブランチ管理 | 永続指示ファイル |
|---|---|---|---|
| **Claude Code** | ローカルマシン環境 | worktree + ブランチを自動生成し隔離実行 | `CLAUDE.md` |

---

## Core Workflows (Zsh Functions)

Zshに統合された以下のシェルマクロ群により、チケット管理からエージェント起動、マージ後の後片付けまでをキーボード駆動でシームレスに処理。

* **`issue`** (チケット起動):
  `status: open` 状態のIssueファイルを `fzf` でプレビューしながら選択。
  worktree `{repo}.wt/{id}-{slug}` をブランチ `claude/{id}-{slug}` で自動作成し、その中で Claude CLI を起動。main のチェックアウトは汚れず、複数Issueを並列実行できる。
* **`issue-abort`** (開発中断):
  進行中の `claude/*` worktree を `fzf` で選択し、worktree と作業ブランチごと破棄。main のチェックアウトには影響しない。
* **`issue-finish`** (レビュー済みブランチの公開とクローズ):
  `main` 未マージの `claude/*` ブランチを `fzf` で選択し、push → PR作成（本文はコミットメッセージ本文から生成）→ メインブランチへのマージまでを一括実行。マージ済みの worktree・ローカル/リモートブランチをクリーンアップし、記録用の GitHub Issue を「作成→即クローズ」で残したうえで、対象のローカルIssueファイルを `status: close` に書き換え、メインブランチへプッシュ。
* **`skill`** (Claude Code Skill ランチャー):
  dotfiles の `.claude/skills/` 内の手動実行用スキル（SKILL.md の frontmatter に `manual: true` を持つもの）を `fzf` で一覧・プレビューし、選択したスキルを `claude /{skill-name}` で起動。
* **plugin marketplace** (外部配布):
  本リポは Claude Code の plugin marketplace としても利用可能。`/plugin marketplace add yktsnet/dotfiles-public` → `/plugin install public-skills` で、汎用性のある4 skill（readme-i18n, repo-about, jp-writing, jp-writing-code）のみを含む `public-skills` プラグインを導入できる（他の私的運用skillは含まれない）。

---

## TUI Toolchain & Development Environment

エージェントと人間が同一環境で作業を行うための、Nixで一元化されたTUI（Text User Interface）環境。

* **Neovim (IDE & Editor)**: `lazy.nvim` をベースにした高度にモジュール化された統合開発環境。LSPによる自動補完や静的型チェック、自動コード整形（conform.nvim）、Yaziとのシームレスな統合のほか、Oil.nvimによるバッファ型ファイル操作、フローティングターミナル（ToggleTerm）、そして自動セッション復元などを備え、開発効率を最大化。
* **Yazi (Terminal File Manager)**: Rust製の超高速ファイラー。fzf/ripgrep連携による高速検索や、終了時にシェルのカレントディレクトリを同期するラッパー関数を搭載。
* **Tmux (Terminal Multiplexer)**: プレフィックスキー不要のペイン切り替え・分割、OSC 52による透過的なクリップボード同期、True Color対応など、リモート・ローカルの差異を埋める設定。Neovimの分割ウィンドウと同一のショートカット（Alt + 矢印、Alt + /、Alt + -、Alt + x）でシームレスに操作可能。

詳細なキーバインドや構成については、[TUI Environment (docs/tui_environment.md)](docs/tui_environment.md) を参照してください。

---

## Agent Development Guides

新規リポで AI Agent 協調開発を始めるためのガイド群。7ファイルをセットで AI に渡し、標準的な開発環境を構築する。

| ガイド | 役割 |
|---|---|
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | プロセス層。Issue 起点の開発フロー・担当分離・シェル関数 |
| [harness-guide.md](docs-agents/harness-guide.md) | ハーネス層。`.claude/` 構成・settings.json・指示ファイル・検証手段 |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD 層。GitHub Actions・自動デプロイ・Cloudflare Tunnel |
| [readme-guide.md](docs-agents/readme-guide.md) | README の書き方。構成・言語規則・JUDGE.md 統合 |
| [repo-guide.md](docs-agents/repo-guide.md) | リポジトリ構成・機密管理・公開前チェックリスト |
| [module-guide.md](docs-agents/module-guide.md) | OSS モジュール型リポの設計規範。型の判断・構造・デモ方式 |
| [test-policy.md](docs-agents/test-policy.md) | テスト層。保証の裁可・保証台帳・テストの濃淡 |

