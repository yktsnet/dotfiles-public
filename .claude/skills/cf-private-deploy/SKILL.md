---
name: cf-private-deploy
description: 個人用 Web アプリを Cloudflare Pages に載せ、Cloudflare Access（Google ログイン限定）で自分だけに閉じた状態で公開する。トークン発行以外は全て REST API で行い、ダッシュボードの GUI 操作を排する。アプリを初めて配信するとき、Access で保護するとき、pages.dev の穴を塞ぐときに使う。
disable-model-invocation: true
---

# cf-private-deploy

Cloudflare Pages + Access で、自分だけがログインできるアプリを配信する。

**GUI が要るのは Cloudflare アカウントにつき生涯2回だけ**（API トークンの初回発行と、GitHub 連携の初回認可）。それ以外を GUI でやろうとすると 20 手前後に膨れるので、必ず API に寄せる。

ダッシュボードのクリック経路は変わるが、REST API のエンドポイントは変わらない。手順を API で書くのは自動化のためだけでなく、手順書が腐らないためでもある。

## 0. 一度だけの準備

### 0-1. API トークン

Cloudflare は「最初の1本目だけはダッシュボードから」と明記している（2本目以降は API で作れる）。CLI での発行手段は無い。`wrangler login` の OAuth は Workers/Pages のスコープしか持たず、Access と DNS を触れないので代替にならない。

https://dash.cloudflare.com/profile/api-tokens → Create Token → Create Custom Token

| | | |
|---|---|---|
| Account | `Cloudflare Pages` | `Edit` |
| Account | `Access: Apps and Policies` | `Edit` |
| Account | `Access: Organizations, Identity Providers, and Groups` | `Read` |
| Zone | `DNS` | `Edit` |
| Zone | `Zone` | `Read` |
| User | `API Tokens` | `Edit` |

`Access: Apps and Policies` だけでは identity provider の一覧を引けない。3行目が無いと `/access/identity_providers` が `Authentication error` を返す。

**トークンは2本に分ける。** 上の6行を持つ管理用を1本作り、そこから API で作業用（`User: API Tokens` を除いた5行）を発行する。日常の作業には作業用だけを使う。

理由は Cloudflare の制約で、**API から作るトークンにはトークン管理権限を付けられない**（`1001 sub-token is not allowed to have permissions to manage other tokens`）。管理用は必ずダッシュボード発行になるので、一度作ったら秘密管理の仕組みへ寝かせて触らない。作業用を漏らしても、管理用があれば API だけで作り直せる。

既存トークンに `User` スコープを後から追加することはできない（編集画面に `User` の選択肢が出ない）。**作成時に入れ忘れたら作り直すしかない。**

`Global API Key` は使わない。全権限・無期限で、失効させるとアカウント全体が壊れる。

発行したら**手元の秘密管理（sops 等）へ入れて永続化する**。ここを毎回やり直すから面倒に感じる。1本入れておけば以後のリポは GUI ゼロで済む。

### 0-2. GitHub 連携

Pages の Git 連携は Cloudflare の GitHub App の認可が要り、これはブラウザでしか通せない。**アカウントで一度通せば以後のリポは API から選べる。**

### 0-3. 環境変数

```bash
export CF_API_TOKEN=...        # 秘密管理から取り出す
export CF_ACCOUNT_ID=...       # dash の URL に入っている
export CF_ZONE_ID=$(curl -s "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "Authorization: Bearer $CF_API_TOKEN" | jq -r '.result[0].id')
api() { curl -s -H "Authorization: Bearer $CF_API_TOKEN" -H 'content-type: application/json' "$@"; }
```

## 1. Pages プロジェクト

```bash
api -X POST "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects" \
  -d "$(jq -n --arg n "$PROJECT" --arg owner "$OWNER" --arg repo "$REPO" '{
    name: $n, production_branch: "main",
    source: { type: "github", config: {
      owner: $owner, repo_name: $repo, production_branch: "main",
      deployments_enabled: true }},
    build_config: { build_command: null, destination_dir: "public", root_dir: "" }
  }')" | jq '.success, .errors'
```

ビルドステップの無い素の静的配信なら `build_command` は `null`、`destination_dir` は公開ディレクトリ。

## 2. 環境変数

`deployment_configs.production` を PATCH する。**`preview` には入れない**。入れると誰でも作れるプレビュー URL から本番データを触れる。

```bash
api -X PATCH "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/pages/projects/$PROJECT" \
  -d '{ "deployment_configs": { "production": { "env_vars": {
    "SOME_PLAIN": { "type": "plain_text", "value": "..." },
    "SOME_TOKEN": { "type": "secret_text", "value": "..." }
  }}}}' | jq '.success, .errors'
```

秘匿値は必ず `secret_text`。`plain_text` は後から平文で読める。

**環境変数はデプロイ時に読まれる。** 入れただけでは反映されないので、再デプロイするまで API は動かない。main へ push すれば済む。

## 3. カスタムドメインと DNS

**ここが本題。`<project>.pages.dev` は Access で保護できない。** Cloudflare Access の self-hosted アプリは自分が所有するゾーンにしか適用できず、`pages.dev` は Cloudflare 所有だからである。自前ドメインの割り当ては省略できない。

```bash
api -X POST ".../accounts/$CF_ACCOUNT_ID/pages/projects/$PROJECT/domains" \
  -d "{\"name\":\"$HOSTNAME\"}"

api -X POST "https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records" \
  -d "$(jq -n --arg n "$HOSTNAME" --arg c "$PROJECT.pages.dev" \
    '{type:"CNAME", name:$n, content:$c, proxied:true}')"
```

`proxied: true` は必須。オレンジクラウドを通らない要求は Access を経由しない。

## 4. pages.dev を塞ぐ

カスタムドメインを Access で守っても、`<project>.pages.dev` と `<hash>.<project>.pages.dev` は認証なしで開いたままになる。**アプリ側で塞ぐ以外に手段が無い。**

Pages Functions なら `functions/_middleware.js` に置く。

```js
export const onRequest = ({ request, next }) => {
  const host = new URL(request.url).hostname;
  if (host === 'pages.dev' || host.endsWith('.pages.dev')) {
    return new Response('not found', { status: 404 });
  }
  return next();
};
```

ドメイン実値を書かずに済むので、公開リポでもそのまま置ける。Pages の Settings にある `Access Policy` はプレビューにしか効かず、本番の `pages.dev` は塞げない。

## 5. Access アプリとポリシー

```bash
APP=$(api -X POST ".../accounts/$CF_ACCOUNT_ID/access/apps" \
  -d "$(jq -n --arg d "$HOSTNAME" --arg n "$PROJECT" '{
    name:$n, domain:$d, type:"self_hosted", session_duration:"24h",
    allowed_idps:[], auto_redirect_to_identity:false }')" | jq -r '.result.id')

api -X POST ".../accounts/$CF_ACCOUNT_ID/access/apps/$APP/policies" \
  -d "$(jq -n --arg e "$EMAIL" '{
    name:"owner only", decision:"allow", include:[{email:{email:$e}}] }')"
```

`allowed_idps: []` は「設定済みの IdP をすべて許可」の意味で、特定の IdP id を調べずに済む。個人用途で IdP が Google 1つなら、これで十分。

**既にこのアカウントで動いている Access アプリがあれば、そこから設定を写すのが速い。** `GET /access/apps/{id}` と `.../policies` は `Access: Apps and Policies` だけで読めるので、IdP の権限が無くても実績のある構成をそのまま複製できる。

Google が identity provider に無ければ、そこだけ Zero Trust の設定画面で有効化する（アカウントにつき一度）。

## 6. 検証

**シークレットウィンドウで確認する。** 通常のウィンドウは既存の Access セッションを持っていて、素通りを見逃す。

- `https://$HOSTNAME` → Google ログインを求められる
- `https://$PROJECT.pages.dev` → 404
- ログイン後、書き込み操作が保存先まで届く

3つ揃うまで運用を始めない。

## トークンを入れ替える

漏らしたとき、あるいは定期的に。`User: API Tokens: Edit` があれば API だけで完結する。入れ替えるのは作業用だけで、管理用を使って回す。

1. 管理用の権限定義を読む（`GET /user/tokens/{admin_id}`）
2. そこから `API Tokens` の permission group を除いて `POST /user/tokens`
3. 新しい作業用で `verify` と実際の操作（Pages・Access・DNS）が通ることを確認
4. 旧作業用を消す（`DELETE /user/tokens/{old_id}`）
5. 新しい値を秘密管理へ収める

**新しい値を配布し終えてから、古い値を破棄する。** 順序を誤ると、入れ替えの途中でどちらの値でも操作できない状態になる。平文を扱う必要がある場合はディスクに残さない場所（RAM ディスク等）で扱う。

## 落とし穴

- **トークンの TTL 切れ。** 短命トークンで組んだ構成を後から直せなくなる。秘密管理に入れる本命は期限を長めに取り、使い捨てが要る場面だけ短命を別に作る
- **`preview` 環境変数。** 本番と同じ値を入れると、プレビュー URL が本番データへの裏口になる
- **`proxied: false`。** DNS を灰色クラウドで作ると Access を素通りする
- **秘匿値をチャットや commit message に貼る。** 人が読む地の文では実値の代わりにプレースホルダを使う。トークンを user から受け取るときは値を言わせず、ファイルに置いてもらってパスだけ聞く
- **トークンに `User: API Tokens: Edit` を入れ忘れる。** 漏らした後で気づくと、ローテーションのためだけにダッシュボードへ戻ることになる
