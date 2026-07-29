---
name: app-demo-gif
description: ブラウザ UI アプリの README 用デモ GIF を Playwright（nix 経由）で録画・生成する。Web アプリの画面デモ・操作 GIF を作りたいとき、README にアプリの動きを載せたいときに使用する。ターミナル CLI のデモは VHS（.tape）の管轄であり本スキルは使わない。
manual: true
---

# app-demo-gif

ブラウザ UI の README デモ GIF を作る。位置づけはスクリーンショットの1つ上（静止画で伝わらない「操作→結果」の因果を見せる）。ターミナルは VHS、ブラウザは本スキル、と使い分ける。

## 0. 撮る前に決める（必須・録画より先）

対象リポの README（コアメッセージ）と主要フローを読み、以下を user に提示して確定させる。**指示なしに録り始めない。**

1. **示したいこと1文**: この GIF を見た人に何が伝わればよいか（例: 「フォーム入力が PDF になり、検索で見つかる」）。これが絵コンテの背骨。
2. **絵コンテ**: 場面列挙（例: ログイン → モーダルで入力 → 生成 → 自動プレビュー → 検索ヒット）。「示したいこと」に寄与しない場面は削る。
3. **上限秒数**: 既定 20 秒以下（30 秒を超える案は分割か削減）。
4. **出力仕様**: 既定 960px 幅・10fps・2MB 以下目標（実績: 18.8秒・1.4MB は README 掲載で体感上問題なし）。README のどこに挿すか（通常はコアメッセージ直下）。

## 1. 録画スクリプトを書く

Playwright（sync API）で `docs/record-app-demo.py` を書き、**リポに同梱する**（VHS の .tape 相当。再生成手順をヘッダの docstring に書く）。**`--dry-run` モードを必ず実装する**: 録画せず、場面の切れ目でスクリーンショットだけ撮る（演出用 sleep はスキップ）。実装型は `reference/record-app-demo.py` を参照。

playwright とブラウザが常設済みの環境（home-manager で `PLAYWRIGHT_BROWSERS_PATH` を設定済み等）では直接実行する:

```bash
python3 docs/record-app-demo.py
```

未整備の環境向けフォールバック（スクリプトの docstring にはこちらも書く）:

```bash
nix-shell -p python3Packages.playwright playwright-driver.browsers --run \
  'export PLAYWRIGHT_BROWSERS_PATH=$(nix-build "<nixpkgs>" -A playwright-driver.browsers --no-out-link); \
   python3 docs/record-app-demo.py'
```

型（要点のみ。完動する全体は `reference/record-app-demo.py` を参照 — ログイン → モーダル入力 → 生成 → 自動プレビュー → 検索の実例）:

```python
browser = p.chromium.launch(headless=False)  # 後述の理由でヘッド付き
ctx = browser.new_context(
    viewport={"width": 1280, "height": 800},
    record_video_dir="docs/video",
    record_video_size={"width": 1280, "height": 800},
)
```

### 落とし穴（実績あり）

- **PDF 表示があるなら `headless=False` 必須**。ヘッドレス Chromium は PDF ビューアを描画せず、プレビューが白紙で録れる。ヘッド付きは実行中ウィンドウが画面に出るので user に一言伝える。
- **ロケータは操作対象のコンテナに限定する**。`page.locator("form input")` はページ全体（検索ボックス等）を拾ってフィールドがずれる。モーダルなら `modal = page.locator("div.fixed.inset-0")` を起点にする。
- **状態遷移は `wait_for_selector` で待つ**（モーダル閉鎖は `state="detached"`）。sleep だけに頼ると失敗時に原因が読めない。
- 入力は `type(..., delay=40)` 程度で人間らしく。場面の切れ目に `time.sleep(1〜3)` の間を置く。
- 動画は context close 時に確定する。`ctx.close()` を必ず通す。

## 2. dry-run で場面を検証する（本録画より先・必須）

「全編録画 → フレーム抽出 → 目視 → 録り直し」は最も高価なループなので、ロケータ・遷移待ち・入力値の検証は録画前に済ませる。

```bash
python3 docs/record-app-demo.py --dry-run   # docs/video/dryrun-*.png に場面スクショ
```

スクショを目視し、絵コンテの各場面が正しく出ているか（フィールドずれ・白紙・未描画・エラー表示）を確認する。NG ならここでスクリプトを直して dry-run をやり直す（数秒で回る）。全場面 OK になってから本録画に進む。本録画は原則1回で終える。

## 3. 本録画 → webm 検証 → GIF 化

本録画後、**GIF 化の前に webm でフレーム検証する**（NG 時に palettegen 込みエンコードを無駄にしない）。GIF は再生して確認できないため、山場の秒数を狙って抜く。

```bash
ffmpeg -ss {秒} -i docs/video/*.webm -frames:v 1 /tmp/frame.png
```

チェック: 「示したいこと」の場面が映っているか / 入力値が結果（PDF 等）に着地しているか / dry-run では出なかった録画起因の崩れ（タイミングずれ等）がないか。

OK なら GIF 化する:

```bash
ffmpeg -i docs/video/*.webm \
  -vf "fps=10,scale=960:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=128[p];[s1][p]paletteuse=dither=bayer" \
  -loop 0 docs/app-demo.gif
```

- 2MB 超なら: fps を 8 に / 幅 800 に / 尺を削る、の順で調整。
- `docs/video/` は .gitignore に追加（中間生成物）。GIF とスクリプトは追跡する。

## 4. README に挿す

確定した挿入位置（既定: コアメッセージ直下）に alt テキスト付きで:

```markdown
![app demo: ログイン → 書類生成 → PDF プレビュー → 検索](docs/app-demo.gif)
```

## reference/

- `record-app-demo.py` — 完動実例（excel-kanri で 18.8秒・1.4MB の GIF を生成したもの）。`--dry-run` モード・ヘッド付き起動・モーダル限定ロケータ・`wait_for_selector` による遷移待ち・再生成手順の docstring を含む

## 5. 報告して止まる

GIF のサイズ・尺・確認したフレームの内容を報告する。コミットは user の指示があったときのみ。
