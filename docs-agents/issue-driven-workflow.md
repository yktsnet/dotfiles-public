[🇯🇵 日本語](issue-driven-workflow.md) | [🇬🇧 English](issue-driven-workflow.en.md)

# Issue-Driven Development Workflow

AI Agent（Claude Code / Jules）を活用したIssue起点の開発フロー。  
設計・実装・検証を分離し、Agentの暴走を防ぎつつ高速に開発。

---

## フェーズ

各リポは **MVP期** か **Issueドリブン期** のいずれかにあり、user が決定してリポの CLAUDE.md に明記する（相談者はフェーズを判断・変更しない）。記載が無ければ Issueドリブン期をデフォルトとする。

- **MVP期**: 方向性・構造が固まっていない立ち上がり期。相談者が開放チャットで直接実装してよい。
- **Issueドリブン期**: 方向性が固まった段階。以下の「担当分離」に従う。

フェーズが不明・曖昧な場合は実装せず user に確認する。

## 担当分離（Issueドリブン期）

| 担当 | 作業 |
|---|---|
| **相談者**（WebChat / デスクトップ Code 開放チャット） | Issue設計・仕様議論・ドキュメント作成。**実装しない** |
| **実行者**（issue() 起動の CLI Code / Jules） | Issueに基づくコード編集・静的確認・git操作・PR作成 |
| **user** | デプロイ・サービス再起動・動作確認・マージ |

- 相談者は Issue ファイルの書き出しまで（`/new-issue` スキルを使う）。コードは書かず、書き終えたら止まる。
- 相談者を Code が演じる場合（`main`・開放チャット）も同じ。実装を頼まれたら Issue を `status: open` で作成して止まり、実装は user が issue() で起動する。
- 実行者は Issue に基づき実装し PR を作成。本番コマンド実行は禁止。
- 検証手順：実行者がPRの `## 検証手順` に記載。userが実施。

---

## 対応 Agent と特性

ZSH側で呼び出すAgent（Code / Jules）を選択。ガードは設定しない。  
Agentの実行環境の特性に応じ、ブランチ管理が異なる。

| Agent | 実行環境 | ブランチ管理 | 永続指示ファイル |
|---|---|---|---|
| **Claude Code (Code)** | ローカル環境 | worktree + ブランチを作成し隔離実行 | `CLAUDE.md` |
| **Jules** | クラウドサンドボックス | ローカルブランチ不生成（リモート完結） | `AGENTS.md` |

---

## プロジェクト構成

`issue-init` 実行時、選択したAgentに応じた永続指示ファイルと共通の管理ディレクトリをカレントリポジトリに生成。

```
{app_root}/
├── CLAUDE.md        # Claude Code用永続指示（静的チェック・検証手順の雛形を含む）
├── AGENTS.md        # Jules用永続指示
├── .claude/
│   └── settings.json        # 権限・事故防止（harness-guide.md）
├── context/         # 共通コンテキスト
│   ├── conventions.md
│   └── structure.md
└── issues/          # ローカルIssue管理
    ├── 00_template.md
    └── {NN}_{slug}.md
```

`pr-workflow`（実行者用）と `new-issue`（相談者用）のスキルはリポごとに持たず、グローバル `~/.claude/skills/`（dotfiles 管理）を使う。リポ固有の検証手段・検証手順は各リポの CLAUDE.md に書き、スキルがそれを参照する。

---

## Issue フォーマット

```markdown
## {タイトル}
id: {00}
branch-slug: {slug}
github_issue:
status: draft | open | close
type: cleanup | fix | feat
対象: {変更・新規作成するファイルをすべて列挙。新規は (新規) を付記}
内容: {目的と概要のみ}
確認: {AI Agent が提出前に行う静的確認}

---

{内容に収まらない仕様を自由に展開}
```

### ライフサイクル

```
draft  →（設計完了）→  open  →（issue-finish）→  close
```

- `draft`: 設計中。`issue()` の選択肢から除外。
- `open`: 実装可能。`issue()` で選択可能。実行者は `status:` を変更しない。
- `close`: 完了済み。`issue-finish` が更新する。

### 派生 Issue

検証で問題が発生した場合、元のIssueを `close` し、`{id}a` などの派生Issueを新規作成。

元のIssueを再open、または同一Agentセッションへの追記プロンプト送信は禁止。記録保持のため常にIssueファイルを起点とする。

### 情報セキュリティ

- Issue / PR・コミットメッセージ・コメントなど**人間が読む説明文に固有の接続情報を直書きしない**。代わりに `~/dotfiles/secrets-agents/` の辞書で定義された `<PLACEHOLDER>` を用いる。
- 伏せる対象：ドメイン実値・公開ポート・Tunnel UUID・cloudflared パス・本番絶対パス・Tailscale IP / SSH ユーザ名・WiFi SSID・アプリ固有情報（口座 / 戦略名等）。デバイス名（`sv6` 等）・localhost・開発ポート・リポジトリ相対パス・LocalStack のリソース名は伏せない。
- 辞書ファイル：`network.md` / `paths.md` / `cloud.md` / `apps.md`（規約は `secrets-agents/README.md`）。`secrets-agents/` 自体は公開しない。
- ローカルに無い値（口座関係等）をアプリへ入力する場合は、該当辞書 MD に随時追記する。

---

## シェル関数

### `issue-init` or `jules-init`

カレントディレクトリ（単一リポジトリ）の開発環境を初期化。

1. ZSH側でAgent（Code / Jules）を選択。
2. 共通コンテキスト（`context/`）およびローカルIssue管理（`issues/`）を生成。
3. 選択したAgentに応じ、`CLAUDE.md` または `AGENTS.md` を生成。

### `issue` or `jules`

対象Issueを選択し、Agentを起動。Issueの管理はローカルファイル（`issues/`）が唯一の真実。GitHub Issue は記録用ミラーで、`issue-finish` が完了時に「作成→即クローズ」で残す。

1. `status: open` のIssueを `fzf` で選択（プレビュー表示）。
2. issues/ の変更を `main` へコミットして Push（worktree ブランチに issue を含め、PR の diff に issues/ が混ざらないようにするため）。
3. Agentごとの分岐：
   - **Code**: worktree `{repo}.wt/{id}-{slug}` をブランチ `claude/{id}-{slug}` で作成し、その中で `claude` コマンドを起動。main のチェックアウトは汚れず、複数Issueの並列実行が可能。stash は不要（worktree は HEAD から切られるため、未コミット変更は持ち込まれない）。
   - **Jules**: ローカルブランチは作らず、`jules new` でIssue内容を直接クラウドセッションへ投入。

GitHub には触れない（記録用 Issue は `issue-finish` が作成する）。

### `issue-abort` or `jules-abort`

進行中のタスクを中断し、変更を破棄。

1. Agentごとの分岐：
   - **Code**: `claude/*` の worktree を `fzf` で選択し、worktree とブランチを強制削除（`git worktree remove --force` + `git branch -D`）。
   - **Jules**: ローカルブランチ操作をスキップ。クラウド側のセッション管理（`jules remote` 等）で手動対応。

### `issue-finish` or `jules-finish`

PRマージ、ブランチ後片付け、Issueクローズを一括実行。

1. オープンなPRを一覧表示、PR番号を入力。
2. `gh pr merge {番号} --merge` を実行。
3. `git pull --prune` を実行（main のチェックアウトは常に main のまま）。
4. Agentごとの分岐：
   - **Code**: マージ済み `claude/*` の worktree・ローカル・リモートブランチを一括削除。
   - **Jules**: ローカルブランチが存在しないため、ブランチ削除処理をスキップ。
5. 記録用 GitHub Issue を作成して即クローズ（`github_issue:` に番号が既にあればクローズのみ）。作成失敗はフローを止めない。
6. ローカルIssueファイルを `status: close` に更新し、`main` へコミット・Push。
