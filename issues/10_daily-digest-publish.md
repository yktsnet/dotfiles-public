## はてブ / Zenn / GitHub Trending の daily digest 一式を公開する
id: 10
branch-slug: daily-digest-publish
github_issue:
status: open
type: feat
対象:
- apps/zsh/hatenadigest.py (新規)
- apps/zsh/githubtrending.py (新規)
- apps/zsh/digest.yml.example (新規)
- apps/zsh/README.md
内容: 私物 `~/dotfiles` で毎日動いている digest 一式（はてブ IT ホットエントリと Zenn デイリートレンドを LLM で選別し、GitHub Trending 上位3件と合わせて Telegram へ流す。GitHub Actions で毎日1回実行）を dotfiles-public に反映する。Zenn 記事「月0.28ドルで、はてブと Zenn の AI・開発の記事だけがスマホに届く」から読者が実装を追えるようにするのが目的で、記事側には断片しか載せない。公開にあたり、資格情報の読み取りを環境変数のみに一本化し、私物の secret ファイルパス分岐を落とす。
確認: `python3 -m py_compile apps/zsh/hatenadigest.py apps/zsh/githubtrending.py`（構文チェック）、目視確認（`digest.yml.example` の YAML 構文、README の表と既存3本の記述との整合、資格情報の読み取り経路に環境変数以外が残っていないこと）。`nix flake check` は対象外（Nix ファイル変更なし）。実際の疎通確認は user が自分の Bot トークンで行う。

---

### 保証
- 新たに宣言する保証:
  - 2本のスクリプトは資格情報（`ANTHROPIC_API_KEY` / `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID`）を環境変数からのみ読む。ファイルパスを受け取って中身を読む経路を持たない
  - `TELEGRAM_BOT_TOKEN` または `TELEGRAM_CHAT_ID` が未設定のとき、送信をスキップして正常終了する（例外で落ちない）
  - 公開するファイルに固有の接続情報（実ドメイン・本番絶対パス・Tailscale IP / SSH ユーザ・アプリ固有の環境変数名）を含まない
  - `digest.yml.example` は `.github/workflows/` 配下に置かないため、本リポの Actions ではスケジュール実行されない
- 維持する保証: なし（本リポに既存の digest 関連コードはなく、`docs/tui_environment.md` の保証範囲にも触れない）

**テスト欠落についての確認事項**: 上記のうち上3つは外部から観測可能な契約だが、本リポに Python のテスト基盤がなく、裏付けテストを対象に含めていない。`python3 -m py_compile` は構文チェックのみで、資格情報の読み取り経路は目視確認になる。既存の `apps/zsh/*.py` 3本も同様にテストを持たない。テストを本 Issue に含めるか、この形で見送るかを裁可時に判断されたい。

### 背景

私物 `~/dotfiles` 側の構成は次のとおり。

- `apps/zsh/hatenadigest.py` — はてブ IT カテゴリの RSS から20件、Zenn の日次トレンド API から20件を取り、`claude-haiku-4-5` に「AI や開発に関連するものだけ選べ」と投げて JSON で受け、Telegram へ送る。前日に送った URL を保存して重複を除外する
- `apps/zsh/githubtrending.py` — GitHub Trending の HTML を `HTMLParser` で解析し、上位3件を Telegram へ送る。LLM は通さない
- `.github/workflows/digest.yml` — 毎日 UTC 14:00（JST 23:00）に上記2本を順に実行し、前日 URL の保存先を `actions/cache` で持ち越す

Zenn 記事側には、プロンプト・JSON パースのフォールバック・`actions/cache` のキー設計といった断片しか載せない。全文と、Telegram Bot のセットアップ手順は本リポが持つ。

### 仕様

#### apps/zsh/hatenadigest.py（新規）

コピー元: `~/dotfiles/apps/zsh/hatenadigest.py`（200行）。次の3点を変更して移植する。

**1. 資格情報の読み取りを環境変数のみにする**

正本の冒頭は、私物のアプリ名を含む環境変数でファイルパスを受け取り、そのファイルを1行ずつ読んで `KEY=VALUE` を拾う分岐を持つ。この分岐ごと落とし、`os.environ.get()` だけにする。公開リポにアプリ固有の名前を出さないための変更であり、GitHub Actions 側は元から環境変数で渡しているので挙動は変わらない。ローカル実行時は user が自分でエクスポートする。

**2. docstring を実態に合わせる**

正本の docstring は「posts the digest to a Discord webhook」と書いてあるが、2026年7月に Telegram へ移行済みで実装と食い違っている。Telegram に直す。

**3. 未使用 import を落とす**

`subprocess` が import されているが使われていない。

それ以外（プロンプト、タイトルを15文字に切って投げる処理、JSON パース失敗時の再エスケープ、前日 URL の保存と除外、4000字でのチャンク分割）はそのまま移植する。前日 URL の保存先 `~/.local/share/hatebu/last_urls.txt` は固有情報を含まないためそのままでよい。

#### apps/zsh/githubtrending.py（新規）

コピー元: `~/dotfiles/apps/zsh/githubtrending.py`（129行）。変更点は `hatenadigest.py` と同じ3点（資格情報を環境変数のみに、docstring の Discord → Telegram、未使用 import の `subprocess` を落とす）。

`TrendingParser` と上位3件に絞る処理はそのまま移植する。

#### apps/zsh/digest.yml.example（新規）

コピー元: `~/dotfiles/.github/workflows/digest.yml`（35行）。内容はそのままでよい（固有情報なし）。

**`.github/workflows/` 配下には置かない。** 置くと本リポでもスケジュール実行が走り、secrets 未設定で毎日失敗して Actions が赤くなる。`apps/zsh/` に `.example` 拡張子で置き、利用者が自分のリポジトリの `.github/workflows/digest.yml` としてコピーする形にする。ファイル先頭に、コピー先のパスと必要な secrets（`ANTHROPIC_API_KEY` / `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID`）を示すコメントを足す。

#### apps/zsh/README.md

現状は冒頭で「フリート運用の骨格になる3本を収めている」と書き、表に3本を並べている。次の3点を更新する。

**1. 冒頭の説明**

「3本」という数と「フリート運用の骨格」という括りが実態と合わなくなる。フリート監視の3本と digest の2本という2系統が入る形に書き直す。既存の文体（ですます調を使わない簡潔な地の文）を保つこと。

**2. 表に2行追加**

既存3行と同じ書式で追記する。

| ファイル | 役割 |
| --- | --- |
| `hatenadigest.py` | はてブ IT と Zenn デイリーから計40件を取り、Claude Haiku に AI・開発関連のものだけ選ばせて Telegram へ送る |
| `githubtrending.py` | GitHub Trending 上位3件を取り、選別せずそのまま Telegram へ送る |

**3. digest 用の節を追加**

`## リモートへ配らない` と `## inject.py` に続く形で、digest の節を1つ立てる。既存2節は「そのスクリプト固有の判断」を1つずつ説明する構成なので、それに倣う。次を含めること。

- **選別する側としない側を分けている理由**: はてブと Zenn は件数が多く関心外が混ざるので Haiku に絞らせる。GitHub Trending は英語圏のプロジェクトが中心で、分野を絞らずに眺めることに価値があるため選別を通さない
- **Telegram Bot のセットアップ手順**: BotFather で Bot を作ってトークンを得る、作った Bot に一度何か話しかける、`https://api.telegram.org/bot<TOKEN>/getUpdates` を叩いて `chat_id` を取る、という3ステップ。実トークンや実 chat_id は書かず `<TOKEN>` 等のプレースホルダで示す
- **実行例**: 環境変数を渡してローカルで実行する形。`fleet_monitor.py` の `FLEET=...` の例と同じ書式にする

```bash
ANTHROPIC_API_KEY=... TELEGRAM_BOT_TOKEN=... TELEGRAM_CHAT_ID=... python3 apps/zsh/hatenadigest.py
```

- **GitHub Actions で回す場合**: `digest.yml.example` を自分のリポジトリの `.github/workflows/` にコピーし、3つの secrets を登録する。前日 URL の持ち越しに `actions/cache` を使っており、7日間実行がないとキャッシュが失効してその日だけ重複が出ること

`apps/zsh/README.md` に英語版はないため、英訳は不要（ルート `README.md` / `README.en.md` は `fleet_monitor.py` にしか触れておらず、今回は変更しない）。

### 実装順序

1. `apps/zsh/hatenadigest.py`（新規、3点の変更を入れて移植）
2. `apps/zsh/githubtrending.py`（新規、同上）
3. `python3 -m py_compile` で2本の構文確認
4. 資格情報の読み取り経路を grep して、環境変数以外が残っていないことを確認
5. `apps/zsh/digest.yml.example`（新規、先頭コメント追加）
6. `apps/zsh/README.md`（冒頭・表・節の追加）
