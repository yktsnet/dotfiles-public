# TUI Toolchain & Development Environment

エージェントと人間が同一環境で作業するための、Nix で一元化された TUI 環境。

## Claude Code 連携ツール

この環境には Claude Code の利用体験を補う4つのツールが同梱されている。詳細は各リンク先を参照。

| ツール | 役割 | 詳細 |
|---|---|---|
| [tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager) | 走っている Claude Code セッションの一覧と、そのペインへの移動 | [§1 tmux](#1-tmux) |
| [hunk](https://github.com/modem-dev/hunk) | 差分レビュー用 TUI ビューア | [§2.6 Git](#26-gitgitsignsnvim) |
| [ctx](https://github.com/ctxrs/ctx) | セッション履歴を SQL でクエリ。Agent（Claude 自身）が `ctx-history-search` skill 経由で使う | [§3 補助 CLI](#3-claude-code-補助-cli) |
| [claude-history](https://github.com/raine/claude-history) | セッション履歴を fzf 風 TUI で検索・再開。人間が対話的に使う | [§3 補助 CLI](#3-claude-code-補助-cli) |

## キーの4層

キーは押す対象ごとに4つの層に分かれている。迷ったらここに戻る。

| 層 | プレフィックス | 対象 |
|---|---|---|
| tmux 層（外側） | `Alt` | ペイン・ウィンドウ・popup |
| Nvim ウィンドウ層（内側） | `s` | Nvim 内の分割・移動 |
| Nvim 機能層 | `Space`（Leader） | LSP・整形・コピー・UI トグル |
| 検索層 | `;` | Telescope のクイックアクセス |

`Alt` は Nvim の中にいても常に tmux に効く。分割・クローズ（`Alt+/`・`Alt+-`・`Alt+x`）も tmux のペインに作用するので、Nvim の中を分割・クローズするには `sv`・`ss`・`sx` を使う。例外は `Alt+j` / `Alt+k` で、Nvim の分割ウィンドウと tmux のペインを続けて巡る。

---

## 1. tmux

プレフィックスキーを使わず、`Alt` の単押しでペインとウィンドウを操作する。

### ペイン・ウィンドウ

| キー | 役割 |
|---|---|
| `Alt + /` | 垂直分割（左右） |
| `Alt + -` | 水平分割（上下） |
| `Alt + x` | ペイン / ウィンドウを閉じる |
| `Alt + j` / `Alt + k` | 次 / 前のペインへ巡回移動（Nvim の分割ウィンドウを含む） |
| `Alt + z` | ペインのズームをトグル |
| `Alt + t` | カレントパスを維持して新規ウィンドウ |
| `Alt + J` / `Alt + K` | 次 / 前のウィンドウへ |
| `Alt + s` | リポジトリを選び、そのリポ専用のセッションへ切替 |
| `Alt + d` | デタッチ |

### ターミナル・その他

| キー | 役割 |
|---|---|
| `Alt + p` | スクラッチターミナルを popup でトグル。ディレクトリごとにセッションを使い回すため、閉じても中身が残る |
| `Alt + v` | コピーモード（vi 操作。`v` か `Enter` で選択開始、`y` か `Enter` でコピー、`Ctrl+v` で矩形選択、`u` / `d` で半ページ移動） |
| `Alt + ;` | コマンドプロンプト（`sp` / `vs` / `q` のエイリアスあり） |
| `Alt + u` | 走っている Claude Code セッションのピッカーを開き、選んだペインへ移動。`macbook` / `linux-desktop` のみ |
| `Alt + m` | 走っている別セッションを選び、外から客観視する相談セッションを popup で起動。`macbook` / `linux-desktop` のみ |

### 設計上のポイント

* **OSC 52 透過型クリップボード同期**: `set-clipboard on` により、SSH 越しのリモート環境やコンテナ内からでも OS 側のクリップボードへ同期する。
* **Neovim 最適化**: True Color と波線アンダーライン（Undercurls）を有効化し、色彩再現性を担保。Focus events により Nvim の自動保存・外部変更検知が正常に動く。
* **Claude セッションの一覧と移動**: 起動はシェルの `c()` で今いるペインに行い、[tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager) のピッカー（`Alt + u`）で走っているセッションを一覧して移る。ステータスバーの右端には、各セッションの状態（入力待ち・待機・実行中）をリポ名のチップで並べる。

---

## 2. Neovim

`lazy.nvim` ベース。Leader キーは `Space`。

### 2.1 ウィンドウ・タブ

| キー | 役割 |
|---|---|
| `sv` / `ss` / `sx` | 垂直分割 / 水平分割 / 閉じる |
| `sh` `sj` `sk` `sl` | 左 / 下 / 上 / 右のウィンドウへ移動 |
| `Ctrl+w` + 矢印 | ウィンドウサイズ変更 |
| `te` | 新規タブ（`:tabedit`） |
| `Tab` / `Shift+Tab` | 次 / 前のタブへ |

### 2.2 ファイラー（oil.nvim）

ディレクトリを**通常のテキストバッファ**として開き、Vim の編集キーでファイル操作を行う。

| キー | 役割 |
|---|---|
| `-` / `Space e` | 現在ファイルの親ディレクトリを開く |
| `Space E` | CWD で開く |
| `dd` / `cw` | （Oil 内）削除マーク / リネーム |
| `cp` / `cr` | （Oil 内）カーソル位置の絶対 / 相対パスをコピー |
| `:w` | （Oil 内）変更を確定（実際の FS 操作） |
| `q` | （Oil 内）閉じる |

### 2.3 検索（telescope.nvim）

`fzf-native` 拡張（C 実装の高速ソーター）を利用。`;` のクイックアクセスと `Space` のルート指定検索の2系統。

| キー | 役割 |
|---|---|
| `;f` | カレントディレクトリのファイル検索（hidden 含む） |
| `;r` | カレントディレクトリ全文検索（hidden 含む） |
| `;;` | 前回のピッカーを再開 |
| `;e` | Diagnostics 一覧 |
| `;s` | Treesitter シンボル一覧（関数・変数等） |
| `;c` | LSP incoming calls（カーソル下の関数の呼び出し元） |
| `;t` | help タグ検索 |
| `\\` | 開いているバッファ一覧 |
| `Space f` / `Space g` | プロジェクトルート配下のファイル名検索 / 全文検索 |
| `Space F` / `Space G` | 複数ルート（`dotfiles` 等）のファイル名検索 / 全文検索 |

### 2.4 LSP・診断・整形

| キー | 役割 |
|---|---|
| `gd` | 定義元へジャンプ（Telescope 経由・常に新ウィンドウ） |
| `K` | ホバー情報（型・ドキュメント） |
| `Ctrl+j` / `Ctrl+k` | 次 / 前のエラー・警告へジャンプ |
| `Space di` | 行内のエラー・警告を浮き枠で表示 |
| `Space rn` | プレビュー付き一括リネーム（inc-rename.nvim） |
| `Space ca` | コードアクション（自動修正・インポート追加等） |
| `Space fm` | コード自動整形（conform.nvim） |
| `Space i` | Inlay Hints のトグル |

スタックは `lspconfig` + `mason.nvim` + `nvim-cmp` + `LuaSnip`。補完・シグネチャヘルプ・静的型チェックは自動で機能する。

### 2.5 編集

| キー | 役割 |
|---|---|
| `x` / `dw` | 1文字 / 単語を削除（ヤンクレジスタを汚さない） |
| `Space p` / `Space P` | レジスタ0（最後にヤンクしたもの）からペースト |
| `Space o` / `Space O` | 下 / 上に新行追加（インデントゴミを残さない） |
| `+`、`Ctrl+a` / `Ctrl+x` | インクリメント / デクリメント（bool・日付・semver 等も対応） |
| `g Ctrl+a` / `g Ctrl+x` | 連番インクリメント / デクリメント |
| `gcc` / `gc` | 行 / 選択範囲のコメントアウト切替（Neovim 組み込み） |

**レジスタを守る操作体系**が方針の中心にある。`x` と `dw` の削除をブラックホールレジスタへ送り、`Space p` でレジスタ0から貼ることで、コピペの途中で誤ってヤンク内容が上書きされる問題を防ぐ。

### 2.6 Git（gitsigns.nvim）

| キー | 役割 |
|---|---|
| `]c` / `[c` | 次 / 前の変更箇所（Hunk）へ |
| `Space hp` | Hunk のプレビュー |
| `Space hb` | カーソル行の Blame |

シェル側では `d` で差分レビュー用の TUI ビューア（[hunk](https://github.com/modem-dev/hunk)）を起動する。ワーキングツリー / 未 push のコミット / 直近コミット / 日付単位から対象を選べる（定義は `zsh/functions/git.sh`）。

### 2.7 コピー・バッファ・UI

| キー | 役割 |
|---|---|
| `Space cp` / `Space cr` | 現在ファイルの絶対 / 相対パスをコピー |
| `Space y` | ファイル名ヘッダー付きで内容全体をコピー |
| `Space bh` / `Space bu` | 非表示 / 名前なしバッファを一括クローズ |
| `Space z` | Zen Mode のトグル |
| `Space a` | Aerial（アウトライン）のトグル |
| `Space M` | Markdown のレンダリング表示（render-markdown.nvim）のトグル |
| `Space x` | ファイルを実行（`.py` → python3, `.sh` → bash） |

### 2.8 プラグイン構成の要点

網羅リストではなく、選定に理由のあるものを挙げる。

* **テーマ（poimandres.nvim）**: ダークブルーとティール基調。tmux のステータスバーと配色を揃えてある。
* **UI 刷新（noice.nvim + nvim-notify）**: コマンドライン・通知・ポップアップを置き換え、LSP ホバーにボーダーを付ける。フォーカスを失っている間の通知はシステム通知へ転送する。
* **分割時のファイル名表示（incline.nvim）**: 複数ウィンドウ分割時に各ウィンドウ右上へファイル名をフローティング表示。ステータスラインを1本に保ったまま、どのウィンドウが何かを判別できる。
* **差分の閲覧（codediff.nvim）**: `:CodeDiff` で差分を Nvim の中で開く。見つけた箇所から `gf` で実ファイルへ抜け、`Space cp` で取ったパスを Claude に渡せる。
* **カーソル位置の復元**: ファイルを開き直すと、前回カーソルがあった位置に戻る。
* **キーマップ案内（which-key.nvim）**: `Space` を押して待つと候補が画面下部に出る。上の4層モデルを覚えていなくても辿れる。

---

## 3. Claude Code 補助 CLI

過去の Claude Code セッション履歴を検索するための2つの CLI。どちらも「セッション履歴を検索する」点は共通だが、使い手が異なる。

* [ctx](https://github.com/ctxrs/ctx): セッション履歴を SQL でクエリできる形にインデックスする CLI。人間が直接叩くのではなく、Agent（Claude 自身）が `ctx-history-search` skill 経由で過去セッションを検索する用途で使う。
* [claude-history](https://github.com/raine/claude-history): 過去のセッションを fzf 風の TUI で検索・再開する CLI。`ctx` とは対照的に、人間が対話的に探す用途で使う。
