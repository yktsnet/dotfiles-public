---
name: repo-standardize
description: 新規リポの組成、または既存リポの公開前点検を docs-agents の5基準で行う。リポを初期化・標準化・点検したいとき、新規ディレクトリを作って足場を整えたいときに使う。
manual: true
---

# repo-standardize

`~/dotfiles/docs-agents/` の5ガイドを唯一の基準として、対象リポを準拠状態にする。
基準そのものは本ファイルに転記しない。**毎回ガイドを読み、最新の基準に従う**。

## 0. 基準を読む（必須・最初に）

以下5本を読む。これが基準のすべて。

- `~/dotfiles/docs-agents/repo-guide.md` — ファイル衛生（LICENSE・.gitignore・.env.example・0バイト禁止・成果物非追跡）
- `~/dotfiles/docs-agents/harness-guide.md` — `.claude/`（settings.json の層1・CLAUDE.md・context/・skills/pr-workflow）と検証手段
- `~/dotfiles/docs-agents/issue-driven-workflow.md` — issues/・担当分離・Issue フォーマット
- `~/dotfiles/docs-agents/readme-guide.md` — README 構成・言語規則・JUDGE.md 統合
- `~/dotfiles/docs-agents/cicd-guide.md` — CI/デプロイ（Public のみ層3）

## 1. モードを判定

- 対象ディレクトリが空 or ほぼ空 → **新規組成モード**
- 既にコードがある → **点検モード**（不足の補完と違反の修正）

## 2. 文脈（分類）を確定する

scaffold には以下が要る。`PLAN.md` / 既存 `README.md` / ソースから拾う。

| 項目 | 取りうる値 | 影響先 |
|---|---|---|
| リポ名 | — | README H1・LICENSE |
| 類型 | 設定 / ロジック / Web / ツール | settings.json の allow/deny、検証手段、CI |
| 公開 | Public / Private | LICENSE 必須性、層3 CI の要否 |
| スタック | 例: .NET8+React / Go+Vue / Astro / Nix | コマンド・conventions・CI ステップ |
| 検証手段 | 例: `dotnet build` / `nix flake check` | CLAUDE.md・SKILL.md・CI |

**引数は使わない。** 既存ファイルから読み取れない項目は推測で埋めず、**必ずユーザーに質問する**。

> 原則: 5ファイルと対象ディレクトリを読んでも確信を持って作れないと判断したら、勝手に進めず**必ず質問して止まる**。曖昧なまま雛形を作らない。

## 3. 適用する（ガイドに従って生成・修正）

判定した類型・スタックに合わせて、各ガイドの「新規リポのチェックリスト」を満たす:

- **repo-guide**: `LICENSE`（Public は必須・年/owner 確認）、`.gitignore`（当該スタックの行のみ・重複なし）、`.env`使用時は`.env.example`、0バイト/プレースホルダ放置なし、成果物は追跡しない
- **harness-guide**: `.claude/settings.json`（共通 deny＋類型別 deny＋`attribution:{commit:"",pr:""}`、`.claude/settings.local.json` のみ gitignore）、`CLAUDE.md`（@import＋コマンド＋構造＋検証手段、200行以下）、`context/conventions.md`＋`context/structure.md`、`.claude/skills/pr-workflow/SKILL.md`
- **issue-driven**: `issues/00_template.md`＋`issues/done/.gitkeep`
- **README**: 新規時は**最小スタブのみ**（H1＋1〜2行概要、Quick Start 程度。0バイトにはしない）。Architecture/Tech Stack(Reason列)/Design Decisions/JUDGE 統合などの本格構成は、中身が固まった **publish 前に別 Skill `repo-readme` で作成する**（readme-guide はそちらの管轄）
- **cicd-guide**: Public または自動デプロイありなら `.github/workflows/ci.yml`（類型別の検証を CI でも回す）

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
- スタック差で settings.json の allow/deny・検証コマンド・CI ステップが変わる。harness-guide の類型表が分岐表。
- 既存の準拠リポ（例: taikan-base-weather）を参照実装として倣ってよい。
