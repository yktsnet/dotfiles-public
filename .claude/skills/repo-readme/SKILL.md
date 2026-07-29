---
name: repo-readme
description: 公開前にリポの README を readme-guide に従って作成・更新する。中身が固まった段階で実行する。Tech Stack の選定理由・Design Decisions・JUDGE.md/PLAN.md 統合（統合後は削除）・docs/ 分離・構成図まで含む本格 README を書きたいときに使う。
manual: true
---

# repo-readme

`~/dotfiles/docs-agents/readme-guide.md` を唯一の基準として README を作成/更新する。

**公開パイプラインの固定順**: `repo-standardize → guarantee-audit → repo-readme → readme-i18n → repo-publish → repo-about`。本 Skill は**第3**。足場とコアメッセージは `repo-standardize` が先に作り、保証台帳は `guarantee-audit` が先に敷く（README が台帳へリンクするには台帳が先に要るため）。本 Skill は**中身（アーキテクチャ・技術選定・判断）が固まった publish 前**に走らせる。この順は都度再判断しない。

## 0. 基準を読む（必須・最初に）

- `~/dotfiles/docs-agents/readme-guide.md` — README の構成・言語規則・JUDGE.md/PLAN.md 統合・docs/ 分離
- 必要に応じ `~/dotfiles/docs-agents/cicd.md`（Deploy 節の書き方）・`repo.md`（Secrets を README に書かない方針）

基準は本ファイルに転記しない。食い違ったらガイドを優先する。

## 1. 種別判定 → 素材を集める

readme-guide.md §1 のリトマス試験（使わせる？→ Type B。読ませるなら証拠がコードか数字かで Type A / Type C）でリポの種別を判定する。判定した種別を前提に、以下を読んでから書く。README は創作でなく**既にあるものの集約**。

- リポのコード・ディレクトリ構成（実際の構造・データフロー）
- `PLAN.md`（MVP 定義・完成条件）— 生きている内容を README の Scope へ吸収する。**統合ソース（後で削除する対象）**
- `JUDGE.md`（あれば）— 技術選定・判断ログ。README の Design Decisions と Tech Stack の Reason 列へ統合する（判断基準を AI が創作しない）。**統合ソース（後で削除する対象）**
- `context/structure.md` / `context/conventions.md`（設計の意図。これらは残す）
- `.github/workflows/`（CI/Deploy バッジ・デプロイ方式）
- 既存 README（あれば差分更新。良い記述は壊さない）

## 2. readme-guide に従って書く

readme-guide.md §0 の考える順序に従う。固定の H2 リストを流し込むのではなく、次を順に決める。**H2 の順序・命名・分割は固定しない**。

1. **下限（§2）**: 1で判定した種別（Type A/B/C）の下限チェックリストを満たすことを最低条件にする
2. **コアメッセージ（§3）**: 1文で「何を解決/実証/問うか＋どういう手段で」を確定し、H1直下の概要と一致させる
3. **ターゲット（§4）**: 習熟度／職種・レイヤー／技術利用者のどの軸で誰に向けるかを1つ選ぶ
4. **アウトライン（§5）**: 下限を満たす前提で、素材プール（Overview / Architecture / Results / Tech Stack（**Reason 列必須**）/ Design Decisions / Usage・API / Reproduce / Scope / Deploy / Comparison / Directory Structure 等）から H2 を選んで組み立てる

要点（詳細はガイド）:

- **言語規則**: H1〜H3 は英語、本文・H4 以降・表の中身は日本語
- **JUDGE.md 統合**: 判断ログを Design Decisions と Reason 列へ反映
- **Secrets を書かない**: GitHub Secrets 一覧・サーバ側手順・ドメイン実値/.ts.net/Tunnel UUID 等は README に載せない（運用ドキュメント管轄。`~/dotfiles/secrets-agents/` の <PLACEHOLDER> 方針）

## 3. 妥当性で取捨する（重要）

必須節を機械的に全部足さない。**そのリポの性質で本当に要るかを判断**する。

- 単純な静的サイト・設定リポでは Architecture(Mermaid)・Scope 等が過剰になりうる → 不要なら省き、省いた旨を一言添える
- 既存記述と重複する節を新設しない（同じ「なぜ」を複数箇所に書かない）。Design Decisions は横断的判断の集約先にし、各機能のインライン説明と重複させない
- 冗長になっていないか、書き終えたら通読して確認する

## 4. docs/ 分離を判断する

**書く前に分離を前提にしない**。README を書き終えてから、ガイドの分離条件（読者モーメントの違い・要点だけで足りる分量か）に照らして肥大した節だけ退避する。

- 分離先の典型候補・条件はガイド §7 に従う（`design-decisions.md` / `usage.md` / `release.md` / `deploy.md`。該当分だけ作る）
- 分離したら README 側に要点 + `docs/` リンクを残す
- `README.en.md` があるリポでは `docs/*.en.md` も対で作る（言語リンクを両ファイル冒頭に。英語版だけインライン、の非対称を作らない）
- 参照形: folio-agent・excel-kanri の README ↔ docs/ 構成

## 5. 統合ソースを削除する

JUDGE.md / PLAN.md は統合が済んだら削除する（統合 = 移設 + 削除。履歴は git にある）。

1. リポ内の参照を grep（`grep -rn "JUDGE\|PLAN" --include="*.md"` 等。CLAUDE.md・context/・issues/ が指していることがある）
2. 参照先を README / docs/ へ書き換える
3. 削除する

## 6. 出して止まる

変更はワーキングツリーに残し、追加/削除した節・docs/ 分離の判断・削除したファイルを要約して報告する。
コミット/push はユーザーの指示があったときのみ。

## 注意

- 本 Skill は README と docs/ を担当。`.claude/`・LICENSE・.gitignore 等の足場は `repo-standardize` の管轄（重複して触らない）。
- 既存の良質 README（例: training-scheduler）を参照形として倣ってよい。
