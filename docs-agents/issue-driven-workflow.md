[🇯🇵 日本語](issue-driven-workflow.md) | [🇬🇧 English](issue-driven-workflow.en.md)

# Issue-Driven Development Workflow

AI Agent（Claude Code）を活用したIssue起点の開発フロー。  
設計・実装・検証を分離し、Agentの暴走を防ぎつつ高速に開発。

---

## フェーズ

各リポは **MVP期** か **Issueドリブン期** のいずれかにあり、user が決定してリポの CLAUDE.md に明記する（相談者はフェーズを判断・変更しない）。記載が無ければ Issueドリブン期をデフォルトとする。

- **MVP期**: 方向性・構造が固まっていない立ち上がり期。相談者が開放チャットで直接実装してよい。
- **Issueドリブン期**: 方向性が固まった段階。以下の「担当分離」に従う。

フェーズが不明・曖昧な場合は実装せず user に確認する。

MVP期からIssueドリブン期への移行は、保証台帳（`docs/guarantees.md`）の正式運用化と同一イベントとして行う（`guarantee-audit` skill が敷設・格上げを担う）。

## 担当分離（Issueドリブン期）

| 担当 | 作業 |
|---|---|
| **相談者**（WebChat / デスクトップ Code 開放チャット） | Issue設計・仕様議論・ドキュメント作成。**実装しない** |
| **実行者**（issue() 起動の CLI Code） | Issueに基づくコード編集・静的確認・コミット |
| **user** | デプロイ・サービス再起動・動作確認・マージ・Issue保証節の裁可 |

- 相談者は Issue ファイルの書き出しまで（`/new-issue` スキルを使う）。コードは書かず、書き終えたら止まる。
- 相談者を Code が演じる場合（`main`・開放チャット）も同じ。実装を頼まれたら Issue を `status: draft` で作成して止まり、user が保証節を裁可して `status: open` に変えたのち issue() で起動する。
- 実行者（Code）は Issue に基づき実装し、ローカルコミットで止まる。push・PR 作成・本番コマンド実行は禁止。リモートへの公開は user のレビュー後に `issue-finish` が行う。

- 検証手順：実行者がコミットメッセージ本文の `## 検証手順` に記載（`issue-finish` がその本文をそのまま PR 本文にする）。userが実施。

---

## プロジェクト構成

各リポジトリは、選択したAgentに応じた永続指示ファイルと共通の管理ディレクトリを持つ。

```
{app_root}/
├── CLAUDE.md        # Claude Code用永続指示（静的チェック・検証手順の雛形を含む）
├── .claude/
│   └── settings.json        # 権限・事故防止（harness-guide.md）
├── context/         # 共通コンテキスト
│   ├── conventions.md
│   └── structure.md
└── issues/          # ローカルIssue管理
    └── {NN}_{slug}.md
```

`pr-workflow`（実行者用）と `new-issue`（相談者用）のスキル、および Issue テンプレートの正本はリポごとに持たず、グローバル `~/.claude/skills/`（dotfiles 管理）に置く。リポ固有の検証手段・検証手順は各リポの CLAUDE.md に書き、スキルがそれを参照する。

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

### 保証
- 新たに宣言する保証: {この変更後に成り立つべき振る舞いを自然言語の箇条書きで}
- 維持する保証: {この変更で壊してはいけない既存の振る舞いを自然言語の箇条書きで}

{内容に収まらない仕様を自由に展開}
```

保証節は自然言語で「振る舞い」を書く（テストコード・テスト名の指定は補足）。テストを伴わない変更は `保証: なし（理由）` と明示する。

### ライフサイクル

```
draft  →（設計完了・user が保証節を裁可）→  open  →（issue-finish）→  close
```

- `draft`: 設計中。`issue()` の選択肢から除外。
- `open`: 実装可能。`issue()` で選択可能。実行者は `status:` を変更しない。**open は user が保証節を裁可済みであることを含む**。
- `close`: 完了済み。`issue-finish` が更新する。

### 派生 Issue

検証で問題が発生した場合、元のIssueを `close` し、`{id}a` などの派生Issueを新規作成。

元のIssueを再open、または同一Agentセッションへの追記プロンプト送信は禁止。記録保持のため常にIssueファイルを起点とする。

### 情報セキュリティ

- Issue / PR・コミットメッセージ・コメントなど**人間が読む説明文に固有の接続情報を直書きしない**。代わりにローカルの機密辞書（`secrets-agents/`、非公開）で定義された `<PLACEHOLDER>` を用いる。
- 伏せる対象：ドメイン実値・公開ポート・Tunnel UUID・本番絶対パス・VPN IP / SSH ユーザ名・アプリ固有情報。localhost・開発ポート・リポジトリ相対パスは伏せない。

---

## シェル関数

### `issue`

対象Issueを選択し、Agentを起動。Issueの管理はローカルファイル（`issues/`）が唯一の真実。GitHub Issue は記録用ミラーで、`issue-finish` が完了時に「作成→即クローズ」で残す。

1. `status: open` のIssueを `fzf` で選択（プレビュー表示）。
2. worktree `{repo}.wt/{id}-{slug}` をブランチ `claude/{id}-{slug}` で作成し、選択した issue ファイルをブランチ上でコミットしてから、その中で `claude` コマンドを起動。main のチェックアウトは汚れず、複数Issueの並列実行が可能。

Code は GitHub に一切触れない（push・PR 作成・記録用 Issue はすべて `issue-finish` が担う）。

### `issue-abort`

進行中のタスクを中断し、変更を破棄。

1. `claude/*` の worktree を `fzf` で選択し、worktree とブランチを強制削除（`git worktree remove --force` + `git branch -D`）。

### `issue-finish`

レビュー済みブランチの公開（push → PR 作成 → マージ）、ブランチ後片付け、Issueクローズを一括実行。リモートに載るのは user がローカルでレビューしたものだけになる。

1. `main` 未マージの `claude/*` ブランチを `fzf` で選択（コミットログと diff をプレビュー）。
2. 選択ブランチを push し、コミットメッセージ本文を PR 本文として `gh pr create` → `gh pr merge --squash`。issue ファイルの open コミットも PR に含まれてマージされる。必須ステータスチェックのあるリポでは即時マージが拒否されるため、auto-merge に切り替えて CI 完了とマージ完了を待つ。
3. `git pull --prune` を実行（main のチェックアウトは常に main のまま）。
4. マージした `claude/*` の worktree・ローカル・リモートブランチを削除。
5. 記録用 GitHub Issue を作成して即クローズ（`github_issue:` に番号が既にあればクローズのみ）。作成失敗はフローを止めない。
6. ローカルIssueファイルを `status: close` に更新し、`main` へコミット・Push。
