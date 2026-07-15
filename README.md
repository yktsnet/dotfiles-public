[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# Two-Phase Development Lifecycle for AI-Agent Collaboration

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

AI エージェントとの開発では、ボトルネックは生成から検証と意図伝達に移る。
本リポジトリは開発を2フェーズに分け、それぞれ異なる駆動文書で回す。立ち上げ期は仕様書（PLAN.md / JUDGE.md）が、保守期は保証台帳（guarantees.md）とテストが、人間の意図をエージェントに執行させる。
このライフサイクルを支える実行環境（Nix・ロール分離・skill 群）ごと、コードとして公開する。

---

## Development Lifecycle（2つの駆動文書）

開発文書には寿命がある。単一の仕様書を永続させようとせず、フェーズごとに駆動文書を交代させる。フェーズは各リポジトリの CLAUDE.md で宣言する。

| フェーズ | 駆動文書 | 手法 | 文書の運命 |
|---|---|---|---|
| MVP期（立ち上げ） | PLAN.md / JUDGE.md | Spec-Driven Development (SDD) | リリース時に README へ昇華し、廃棄 |
| Issueドリブン期（保守） | Issue の保証節 + `docs/guarantees.md` | Guarantee-Driven Development (GDD) | テストが継続検証する永続契約 |

### MVP期: Spec-Driven Development

方向性と構造が固まっていない立ち上げ期は、PLAN.md（仕様・計画・作業記録）と JUDGE.md（実装中の判断記録）が開発を駆動する。エージェントに両ファイルを更新させながら実装を進め、リリース時に README へ昇華して役目を終える。仕様書はこのフェーズ限りの足場であり、永続を求めない。

### Issueドリブン期: Guarantee-Driven Development

リリース後は、仕様書を書くほどではない修正が積み重なり、最初の仕様書は実装から乖離していく。そこで駆動文書を保証台帳（`docs/guarantees.md`）へ交代させる。台帳は「何を約束し、何を約束していないか」だけを記し、各約束は対応するテストが継続検証する。README と違い、破れば落ちるため黙って腐れない。挙動に違和感を覚えたとき最初に開くのはこの台帳である。

エージェントがコードを書く開発では、人間の仕事はテストを書くことから約束を裁可することへ移る。保証の宣言（何が成り立つべきか）は user が Issue の保証節で裁可し、テストコードの実装はエージェントが書く。テストそのものが正なのではなく、裁可された保証を実行可能な形に書き下ろしたものである。TDD がテストを先に書く規律だとすれば、GDD は約束の裁可を先に行う規律である。台帳とテストの乖離は `guarantee-audit` skill による棚卸しで検出する。詳細は [test-policy.md](docs-agents/test-policy.md) を参照。

---

## Role Separation（ロールの分離）

上記2ワークフローの実行機構。人間、対話型AI、自律型AIエージェントの担当範囲を厳格に定義し、エージェントの編集がレビューを経ないままメインブランチや本番に及ばないようにする。

* **WebChat（設計・対話型AI）**:
  ユーザーと対話しながら、MVP期は仕様策定と設計ファイルの作成を、Issueドリブン期は調査と Issue 設計を行う。実装はしない。
* **AI Agent（実装・自律型AI）**:
  Issue ファイルをインプットとしてコード編集・テスト実装・静的エラー確認・ローカルコミットまでを自律実行し、リモートには触れない。`rebuild` 等の破壊的コマンドや機密へのアクセスは `.claude/settings.json` の deny で構造的に遮断する。
* **User（裁可・検証・人間）**:
  Issue の保証節を裁可し、エージェントのコミットをローカルでレビュー・動作確認し、`issue-finish` で公開（push・PR作成・マージ）を実行する。レビューを通った変更だけがリモートに残る。

ロール間の受け渡しは Zsh マクロで行う:

* **`issue`**: `status: open` の Issue を `fzf` で選択し、worktree `{repo}.wt/{id}-{slug}` をブランチ `claude/{id}-{slug}` で自動作成して Claude CLI を起動。main を汚さず複数 Issue を並列実行できる。
* **`issue-abort`**: 進行中の `claude/*` worktree を選択し、作業ブランチごと破棄。
* **`issue-finish`**: レビュー済みブランチを選択し、push → PR 作成 → マージ → worktree・ブランチのクリーンアップ → Issue ファイルの `status: close` 化までを一括実行。
* **`skill`**: 手動実行用スキル（frontmatter に `manual: true`）を `fzf` で一覧・プレビューし、`claude /{skill-name}` で起動。

このリポジトリは Claude Code の plugin marketplace としても利用できる。`/plugin marketplace add yktsnet/dotfiles-public` → `/plugin install public-skills` で、汎用性のある4 skill（readme-i18n, repo-about, jp-writing, jp-writing-code）を導入できる。

---

## Foundation（自律実行の前提条件）

エージェントの自律実行は、環境・機密・知識の3点を構造的に整えてはじめて成立する。

* **Nix による環境同一性**: 環境差はエージェントの「コマンド未検出」「実行時エラー」を招く。Nix Flakes と Home Manager で macOS / Linux のツールチェーンをコードとして同一化し、CI（`nix flake check`）で継続検証する。
* **機密情報の分離**: 公開リポジトリ側のコードや Issue ファイルに本番の IP・ポート・実ホスト名を書かない。実値はローカルの `secrets-agents/` に隔離し、地の文では `<PLACEHOLDER>` を用いる。
* **暗黙知の skill 化**: 「どのファイルをいつ AI に渡すか」が人間の暗黙知に依存すると、AI 単独で運用を再現できない。「〜するとき」と条件を言える手順は skill 化し、description に起動条件を宣言する。前節のワークフロー自体（`new-issue`・`guarantee-audit` 等）もこの形でコミットされている。詳細は [harness-guide.md](docs-agents/harness-guide.md#知識の配置基準) を参照。

---

## TUI Toolchain & Development Environment

エージェントと人間が同一環境で作業を行うための、Nixで一元化されたTUI環境。

* **Neovim**: `lazy.nvim` ベースの統合開発環境。LSP 補完・静的型チェック・自動整形（conform.nvim）・Yazi 統合・自動セッション復元。
* **Yazi**: Rust製ファイラー。fzf/ripgrep 連携と、終了時にシェルのカレントディレクトリを同期するラッパー関数。
* **Tmux**: プレフィックスキー不要のペイン操作、OSC 52 クリップボード同期、True Color 対応。Neovim の分割ウィンドウと同一ショートカットで操作できる。

詳細なキーバインドや構成は [TUI Environment (docs/tui_environment.md)](docs/tui_environment.md) を参照。

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
