---
name: vhs-demo
description: ターミナル CLI の README 用デモ GIF を VHS（.tape）で設計・生成する。CLI モジュールのデモ GIF を作る・作り直すとき、demo.tape を書くときに使用する。ブラウザ UI のデモは app-demo-gif の管轄であり本スキルは使わない。
manual: true
---

# vhs-demo

CLI デモ GIF を VHS で作る。`.tape` をリポに同梱し、`nix-shell --run 'vhs path/to/demo.tape'` で再生成できる状態を保つ（vhs は home.nix 導入済み）。

## 0. 撮る前に決める（必須・tape を書くより先）

対象モジュールの README・コードを読み、以下を確定させる。**これが決まっていない tape は「コマンドを順に打つだけの映像」になり、作る意味がない。**

1. **示したいこと1文**: この GIF から何が読み取れればよいか（例: 「YAML の `セル番地: 項目名` に従い、JSON の値が該当セルに流し込まれる」）。
2. **絵コンテ**: 場面列挙。**before/after の対比を必ず含める**（実行前の状態 → 実行 → 同じ場所の変化）。1文に寄与しない場面は削る。
3. **尺目安: 約10秒**（±2秒程度は可。厳密に切り詰めるより対比の見やすさを優先する）。Sleep 合計 + タイプ時間（文字数 × TypingSpeed）で事前に概算する。約10秒に収まるのは実質「before → 実行 → after」の3場面のみ。大きく超えるのは示したいことが2つ以上ある兆候であり、GIF を分けるか場面を捨てる。

## 1. tape の規範

- **ナレーションはコメント行**（`Type "# ..."`）で冒頭に1行だけ（= 示したいこと1文）。場面ごとの解説は入れない（尺を食う）。
- **コマンドは短く**。`.venv/bin/python` のような長いパスは冒頭で `alias py=...` を張って画面から消す。タイプが長いコマンドは `TypingSpeed` を局所的に速める（`Set TypingSpeed 10ms` → 打鍵後に戻す）か、`Hide`〜`Show` で仕込む。
- **before/after は同じ形式で見せる**（例: 同じセルの値を実行前後で print する）。差分が視覚的に対比できることが本体。
- **モジュール境界を壊さない**: 汎用モジュールのデモが上位層（app 等）を import するコマンドを含めない。デモ用の `--exec` は `echo` 等の自己完結コマンドにする。
- デモ素材（mapping・data 等）は最小に刈り込む（3項目程度。画面で全体が一瞥できる量）。
- `Set` 値（FontSize/Width/Theme）はリポ内の既存 tape に合わせる。

## 2. レンダリング前に素で流す（必須）

VHS は 10 秒の tape でも生成に 1〜2 分かかるため、コマンドの試行錯誤を tape の再生成で回さない。tape に書くコマンド列を先に素の bash で実行し、before/after の出力・エラーの有無・絶対パス（ホームディレクトリ）の露出を確認してから tape に固める。tape 化以降の直しは Set 値・間・タイプ演出の範囲に収まっているのが正常で、コマンド自体を tape 上で直し始めたらこの工程に戻る。

## 3. 生成する

```bash
nix-shell --run 'vhs packages/<mod>/demo.tape'
```

前提（Gotenberg・venv 等）が要る場合は tape 冒頭のコメントに明記する。

## 4. 検証する（必須）

尺とサイズを実測し、フレーム抽出で**目視**確認する。

```bash
ffmpeg -i packages/<mod>/demo.gif 2>&1 | grep Duration   # 約10秒か
ffmpeg -ss {秒} -i packages/<mod>/demo.gif -frames:v 1 /tmp/frame.png
```

チェック: 約10秒か / 「示したいこと」の1文が映像から読み取れるか / before/after の対比が映っているか / エラー・失敗出力・**行の折り返し崩れ・絶対パス（ホームディレクトリ露出）**が映り込んでいないか。NG なら tape を直して再生成する。

## 実証済みの落とし穴

- コマンド名は **`Hide` / `Show`**。`Hidden` は parser エラーになる（recording failed）。
- 行末に `# 解説` を足すと画面幅を超えて折り返し、行頭に断片が化けて映る。インラインコメントは入れない。
- macOS の watchdog（FSEvents）はイベントを**絶対パス**で返す。ログや exec 出力に `/Users/{user}/...` が映り込むツールは、デモ前にツール側で cwd 相対化するのが正道（tape 側では隠せない）。
- venv 前提の tape は nixpkgs 更新で venv が壊れると黙って素の python で走る。生成前に `python -m pytest` 等で venv の生存確認をする。

## reference/

- `example-before-after.tape` — before/after 対比型（template_fill: 空セル → 実行 → 値着地）。Hide 仕込み・Type@ 加速・cells ヘルパ関数の実例
- `example-background-watcher.tape` — バックグラウンド常駐型（watch_convert: watcher 起動 → 保存検知 → デバウンス実証）

## 5. 報告して止まる

各 GIF の「示したいこと」1文・実測尺・サイズと、確認したフレームの内容を報告する。コミットは user の指示があったときのみ。
