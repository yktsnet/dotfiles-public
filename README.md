[🇯🇵 日本語](README.md) | [🇬🇧 English](README.en.md)

# AI-Agent Development Environment as Code

[![CI](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml/badge.svg)](https://github.com/yktsnet/dotfiles-public/actions/workflows/ci.yml)

AI エージェントとの開発では、ボトルネックは生成から検証と意図伝達に移る。
本リポジトリは、その前提で組んだ個人の開発環境を、Nix 構成・ロール分離の実行機構・skill 群ごとコードとして公開する。
開発の型は、チームのリポジトリへ取り込める形に切り出して [sdlc-kit](https://github.com/yktsnet/sdlc-kit) で配っている。ここはその型を実際に回している環境である。

---

## Development Lifecycle（2つの駆動文書）

開発を2フェーズに分け、駆動文書を交代させる。立ち上げ期は PLAN.md / JUDGE.md（SDD）、リリース後は保証台帳 `docs/guarantees.md` とテスト（GDD）で回す。フェーズは各リポジトリの CLAUDE.md で宣言する。

考え方は sdlc-kit の [docs/lifecycle.md](https://github.com/yktsnet/sdlc-kit/blob/main/docs/lifecycle.md) にある。本リポジトリでの運用基準は [test-policy.md](docs-agents/test-policy.md) を参照。

---

## Role Separation（ロールの分離）

上記2ワークフローの実行機構。人間、対話型AI、自律型AIエージェントの担当範囲を厳格に定義し、エージェントの編集がレビューを経ないままメインブランチや本番に及ばないようにする。

* **WebChat（設計・対話型AI）**:
  ユーザーと対話しながら、MVP期は仕様策定と設計ファイルの作成を、Issueドリブン期は調査と Issue 設計を行う。実装はしない。
* **AI Agent（実装・自律型AI）**:
  Issue ファイルをインプットとしてコード編集・テスト実装・静的エラー確認・ローカルコミットまでを自律実行し、リモートには触れない。手順は [pr-workflow](.claude/skills/pr-workflow/SKILL.md) に固定してある。`rebuild` 等の破壊的コマンドや機密へのアクセスは `.claude/settings.json` の deny で遮断し、前方一致では判定できないもの（パス付き実行のパッケージ導入、生成物への直接編集）は [`.claude/hooks/`](.claude/hooks/) の PreToolUse フックが受け持つ。
* **User（裁可・検証・人間）**:
  Issue の保証節を裁可し、エージェントのコミットをローカルでレビュー・動作確認し、`issue-finish` で公開（push・PR作成・マージ）を実行する。レビューを通った変更だけがリモートに残る。

ロール間の受け渡しは Zsh マクロで行う:

* **`issue`**: 対象 Issue を選択し、worktree を隔離作成してエージェントを起動。main を汚さず複数 Issue を並列実行できる。
* **`issue-abort`**: 進行中の worktree を作業ブランチごと破棄。
* **`issue-finish`**: レビュー済みブランチの push → PR 作成 → マージ → 後片付けを一括実行。

分離を硬直させないための例外も定義している。障害対応などのリアルタイム ops、user が明示宣言する単発例外、そしてロジックに触れない小規模変更を Issue 化なしで通す軽量経路の3経路である。

このロール分離は1本の Issue の流れを説明したものであり、実際には複数の worktree と相談者セッションが同時に走る。同じモデル・同じ規則で動くセッションは、自分が方向を外したことを自分では検出できない。外部の読み手を用意するのが `M-m`（[session-nudge](.claude/skills/session-nudge/SKILL.md)）で、送信は cross-session messaging で行うが、文案は必ず user が承認してから送る。自動で他セッションへ介入はしない。

詳細は [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) を参照。

---

## Foundation（自律実行の前提条件）

エージェントの自律実行は、環境・機密・知識の3点を構造的に整えてはじめて成立する。

* **Nix による環境同一性**: 環境差はエージェントの「コマンド未検出」「実行時エラー」を招く。Nix Flakes と Home Manager で macOS / Linux のツールチェーンをコードとして同一化し、CI（`nix flake check`）で継続検証する。導入経路の逸脱（`brew` / `npm -g` / `pip install`）は `.claude/hooks/block-non-nix-install.sh` が遮断する。
* **機密情報の分離**: 公開リポジトリ側のコードや Issue ファイルに本番の IP・ポート・実ホスト名を書かない。実値はローカルの `secrets-agents/` に隔離し、地の文では `<PLACEHOLDER>` を用いる。辞書は平文でローカルに置くのではなく暗号化して git 経由で配り、各デバイスが自分の鍵で復号する。1台にしか無いと、別のデバイスでは何を伏せるべきか分からないまま書くことになるため。
* **暗黙知の skill 化**: 「どのファイルをいつ AI に渡すか」が人間の暗黙知に依存すると、AI 単独で運用を再現できない。「〜するとき」と条件を言える手順は skill 化し、description に起動条件を宣言する。前節のワークフロー自体（`new-issue`・`guarantee-audit` 等）もこの形でコミットされている。詳細は [harness-guide.md](docs-agents/harness-guide.md#知識の配置基準) を参照。
* **規則の棚卸し**: CLAUDE.md も skill も memory も「人が書いた規則を AI が読む」構造であり、規則同士の矛盾を検出する仕組みを持たない。増え続ける規則を放置すると挙動が不安定になるため、[`consolidate-rules`](.claude/skills/consolidate-rules/SKILL.md) が索引 `.claude/RULES.md` を起点に差分だけを定期監査する。永続メモリは索引を持たせず、`~/memory/` 直下に1ファイル1事実で置く（`ls` が索引になる粒度に保つ）。

---

## Devices（管理対象）

単一の Flake が macOS と Linux の開発機を束ねる。デバイス名は公開にあたり役割ベースの総称に置き換えている。

| 構成 | OS | 役割 |
|---|---|---|
| `gui/linux-desktop` | NixOS（disko / SSD） | 主開発機。相談者チャットと `issue()` の起動元 |
| `gui/macbook` | macOS（nix-darwin） | home-manager 層を Linux 機と共有する |

OS の差は、Nix 側では `pkgs.stdenv.isDarwin`、シェル側では `zsh/functions/os.sh` のシム（`_is_darwin` / `_sed_i` / `_open` / `_linux_only`）に閉じ込める。home-manager モジュールと関数ファイルは両 OS が同一のものを読む。

公開しているのは、エージェントとの開発に関わる層（Claude Code・メモリ・機密・レビュー・tmux のセッション管理）に限る。エディタやデスクトップの設定、サーバー類の構成は含めていない。

---

## Agent Development Guides

新規リポで AI Agent 協調開発を始めるためのガイド群。`docs-agents/` の9ファイルは、リポごとに答えが変わる**判断層**と、一度決めれば機械的に適用できる**定型層**に分かれ、その上にどちらの前提でもある**原理層**が1本ある。多数のリポを並行して立ち上げる運用では、判断層に払うコストがスループットを左右する。判断層は `repo-readme` / `module-dev` Skill が、定型層は `repo-standardize` / `guarantee-audit` Skill が読む。

### 原理層

| ガイド | 役割 |
|---|---|
| [principles.md](docs-agents/principles.md) | 導入順序と、各段の本質・機構・完了条件。各ガイドが何を前提に書かれているか |

### 判断層

| ガイド | 役割 |
|---|---|
| [module-guide.md](docs-agents/module-guide.md) | OSS モジュール型リポの設計規範。型の判断・構造・デモ方式 |
| [readme-guide.md](docs-agents/readme-guide.md) | README の書き方。構成・言語規則・JUDGE.md 統合 |
| [diagram-guide.md](docs-agents/diagram-guide.md) | 図を描くかの判断・幅の制約・形と線種・抽象度 |

### 定型層

| ガイド | 役割 |
|---|---|
| [repo-guide.md](docs-agents/repo-guide.md) | リポジトリ構成・機密管理・公開前チェックリスト |
| [issue-driven-workflow.md](docs-agents/issue-driven-workflow.md) | プロセス層。Issue 起点の開発フロー・担当分離・シェル関数 |
| [harness-guide.md](docs-agents/harness-guide.md) | ハーネス層。`.claude/` 構成・settings.json・指示ファイル・検証手段 |
| [cicd-guide.md](docs-agents/cicd-guide.md) | CI/CD 層。GitHub Actions・Cloudflare（Pages / Workers）への自動デプロイ・Dependabot |
| [test-policy.md](docs-agents/test-policy.md) | テスト層。保証の裁可・保証台帳・テストの濃淡 |
