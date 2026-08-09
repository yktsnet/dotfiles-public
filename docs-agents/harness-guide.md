[🇯🇵 日本語](harness-guide.md) | [🇬🇧 English](harness-guide.en.md)

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

検証手段は**その環境で追加インストールなしに走るもの**を選ぶ。再現性を壊す命令的なグローバル導入（`pip install`・`npm install -g` 等）は禁止。標準にないツールは使い捨て環境で取り込む（本フリートは Nix 管理のため `nix-shell -p {pkg} --run "..."`）。Issue の `確認` 欄も、env に標準で在る手段（`php -l` 等）か使い捨て環境／目視を書く。

PR の `## 検証手順` には Agent 側で完結しない確認（デプロイ・ブラウザ・本番動作）を書き、user に委ねる。安全に走るものは Agent 側、危険なもの（本番・デプロイ・マージ）は user 側。

---

## 2. 層の構成

| 層 | 内容 | 適用 |
|---|---|---|
| 層1 事故防止 | `settings.json` の deny ＋ attribution ＋ `hooks/` の PreToolUse | 全リポ |
| 層2 運用基盤 | 指示ファイル（CLAUDE.md / context/ / Skills）＋ 検証手段 | Agent を走らせる全リポ |
| 層3 公開検証 | CI（`cicd-guide.md`） | Public または自動デプロイあり |

---

## 3. 層1 — settings.json とフック

`.claude/settings.json` をチェックインする。`.local.json` は gitignore される個人上書き用。

遮断の手段は2つある。`deny` は宣言的で読みやすいが**文字列の前方一致**しか見ない。コマンドの構造や編集先の意味を判定する必要があるものは PreToolUse フックで書く（後述の 3.5）。

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

リポ外のディレクトリ（機密辞書等）を読ませる場合は、`permissions` の `additionalDirectories` に対象パスを追加する。

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

### 3.5 フック（`.claude/hooks/`）

`deny` は文字列の前方一致であって、コマンドの解釈ではない。`Bash(pip install *)` を deny に置いても、`/tmp/venv/bin/pip install x` も `make setup && pip install x` も一致しない。**禁止したい対象が文字列ではなく行為であるとき**は PreToolUse フックで判定する。

本リポの `.claude/hooks/` に実装がある。稼働環境では `home-manager/modules/claude.nix` が `.claude/` を `~/.claude/` へ配置するため、同じ実体が全リポに効く。

| フック | 契機 | 塞いでいるもの |
|---|---|---|
| `block-non-nix-install.sh` | PreToolUse `Bash` | Nix 外のパッケージ導入（pip / brew / npm -g / cargo / gem）。パス付き実行・複合コマンド内も捕捉する |
| `block-live-claude-config-edit.sh` | PreToolUse `Edit\|Write\|Bash` | 生成物である `~/.claude/` への直接編集。生成元のパスへ書き換えて返す。`sed -i` 等のシェル経由の書き込みも見る（読み取りは通す） |
| `block-new-skill-md.sh` | PreToolUse `Write\|Bash` | 新規 `SKILL.md` の規約違反。frontmatter（`name` / `description` / 明示呼び出し指定）と配置先を検査し、`~/.claude/skills/` への直書きは拒否、repo-local は確認を挟む |
| `block-project-scoped-memory.sh` | PreToolUse `Edit\|Write` | メモリの置き場違い（後述の 4.5） |
| `sync-memory-index.sh` | SessionStart | （遮断ではなく生成）`MEMORY.md` の再生成 |
| `opus-scope-and-concision.sh` | SessionStart | （遮断ではなく注入）Opus 系のときだけ簡潔性とスコープ厳守を足す |
| `backup-secret-json.sh` | PreToolUse `Edit\|Write` | `secrets/**/*.json.age` の上書き前にバックアップ（遮断ではなく安全網。直近5世代のみ保持） |

#### 判定はコマンド位置で行う

`block-non-nix-install.sh` の照合はこの形にしてある。

```bash
stripped=$(printf '%s' "$cmd" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')
pre='(^|[;&|`]|\$\()[[:space:]]*(sudo[[:space:]]+)?(env[[:space:]]+)?([[:alnum:]@/_.~+-]*/)?'
```

引用符の中身を先に落とすのは、コミットメッセージに `pip install` と書いただけで発火する誤検知を消すため。`pre` でコマンド位置（行頭、または `;` `|` `&` `` ` `` `$(` の直後）に限定し、パス付き実行と `sudo` / `env` の前置を吸収する。

#### 拒否メッセージを分岐器として書く

Agent は拒否されると別の手を試す。何を試すかは拒否文で指定できるので、フックの `permissionDecisionReason` には**理由と代替手順の両方**を入れる。`block-non-nix-install.sh` は `nix run` / `nix shell` / `home.nix` / `shell.nix` の使い分けと `nix-tool-install` スキルを返し、`block-live-claude-config-edit.sh` は編集先を機械的に書き換えて提示する。

```bash
dotfiles_path="${file_path/#$home\/.claude\//$home/dotfiles/.claude/}"
```

壁を立てるだけなら `deny` で足りる。フックの利得は、拒否と同時に正しい経路へ寄せられる点にある。

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
**書かないもの**: 禁止・強制（→ settings.json の deny）、attribution（→ settings.json）、長大な仕様、公開を避けるべきインフラ設定・秘密情報（→ `~/dotfiles/secrets-agents/` のファイルを参照する指示のみを書く）。

### context/

| ファイル | 役割 |
|---|---|
| `conventions.md` | 命名規則・コード規約・スタイル（どう書くか） |
| `structure.md` | ディレクトリ構成・ルーティング・データフロー（どこに何があるか） |

リポの性質に応じてファイルを足してよい。2ファイルに収まるなら分けなくてもよい。

### Skills

ワークフロー用スキルはリポごとに持たず、グローバル `~/.claude/skills/` を使う。正本は本リポの `.claude/skills/` にあり、`home-manager/modules/claude.nix` がそこへコピーする。

| Skill | 役割 |
|---|---|
| `pr-workflow` | 実行者用。実装 → 検証手段の実行 → ローカルコミット（ブランチと worktree は `issue()` が作成。push・PR 作成は `issue-finish` が行う） |
| `new-issue` | 相談者用。要件整理 → 機密マスク → `issues/` に Issue 書き出し |
| `consolidate-rules` | 規則ファイル間の矛盾・陳腐化の棚卸し（後述の 4.6） |

どちらも汎用フローのみを定義し、リポ固有の検証手段・検証手順（上記セクション1）は各リポの CLAUDE.md に書く。スキルはそれを参照する。
`pr-workflow` は `issue-driven-workflow.md` のシェル関数 `issue()` から `claude` コマンドで起動される。

### 知識の配置基準

知識の置き場は、読み込みの契機で決める。

| 契機 | 置き場 |
|---|---|
| 毎回効く短い規則 | CLAUDE.md に1行 |
| 「〜するとき」と条件を言える手順・規範 | skill（description が起動条件の宣言になる） |
| 規則から指す共有辞書・ガイド | 独立ディレクトリに置き、CLAUDE.md / skill から絶対パスで参照（例: `secrets-agents/`・`docs-agents/`） |
| 人間の下書き・未整理の思考 | ハーネスの外。AI に自動で読ませない |

移住のトリガーは「またこのドキュメントを手で渡したな」と気づいた瞬間である。一括移行はしない。

skill の骨格:

```markdown
---
name: sops-secrets
description: sops / age による secret の暗号化・復号・再暗号化の運用手順。secret を暗号化するとき、`.sops.yaml` を変更するとき、新デバイスの鍵を登録するときに使用する。
---
```

description に「〜するとき使用する」と起動条件を列挙し、暗黙知を宣言に変える。

skill の更新は自動抽出しない。作業中にズレへ気づいたら提案に留め、レビューされない規範を量産しない。

### 4.5 永続メモリ

セッションをまたいで残す知識は `~/memory/` に置く。1ファイル1事実で、型ごとにサブディレクトリを分ける。

| 型 | 内容 |
|---|---|
| `user` | user 自身のこと（役割・専門・好み） |
| `feedback` | 進め方への指示。理由（**Why**）と適用方法（**How to apply**）を併記する |
| `project` | コードや git 履歴から導けない進行中の事情・制約。相対日付は絶対日付に直す |
| `reference` | 外部資源へのポインタ（URL・ダッシュボード・チケット） |

索引 `~/memory/MEMORY.md` は**生成物であって手書きしない**。SessionStart の `sync-memory-index.sh` が各ファイルの frontmatter（`name` / `description`）から再生成する。差分があるときだけ書き換えるので、無変更セッションでは何も起きない。

ハーネスのシステムプロンプトは置き場として `~/.claude/projects/<project>/memory/` を指示してくることがある。この環境の正本は `~/memory/` なので、そちらへ書かれると索引に載らない重複が溜まる。`block-project-scoped-memory.sh` がプロジェクトスコープへの書き込みを拒否し、ファイル名から正しい配置先を組み立てて返す。

索引を自動生成しても、書き込み先が違えば索引には現れない。**生成（`sync-memory-index.sh`）と遮断（`block-project-scoped-memory.sh`）は別の対策であり、両方要る。**

### 4.6 規則の棚卸し

CLAUDE.md・skill・memory はいずれも「人が書いた規則を AI が読む」構造で、規則同士の矛盾を検出する仕組みを持たない。規則ファイルは増え続けるため、矛盾と陳腐化はいずれ Agent の挙動を不安定にする。`consolidate-rules` スキルがこの棚卸しを担う。

見る乖離は3種類ある。

1. `docs-agents` 内部の相互矛盾（例: `test-policy.md` と `issue-driven-workflow.md` で基準がずれる）
2. CLAUDE.md と `docs-agents` の乖離（CLAUDE.md にしか無い規則が、ガイドの更新で置き去りになる）
3. skill の `description` と本文の乖離（規則を直したのに起動条件が古いまま残る）

設計上の要点が2つある。

**索引を挟んで差分だけ読む。** `.claude/RULES.md` に規則の中身は書かず、ファイルへのポインタ・一言要約・相互参照・前回棚卸し時点の commit と日付だけを置く。2回目以降はそこを起点に、記録より後に変更されたファイルだけを深読みする。索引が無い設計では実行のたびに全対象を読むことになり、定期実行のコストが対象数に比例して積み上がる。

**除外リストを保守しない。** 監査対象は自分が書いた規則であって、ベンダー製の技術リファレンスや標準搭載スキルではない。これを固定リストで持つと skill が増えるたびに保守が要るので、frontmatter の `description` が日本語かどうかで機械的に切り分ける。

指摘は1件ずつ user の裁可を取ってから反映する。まとめて承認にしない。

---

## 5. 新規リポのチェックリスト

```
[ ] 類型を判定（設定 / ロジック / Web / ツール、Public / Private）
[ ] 層1: .claude/settings.json（共通 deny ＋ 類型別 deny ＋ attribution）
[ ] 層2: CLAUDE.md（@import ＋ コマンド ＋ 構造 ＋ 検証手段・検証手順の雛形、200行以下）
[ ] 層2: context/（conventions.md ＋ structure.md）
[ ] 層3: Public / 自動デプロイなら CI（cicd-guide.md）
[ ] 禁止事項は CLAUDE.md でなく settings.json の deny に書く
```
