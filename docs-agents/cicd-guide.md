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
| **公開アプリ** | Web アプリ・ポートフォリオ作品 | GitHub Actions（型チェック → test → build） | 自ホストへ自動デプロイ → Cloudflare Tunnel でデモ公開 |
| **内部ツール** | データ処理スクリプト・自動化スクリプト・シェルコマンド | 任意（ローカル検証で代替可） | なし（ローカル実行 or dotfiles 経由で配布） |

公開アプリは外から見えるため、CI とデプロイを持つ。内部ツールは自分しか使わないため、`harness-guide.md` の層2（ローカル検証）で十分。

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
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4   # 言語に応じて差し替え
        with: { node-version: 24, cache: npm }
      - run: npm ci
      - run: npm run typecheck
      - run: npm test
```

内部ツールで CI を入れる場合も同じ構成。ただし多くの場合、Agent のローカル検証（構文チェック・ドライラン）で事足りるため、CI は省略してよい。

---

## 3. デプロイ（公開アプリ）

main への push をトリガーに、CI 通過後、Tailscale 経由で自ホストへ転送し再起動する。
Docker の有無で2型。

### 3-1. compose 型

GitHub Actions → Tailscale → scp → `docker compose up -d --build`。
Web アプリの大半はこの型。

```yaml
deploy:
  needs: test
  if: github.ref == 'refs/heads/main'
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - name: Connect to Tailscale
      uses: tailscale/github-action@v3
      with:
        oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
        oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
        tags: tag:ci
    - name: Sync source
      uses: appleboy/scp-action@v0.1.7
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        source: "."
        target: "~/apps/{project}/"
    - name: Up
      uses: appleboy/ssh-action@v1
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        script: |
          cd ~/apps/{project}
          docker compose up -d --build
```

### 3-2. バイナリ型

ビルド → scp → systemd restart。クロスコンパイル（Linux amd64）が必要な場合に使う。

```yaml
    - name: Build
      run: {cross-compile command}   # 例: GOOS=linux GOARCH=amd64 go build
    - name: Copy binary
      uses: appleboy/scp-action@v0.1.7
      with: { host: ${{ secrets.DEPLOY_HOST }}, ..., source: "{binary}", target: "/tmp/" }
    - name: Restart service
      uses: appleboy/ssh-action@v1
      with:
        host: ${{ secrets.DEPLOY_HOST }}
        username: ${{ secrets.DEPLOY_USER }}
        key: ${{ secrets.SSH_PRIVATE_KEY }}
        script: |
          sudo mv /tmp/{binary} /opt/{name}/{binary}
          sudo chmod +x /opt/{name}/{binary}
          sudo systemctl restart {name}
```

---

## 4. デモ公開（Cloudflare Tunnel）

公開アプリは自ホスト上で動作し、Cloudflare Tunnel 経由で `{subdomain}.{domain}` として公開する。
直接ポートを露出しないため、複数プロジェクトを同居させても外部からは個別ドメインに見える。

DNS ルート追加とトンネル ingress 設定はサーバー側の運用手順で実施する。ホスト名・トンネル ID・ポート割当などの固有値はリポに書かず、Secrets と運用ドキュメントで管理する。

---

## 5. Secrets

GitHub Actions で使う Secrets。値はリポに載せない。

| Secret | 用途 |
|---|---|
| `DEPLOY_HOST` | デプロイ先ホスト（Tailscale 経由） |
| `DEPLOY_USER` | デプロイ先ユーザー |
| `SSH_PRIVATE_KEY` | デプロイ先への SSH 秘密鍵 |
| `TS_OAUTH_CLIENT_ID` | Tailscale OAuth Client ID |
| `TS_OAUTH_SECRET` | Tailscale OAuth Secret |
| `{APP}_API_KEY` | アプリ固有の外部 API キー |

---

## 6. 担当分離との接続

CI 自動デプロイを持つリポでは、`issue-driven-workflow.md` の担当表が変わる。

| 担当 | デプロイ時の作業 |
|---|---|
| CI | main マージ後、test 通過 → 自動デプロイ |
| user | PR レビューとマージのみ |

内部ツールなど手動実行のリポは「user: 起動コマンド実行」のまま。
