# README Guide

公開リポの README 作成ガイド。実装完了後に README を書くにあたっての、構成と書き方のルール。

開発中に JUDGE.md へ記録した技術選定の判断根拠を README に統合し、「何を使っているか」だけでなく「なぜその選択をしたか」まで可視化する。

---

## 1. 言語規則

- 見出し H1〜H3 は英語
- 本文・H4 以降・表の中身は日本語


---

## 2. 構成

上から順に並べる。読者が最短で動かし、次に設計意図を理解する流れ。

| セクション | 内容 | 必須 |
|---|---|---|
| **H1 + バッジ + 概要** | プロジェクト名、CI/Deploy バッジ、1〜2行の概要 | ○ |
| **Quick Start** | Prerequisites → セットアップ手順 → 起動確認 URL。コピペで動く状態 | ○ |
| **Overview** | 目的・背景・デモ URL。何を解決するプロジェクトか | ○ |
| **Architecture** | 構成図（Mermaid）・データフロー・レイヤー構成。文章より図 | ○ |
| **Tech Stack** | 表形式。技術名だけでなく選定理由を添える（後述の JUDGE.md 統合） | ○ |
| **Design Decisions** | JUDGE.md から統合した選定根拠。Why を書く | ○ |
| **Scope** | Focus（何に特化）と Out-of-Scope（何をやらないか）を明示 | ○ |
| **Deploy** | デプロイ方式・Secrets 一覧・初回セットアップ手順 | 公開アプリのみ |
| **Development** | ローカル開発手順・テスト実行・型チェック等のコマンド一覧 | ○ |
| **Directory Structure** | ツリー形式。主要ファイルにコメント | 任意 |

### H1 + バッジ

```markdown
# Project Name

[![CI](https://github.com/{owner}/{repo}/actions/workflows/ci.yml/badge.svg)](...)
[![Deploy](https://github.com/{owner}/{repo}/actions/workflows/deploy.yml/badge.svg)](...)

1〜2行の概要。
```

Deploy バッジは自動デプロイがあるリポのみ。

### Quick Start

Docker で動くなら Docker だけの手順を先に書く。言語ランタイムの個別インストールは Local Development セクションへ。

```markdown
## Quick Start

### Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

### Setup
\```bash
cp .env.example .env
docker compose up -d --build
\```

- App: http://localhost:{port}
```

### Tech Stack

技術名と選定理由を表で書く。「何を使っているか」だけでなく「なぜそれか」まで。

```markdown
## Tech Stack

| Layer | Technology | Reason |
|---|---|---|
| Frontend | React, TypeScript, Vite | ... |
| Backend | .NET 8 (Minimal API) | ... |
```

---

## 3. JUDGE.md の統合

開発中、技術選定の判断基準を `JUDGE.md` に記録する（なぜその技術・構成を選んだか）。これは AI への指示ファイルではなく、user の作業産物。

公開時、`JUDGE.md` の内容を README の Design Decisions セクションおよび Tech Stack の Reason 列へ統合する。

- `JUDGE.md` … 開発中の判断ログ（ADR 的）。リポに残すかは任意
- README … 統合後の選定理由。公開向けに整理

> AI への前提: 「`JUDGE.md` があれば、その判断基準を README の選定理由へ反映する」。判断基準そのものを AI が創作しない。

---

## 4. 図

構成図・データフローは Mermaid で書く。README 内にインラインで埋め込み、GitHub 上でレンダリングさせる。

画像を使う場合は `src/` や `docs/` に置き、相対パスで参照する。外部ホスティング（imgur 等）に依存しない。

