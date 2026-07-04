---
name: repo-readme
description: 公開前にリポの README を readme-guide に従って作成・更新する。中身が固まった段階で実行する。Tech Stack の選定理由・Design Decisions・JUDGE.md 統合・構成図まで含む本格 README を書きたいときに使う。
manual: true
---

# repo-readme

`~/dotfiles/docs-agents/readme-guide.md` を唯一の基準として README を作成/更新する。
**ライフサイクル上の位置**: リポの足場は `repo-standardize` が作る。本 Skill はそれより後、**中身（アーキテクチャ・技術選定・判断）が固まった publish 前**に走らせる。

## 0. 基準を読む（必須・最初に）

- `~/dotfiles/docs-agents/readme-guide.md` — README の構成・言語規則・JUDGE.md 統合
- 必要に応じ `~/dotfiles/docs-agents/cicd.md`（Deploy 節の書き方）・`repo.md`（Secrets を README に書かない方針）

基準は本ファイルに転記しない。食い違ったらガイドを優先する。

## 1. 素材を集める

README は創作でなく**既にあるものの集約**。以下を読んでから書く。

- リポのコード・ディレクトリ構成（実際の構造・データフロー）
- `PLAN.md` / `context/structure.md` / `context/conventions.md`（設計の意図）
- `JUDGE.md`（あれば）— 技術選定・判断ログ。**README の Design Decisions と Tech Stack の Reason 列へ統合する**（判断基準を AI が創作しない）
- `.github/workflows/`（CI/Deploy バッジ・デプロイ方式）
- 既存 README（あれば差分更新。良い記述は壊さない）

## 2. readme-guide に従って書く

要点（詳細はガイド）:

- **言語規則**: H1〜H3 は英語、本文・H4 以降・表の中身は日本語
- **構成（上から順）**: H1＋バッジ＋概要 / Quick Start / Overview / Architecture（Mermaid 推奨）/ Tech Stack（**Reason 列必須**）/ Design Decisions / Scope（Focus & Out-of-Scope）/ Deploy（公開アプリのみ）/ Development / Directory Structure（任意）
- **JUDGE.md 統合**: 判断ログを Design Decisions と Reason 列へ反映
- **Secrets を書かない**: GitHub Secrets 一覧・サーバ側手順・ドメイン実値/.ts.net/Tunnel UUID 等は README に載せない（運用ドキュメント管轄。`~/dotfiles/secrets-agents/` の <PLACEHOLDER> 方針）

## 3. 妥当性で取捨する（重要）

必須節を機械的に全部足さない。**そのリポの性質で本当に要るかを判断**する。

- 単純な静的サイト・設定リポでは Architecture(Mermaid)・Scope 等が過剰になりうる → 不要なら省き、省いた旨を一言添える
- 既存記述と重複する節を新設しない（同じ「なぜ」を複数箇所に書かない）。Design Decisions は横断的判断の集約先にし、各機能のインライン説明と重複させない
- 冗長になっていないか、書き終えたら通読して確認する

## 4. 出して止まる

変更はワーキングツリーに残し、追加/削除した節と冗長性の判断を要約して報告する。
コミット/push はユーザーの指示があったときのみ。

## 注意

- 本 Skill は README のみを担当。`.claude/`・LICENSE・.gitignore 等の足場は `repo-standardize` の管轄（重複して触らない）。
- 既存の良質 README（例: training-scheduler）を参照形として倣ってよい。
