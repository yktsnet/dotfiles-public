[🇯🇵 日本語](issue-driven-workflow.md) | [🇬🇧 English](issue-driven-workflow.en.md)

# Issue-Driven Development Workflow

AI Agent（Claude Code / Jules）を活用したIssue起点の開発フロー。  
設計・実装・検証を分離し、Agentの暴走を防ぎつつ高速に開発。

---

## 担当分離

| 担当 | 作業 |
|---|---|
| **WebChat** | Issue設計・仕様議論・ドキュメント作成 |
| **AI Agent** | コード編集・静的確認・git操作・PR作成 |
| **user** | デプロイ・サービス再起動・動作確認・マージ |

- WebChatの責務：Issueファイルの書き出しまで。検証手順は記述しない。
- AI Agentの責務：Issueに基づく実装、PR作成。本番環境でのコマンド実行は禁止。
- 検証手順：AI AgentがPRの `## 検証手順` に記載。userが実施。

---

## 対応 Agent と特性

ZSH側で呼び出すAgent（Code / Jules）を選択。ガードは設定しない。  
Agentの実行環境の特性に応じ、ブランチ管理が異なる。

| Agent | 実行環境 | ブランチ管理 | 永続指示ファイル |
|---|---|---|---|
| **Claude Code (Code)** | ローカル環境 | ローカルブランチを作成・操作 | `CLAUDE.md` |
| **Jules** | クラウドサンドボックス | ローカルブランチ不生成（リモート完結） | `AGENTS.md` |

---

## プロジェクト構成

`issue-init` 実行時、選択したAgentに応じた永続指示ファイルと共通の管理ディレクトリをカレントリポジトリに生成。

```
{app_root}/
├── CLAUDE.md        # Claude Code用永続指示
├── AGENTS.md        # Jules用永続指示
├── .claude/
│   ├── settings.json        # 権限・事故防止（harness-guide.md）
│   └── skills/
│       └── pr-workflow/SKILL.md
├── context/         # 共通コンテキスト
│   ├── conventions.md
│   └── structure.md
└── issues/          # ローカルIssue管理
    ├── 00_template.md
    └── {NN}_{slug}.md
```

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
- `open`: 実装可能。`issue()` で選択可能。
- `close`: 完了済み。

### 派生 Issue

検証で問題が発生した場合、元のIssueを `close` し、`{id}a` などの派生Issueを新規作成。

元のIssueを再open、または同一Agentセッションへの追記プロンプト送信は禁止。記録保持のため常にIssueファイルを起点とする。

### 情報セキュリティ

- 公開リポジトリでは、本番環境のIP、固有ポート、実ホスト名（例：`production-server`）などの具体的な接続情報はIssueファイルに直接記述せず、`~/dotfiles/secrets-agents/` のファイルを参照するよう記述する。

---

## シェル関数

実装は [`zsh/functions/`](../zsh/functions/) に集約し、Mac は `zsh/darwin.nix`、x86 / NixOS は
`zsh/nixos.nix` から読み込む（構成は [`zsh/README.md`](../zsh/README.md)）。

### `issue-init` or `jules-init`

カレントディレクトリ（単一リポジトリ）の開発環境を初期化。

1. ZSH側でAgent（Code / Jules）を選択。
2. 共通コンテキスト（`context/`）およびローカルIssue管理（`issues/`）を生成。
3. 選択したAgentに応じ、`CLAUDE.md` または `AGENTS.md` を生成。

### `issue` or `jules`

対象Issueを選択し、ローカルとリモートを同期したうえでAgentを起動。Issueはローカルファイル（`issues/`）と GitHub Issue の両方で管理する。

1. `status: open` のIssueを `fzf` で選択（プレビュー表示）。
2. 未コミット変更がある場合、`git stash` を確認。Issueファイルの更新は `main` へコミット。
3. リモートと同期（`git pull --rebase`、必要なら `push`）。
4. `github_issue:` が空なら GitHub Issue を自動作成し、付与された番号をIssueファイルへ書き戻してコミット・Push（紐付け済みならスキップ）。
5. Agentごとの分岐：
   - **Code**: ローカルブランチ `{agent}/{id}-{slug}` を作成・チェックアウト。`claude` コマンドでタスク投入。
   - **Jules**: ローカルブランチは作らず、`jules new` でIssue内容を直接クラウドセッションへ投入。

### `issue-abort` or `jules-abort`

進行中のタスクを中断し、変更を破棄。

1. Agentごとの分岐：
   - **Code**: 現在の `{agent}/*` ブランチを確認。`git stash` 後、`main` に切り替え、当該ローカルブランチを強制削除（`git branch -D`）。
   - **Jules**: ローカルブランチ操作をスキップ。クラウド側のセッション管理（`jules remote` 等）で手動対応。

### `issue-finish` or `jules-finish`

PRマージ、ブランチ後片付け、Issueクローズを一括実行。

1. オープンなPRを一覧表示、PR番号を入力。
2. `gh pr merge {番号} --merge` を実行。
3. `git checkout main && git pull --prune` を実行。
4. Agentごとの分岐：
   - **Code**: マージ済みのローカル・リモートブランチ（`claude/*`）を一括削除。
   - **Jules**: ローカルブランチが存在しないため、ブランチ削除処理をスキップ。
5. 対象Issueに紐付く GitHub Issue を `gh issue close` でクローズ。
6. ローカルIssueファイルを `status: close` に更新し、`main` へコミット・Push。
