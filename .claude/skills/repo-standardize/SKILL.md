---
name: repo-standardize
description: 新規リポの組成、または既存リポの公開前点検を docs-agents の4基準で行う。リポを初期化・標準化・点検したいとき、新規ディレクトリを作って足場を整えたいときに使う。
manual: true
---

# repo-standardize

`~/dotfiles/docs-agents/` の4ガイドを唯一の基準として、対象リポを準拠状態にする。
基準そのものは本ファイルに転記しない。**毎回ガイドを読み、最新の基準に従う**。

## 前提

動くソースコードがあるリポに対して実行する。コードがない段階では実行しない。

## 0. 基準を読む（必須・最初に）

以下4本を読む。これが基準のすべて。

- `~/dotfiles/docs-agents/repo.md` — ファイル衛生（LICENSE・.gitignore・.env.example・0バイト禁止・成果物非追跡）
- `~/dotfiles/docs-agents/harness.md` — `.claude/`（settings.json の層1・CLAUDE.md・context/・skills/pr-workflow）と検証手段
- `~/dotfiles/docs-agents/workflow.md` — issues/・担当分離・Issue フォーマット
- `~/dotfiles/docs-agents/cicd.md` — CI/デプロイ（Public のみ層3）

> `readme-guide.md` は本 Skill の管轄外。本格 README は `repo-readme` Skill で作成する。

## 1. 文脈（分類）を確定する

既存のソースコードと設定から以下を読み取る。

| 項目 | 取りうる値 | 影響先 |
|---|---|---|
| リポ名 | — | README H1・LICENSE |
| 類型 | 設定 / ロジック / Web / ツール | settings.json の allow/deny、検証手段、CI |
| 公開 | Public / Private | LICENSE 必須性、層3 CI の要否 |
| スタック | 例: Go+Vue / Python+React / Astro / Nix | コマンド・conventions・CI ステップ |
| 検証手段 | 例: `make test` / `nix flake check` | CLAUDE.md・pr-workflow・CI |

**引数は使わない。** 既存ファイルから読み取れない項目は推測で埋めず、**必ずユーザーに質問する**。

## 2. 雛形から生成する成果物

`reference/` に雛形がある。雛形には `<!-- FILL: 説明 -->` マーカーで埋めるべき箇所が示されている。**マーカーの箇所だけを埋め、それ以外は一字一句変えない。** FILL コメント自体は出力から除去する。

| 雛形 | 出力先 |
|---|---|
| `settings-json-{type}.json` | `.claude/settings.json` |
| `pr-workflow.md` | `.claude/skills/pr-workflow/SKILL.md` |
| `issue-template.md` | `issues/00_template.md` |
| `gitignore-base.txt` | `.gitignore` |
| `license-mit.txt` | `LICENSE`（Public のみ必須） |

`settings-json-{type}.json` は JSON のためコメントが使えない。allow 配列にスタック固有の行を追加する。deny・attribution は変えない。

既存の `.gitignore` がある場合は、base の共通行が含まれていることを確認し、不足があれば追加する（上書きしない）。

`issues/done/.gitkeep` も作成する。

## 3. 実コードを読んで生成する成果物

雛形がない。ソースコードを読み、そのリポ固有の判断を含めて書く。

| 成果物 | 書くべき内容 |
|---|---|
| `CLAUDE.md` | `@import` + 実際に動くコマンド（setup / dev / build / 検証）+ アーキテクチャの要点 + 検証手段。200行以下 |
| `context/conventions.md` | 実コードから読み取った命名規則・コード規約・スタイル。汎用ルール（「PEP8 準拠」等）の羅列ではなく、**このリポ固有の判断**を書く |
| `context/structure.md` | **実在するファイル**のディレクトリ構成・データフロー・レイヤー構成 |
`.claude/`・`CLAUDE.md`・`context/`・`issues/` は**公開リポでは追跡対象**（gitignore で全無視しない。無視は `.claude/settings.local.json` のみ）。

## 4. 決定的チェック（report）

生成・修正後、最低限を機械確認して結果を表で報告する:

```
[ ] LICENSE 有（Public）
[ ] 0バイト/プレースホルダのみのファイルなし（.gitkeep/__init__.py 等の慣用は除外）
[ ] 追跡済みに成果物（bin/dist/db/node_modules/.env）なし（git ls-files）
[ ] .gitignore に無関係スタック残骸・重複行なし
[ ] .env 非追跡 ＋ .env.example 有（.env 使用時）
[ ] .claude/settings.json 有（JSON 妥当・deny に push/force、attribution 空）
[ ] CLAUDE.md / context/{conventions,structure}.md / skills/pr-workflow/SKILL.md 有・非空
[ ] issues/00_template.md 有
[ ] README が存在（最低 H1＋概要・0バイトでない）。本格構成は publish 前に `repo-readme` で整える
[ ] CI 有（Public/自動デプロイ時）
[ ] 地の文・コミット・PR にシークレット直書きなし（ドメイン実値/.ts.net/Tunnel UUID/SSHユーザ等は ~/dotfiles/secrets-agents/ の <PLACEHOLDER>）
```

## 5. コミット・push はしない

変更はワーキングツリーに残し、差分を要約して止まる。コミット/push はユーザーの指示があったときのみ。
（このフリートの担当分離: 実装は実行者、本番操作・マージは user。）

## 注意

- 基準は本ファイルでなく `~/dotfiles/docs-agents/` が正。食い違ったらガイドを優先する。
- スタック差で settings.json の allow/deny・検証コマンド・CI ステップが変わる。harness の類型表が分岐表。
