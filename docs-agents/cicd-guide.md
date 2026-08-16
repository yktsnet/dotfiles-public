[🇯🇵 日本語](cicd-guide.md) | [🇬🇧 English](cicd-guide.en.md)

# CI/CD Guide

リポの CI/CD 設計ガイド。新規リポを作るとき、検証とデプロイの経路をここから決める。
`harness-guide.md` の層3（公開検証）に対応し、`issue-driven-workflow.md` の担当分離と接続する。

設計意図は2点。**CI は Agent のローカル検証と同じものを回す**（二重化で PR 前の見落としを拾う）。**デプロイは CI 通過後の自動プッシュ型**（手動オペを挟まない）。

---

## 1. 2つのリポパターン

新規リポは大きく2種類に分かれる。CI/CD の構成はここで決まる。

| パターン | 典型 | CI | デプロイ |
|---|---|---|---|
| **公開アプリ** | Web アプリ・ポートフォリオ作品 | GitHub Actions（構文/型チェック → test → build） | Cloudflare（Pages / Workers）へ自動デプロイ |
| **内部ツール** | データ処理スクリプト・自動化スクリプト・シェルコマンド | 任意（ローカル検証で代替可） | なし（ローカル実行 or dotfiles 経由で配布） |

公開アプリは外から見えるため、CI とデプロイを持つ。内部ツールは自分しか使わないため、`harness-guide.md` の層2（ローカル検証）で十分。

**デプロイ先は Cloudflare に寄せる。** 自ホスト（VPS 等）へ配る経路は新規に作らない。サーバーの生存・OS 更新・鍵の管理が運用コストとして残り続けるため、サーバレスで足りるものはサーバレスに置く。

---

## 2. CI

`.github/workflows/ci.yml`。push / pull_request をトリガーに、`harness-guide.md` で定めた検証手段と同じものを走らせる。

| 類型 | CI で走らせる |
|---|---|
| 設定 | 構文チェック（`flake check` / `zsh -n` 等） |
| ロジック | 構文チェック ＋ test（あれば） |
| Web | 型チェック → test → build |

```yaml
on:
  push: { branches: [main] }
  pull_request: { branches: [main] }
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-node@v6   # 言語に応じて差し替え
        with: { node-version: 24 }
      - run: npm test                 # 依存が無いリポは node --test 等をそのまま呼ぶ
```

依存パッケージを持たないリポでは `npm ci` を置かない。**実際に走らせているコマンドと CI を一致させる**のが趣旨であり、雛形の踏襲ではない。

内部ツールで CI を入れる場合も同じ構成。ただし多くの場合、Agent のローカル検証（構文チェック・ドライラン）で事足りるため、CI は省略してよい。

---

## 3. デプロイ（Cloudflare）

### 3-1. Pages（静的サイト・Pages Functions）

既定はこれ。**GitHub 連携を使い、Actions にデプロイ job を書かない**。Cloudflare 側が push を検知してビルド・配信する。CI（Actions）とデプロイ（Cloudflare）が独立し、デプロイ用の API トークンを GitHub に置かずに済む。

初回接続は Cloudflare ダッシュボードでの操作になる（user 担当）。設定するのは次の3点。

| 項目 | 内容 |
|---|---|
| ビルドコマンド | 無ければ空。ある場合はローカルと同じもの |
| ビルド出力ディレクトリ | 配信する静的ファイルの置き場（例: `public` / `dist`） |
| 環境変数 | 本番値は Cloudflare 側に置く。リポには `.env.example` のキーだけ |

`functions/` はリポジトリ直下に置けば自動で Pages Functions として展開される。

CI の通過を待ってから配信したい場合のみ、GitHub 連携をやめて Actions から `wrangler pages deploy` を打つ形に切り替える。トークンの管理が増えるため、必要になるまで採らない。

### 3-2. Workers

`wrangler deploy` を Actions から実行する。

```yaml
deploy:
  needs: test
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v6
    - uses: cloudflare/wrangler-action@v3
      with:
        apiToken: ${{ secrets.CLOUDFLARE_API_TOKEN }}
        accountId: ${{ secrets.CLOUDFLARE_ACCOUNT_ID }}
```

`wrangler` は Agent の settings.json で deny する（`harness-guide.md` の Web 類型）。デプロイを打つのは CI か user であって、Agent ではない。

---

## 4. 公開とアクセス制御

Pages / Workers の独自ドメインは Cloudflare 側で割り当てる。ポート露出も cloudflared の常駐も要らない。

非公開で使うアプリ（自分専用の業務ツール等）は **Cloudflare Access** を前段に置き、Google ログイン等で絞る。この場合アプリ側に認証を実装せず、「Access を通った要求だけが届く」前提で書く。その前提は README か CLAUDE.md に明記する。

---

## 5. Secrets

GitHub Actions で使う Secrets。値はリポに載せない。

| Secret | 用途 |
|---|---|
| `CLOUDFLARE_API_TOKEN` | Workers / Pages のデプロイ（Actions から打つ場合のみ） |
| `CLOUDFLARE_ACCOUNT_ID` | 同上 |
| `{APP}_API_KEY` | アプリ固有の外部 API キー |

**アプリの実行時に要る値は GitHub ではなく Cloudflare 側の環境変数・Secrets Store に置く。** GitHub Secrets はビルドとデプロイのための入れ物であって、実行環境の設定ではない。

Pages を GitHub 連携で運用する場合、この表の Cloudflare 系は不要になる。

---

## 6. 依存更新（Dependabot）

判断は PR 単位でなくルール単位で行う。個別 PR を見て毎回悩まない。

| 状況 | 扱い |
|---|---|
| minor/patch ＋ CI グリーン | 自動マージ（無条件） |
| major | 保留。溜まったら changelog を見て一括判断（マージ / close / 追従 Issue 化） |
| CI レッド | マージしない。close してよい提案として扱う（`@dependabot ignore this major version` で恒久無視可） |
| CI が無いリポ | 自動マージ禁止。グループ化して通知としてのみ使う |

構成は3点セット。雛形は `repo-standardize` の `reference/` にある。

1. `.github/dependabot.yml` — 全 ecosystem を weekly ＋ minor/patch グループ化。レジストリ系（npm/pip/composer/gomod）は `cooldown: default-days: 7` を付ける（サプライチェーン対策: 悪性リリースの多くは公開後数日で取り下げられる）
2. `.github/workflows/dependabot-auto-merge.yml` — major 以外に `gh pr merge --auto` を打つ
3. リポ設定 — `allow_auto_merge: true` ＋ main への ruleset（required status checks に CI のジョブ名、bypass に Repository admin / always。これで user の直 push は塞がない）

Compatibility score は他人のリポの CI 統計であり判断材料にしない。自リポの CI ＞ semver 種別 ＞＞ score。

注意: auto-merge のマージは `GITHUB_TOKEN` 起点のため、**マージ後の push トリガー workflow（deploy 等）は発火しない**。デモの依存反映は次の人手 push まで遅延するが許容する。即時反映が要るリポだけ PAT に切り替える。

---

## 7. 担当分離との接続

CI 自動デプロイを持つリポでは、`issue-driven-workflow.md` の担当表が変わる。

| 担当 | デプロイ時の作業 |
|---|---|
| CI / Cloudflare | main マージ後、自動でビルド・配信 |
| user | PR レビューとマージ、および Cloudflare 側の初回接続（ダッシュボード操作） |

Cloudflare のプロジェクト作成・GitHub 連携・独自ドメイン割当・Access のポリシー設定は GUI 操作であり user が行う。Agent はリポ内のファイル（`ci.yml`・`functions/`・`.env.example`）までを担当する。

内部ツールなど手動実行のリポは「user: 起動コマンド実行」のまま。
