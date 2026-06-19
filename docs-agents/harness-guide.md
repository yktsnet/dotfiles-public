# Harness Guide

リポごとの `.claude/` 構成・指示ファイル・検証手段の設計ガイド。
新規リポでは `issue-driven-workflow.md`（プロセス層）と本書（ハーネス層）を最初に適用する。CI/CD は `cicd-guide.md` へ委譲。

設計意図は2点。**禁止は設定に書き、指示ファイルは短く保つ**。**検証手段を Agent に与え、PR 前に自己確認させる**。

---

## 1. リポ類型と検証手段

リポを類型で分類し、Agent が PR 前に実行する検証手段を決める。
検証手段は test とは限らない。「自分の変更が壊れていない」と確かめる経路を1つ以上持てばよい。

| 類型 | 検証手段 |
|---|---|
| 設定（IaC・dotfiles） | 構文チェック（`flake check`・`zsh -n`・`py_compile` 等） |
| ロジック（バッチ・常駐・解析） | 構文チェック ＋ import・caller 確認。可能ならドライラン。test があれば実行 |
| Web（API・サイト） | 型チェック ＋ test |
| ツール（自動化・Agent 駆動） | 構文チェック。副作用コマンドを強く絞る |

公開状態を直交軸とする。**Public** は CI（層3）を持つ。**Private** は CI 任意、ローカル検証で代替。

PR の `## 検証手順` には Agent 側で完結しない確認（デプロイ・ブラウザ・本番動作）を書き、user に委ねる。安全に走るものは Agent 側、危険なもの（本番・デプロイ・マージ）は user 側。

---

## 2. 層の構成

| 層 | 内容 | 適用 |
|---|---|---|
| 層1 事故防止 | `settings.json` の deny ＋ attribution | 全リポ |
| 層2 運用基盤 | 指示ファイル（CLAUDE.md / context/ / Skills）＋ 検証手段 | Agent を走らせる全リポ |
| 層3 公開検証 | CI（`cicd-guide.md`） | Public または自動デプロイあり |

---

## 3. 層1 — settings.json

`.claude/settings.json` をチェックインする。`.local.json` は gitignore される個人上書き用。

### deny（共通）

```json
"deny": [
  "Bash(git push origin main*)",
  "Bash(git push --force *)",
  "Bash(git push -f *)"
]
```

### deny（類型別・共通に追加）

| 類型 | 追加 deny |
|---|---|
| 設定 | 適用コマンド（`*-rebuild *` 等）、シークレット読み書き、ロックファイル編集 |
| ロジック | 本番起動・外部副作用を伴うコマンド（実発注・実送信・実課金系） |
| Web | デプロイ CLI（`wrangler` 等） |
| ツール | 役割に応じ副作用コマンドを deny に残す |

自ホスト環境では `ssh`・`rsync` も deny に加える（デプロイ経路の遮断）。

### allow（共通）

```json
"allow": ["Bash(git *)", "Bash(gh pr *)"]
```

push 系は deny が優先されるため `Bash(git *)` allow と両立する。

### allow（類型別）

| 類型 | 追加 allow |
|---|---|
| 設定 | パーサ・構文チェック系 |
| ロジック | 言語ランタイム（本番コマンドは deny で個別遮断） |
| Web | パッケージ実行（`npm run *` / test ランナー / ビルド CLI） |

### attribution

```json
"attribution": { "commit": "", "pr": "" }
```

Co-Authored-By を外す。Agent は道具であり共著者ではない、という立場。commit 履歴に人間以外の名前を混ぜると blame の可読性も下がる。

---

## 4. 層2 — 指示ファイル

Agent が読む指示を役割で分ける。

### CLAUDE.md（エントリポイント・200行以下）

`@import` で context を読み込む。

```markdown
# CLAUDE.md
@context/conventions.md
@context/structure.md

## コマンド
{setup / dev / build / 検証コマンド}

## アーキテクチャの要点
{唯一のデータソース・レイヤー構成など最小限}

## 検証手段
{PR 前に Agent が確認する経路}
```

**書くもの**: コマンド、構造の要点、検証手段。
**書かないもの**: 禁止・強制（→ settings.json の deny）、attribution（→ settings.json）、長大な仕様（→ context/ または `.claude/rules/`）。

### context/

| ファイル | 役割 |
|---|---|
| `conventions.md` | 命名規則・コード規約・スタイル（どう書くか） |
| `structure.md` | ディレクトリ構成・ルーティング・データフロー（どこに何があるか） |

リポの性質に応じてファイルを足してよい。2ファイルに収まるなら分けなくてもよい。

### Skills

`.claude/skills/{name}/SKILL.md`。フロントマターに `name` と `description`。

| Skill | 役割 |
|---|---|
| `pr-workflow` | ブランチ作成 → 実装 → 検証手段の実行 → PR 作成 |

`pr-workflow` の検証 step に、上記セクション1の検証手段を組み込む。
`issue-driven-workflow.md` のシェル関数 `issue()` から `claude` コマンドで起動される。

---

## 5. 新規リポのチェックリスト

```
[ ] 類型を判定（設定 / ロジック / Web / ツール、Public / Private）
[ ] 層1: .claude/settings.json（共通 deny ＋ 類型別 deny ＋ attribution）
[ ] 層2: CLAUDE.md（@import ＋ コマンド ＋ 構造 ＋ 検証手段、200行以下）
[ ] 層2: context/（conventions.md ＋ structure.md）
[ ] 層2: .claude/skills/pr-workflow/SKILL.md
[ ] 層3: Public / 自動デプロイなら CI（cicd-guide.md）
[ ] 禁止事項は CLAUDE.md でなく settings.json の deny に書く
```
