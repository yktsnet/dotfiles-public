## PR記録: feat: はてブ / Zenn / GitHub Trending の daily digest 一式を公開する
issue: 10 (10_daily-digest-publish.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/34
Merged: a157b097fb4b6ab5688edad76c1b43aa0b670ccb

## 変更内容
私物 `~/dotfiles` で毎日動いている digest 一式（はてブ IT ホットエントリと Zenn デイリートレンドを LLM で選別し、GitHub Trending 上位3件と合わせて Telegram へ流す。GitHub Actions で毎日1回実行）を dotfiles-public に反映した。

- `apps/zsh/hatenadigest.py`（新規）: 私物版から、資格情報の読み取りをファイルパス分岐から `os.environ.get()` のみに一本化、docstring の Discord → Telegram 修正、未使用の `subprocess` import 削除の3点を変更して移植
- `apps/zsh/githubtrending.py`（新規）: 同上3点の変更を入れて移植
- `apps/zsh/digest.yml.example`（新規）: 私物 `.github/workflows/digest.yml` をそのまま移植。`.github/workflows/` 配下には置かず（本リポでスケジュール実行させないため）、`apps/zsh/` に `.example` 拡張子で配置。先頭にコピー先パスと必要 secrets のコメントを追加
- `apps/zsh/README.md`: 冒頭を「フリート監視3本 + digest 2本」の構成に更新、表に2行追加、digest 用の節（選別する側/しない側の理由、Telegram Bot セットアップ手順、実行例、GitHub Actions で回す場合の注意）を追加

## 保証
- 2本のスクリプトは資格情報を環境変数からのみ読む → 目視確認（テストなし。本リポに Python のテスト基盤がなく、既存の `apps/zsh/*.py` 3本も同様にテストを持たないため）
- `TELEGRAM_BOT_TOKEN` / `TELEGRAM_CHAT_ID` 未設定時は送信をスキップして正常終了する → 目視確認（同上、テストなし）
- 公開ファイルに固有の接続情報を含まない → 目視確認 + grep（同上、テストなし）
- `digest.yml.example` は `.github/workflows/` 配下に置かないため本リポでスケジュール実行されない → ファイル配置で担保（`apps/zsh/digest.yml.example`）

## 静的確認結果
- `python3 -m py_compile apps/zsh/hatenadigest.py apps/zsh/githubtrending.py`: OK
- 資格情報の読み取り経路の grep（`SECRET_FILE|KISSFX|open(.*SECRET|subprocess`）: 0件ヒット。`os.environ.get` 経路のみ確認
- 固有情報（ドメイン実値・Tailscale IP・SSH ユーザ・アプリ固有値）の grep: 0件ヒット
- `digest.yml.example` が `.github/workflows/` 配下に無いことを確認（`apps/zsh/digest.yml.example` のみ、`.github/workflows/` には `ci.yml` と `dependabot-auto-merge.yml` のみ存在）
- `docs/guarantees.md` は本リポに存在せず、保証台帳の更新は対象外
- `git diff --name-only --cached`: apps/zsh/README.md, apps/zsh/digest.yml.example, apps/zsh/githubtrending.py, apps/zsh/hatenadigest.py（issue の対象と完全一致）
- `nix flake check` は対象外（Nix ファイル変更なし）

## 検証手順
実際の疎通確認（Telegram Bot トークンでの送信テスト）は user が自分の Bot トークンで行う。

```bash
ANTHROPIC_API_KEY=... TELEGRAM_BOT_TOKEN=... TELEGRAM_CHAT_ID=... python3 apps/zsh/hatenadigest.py
TELEGRAM_BOT_TOKEN=... TELEGRAM_CHAT_ID=... python3 apps/zsh/githubtrending.py
```
