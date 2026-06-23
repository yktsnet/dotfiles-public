# TUI Toolchain & Development Environment

エージェントと人間が同一環境で作業を行うための、Nixで一元化されたTUI（Text User Interface）環境の詳細設定です。

---

## 1. Neovim (IDE & Editor)

`lazy.nvim` プラグインマネージャをベースに構築された、ポータブルで高度にモジュール化された設定。
人間だけでなくAIエージェントにとっても直感的に操作でき、日常的な開発とAI協調ワークフローの双方に最適化されています。

### 1.1 主要機能とプラグイン構成

#### 🎨 見た目・UI・テーマ (UI & Visuals)
* **テーマ ([poimandres.nvim](https://github.com/olivercederborg/poimandres.nvim))**: ダークブルーとティールを基調とした、目に優しく洗練されたモダンな配色。
* **ステータスライン ([lualine.nvim](https://github.com/nvim-lualine/lualine.nvim))**: 現在の編集モード、ファイル情報、Gitブランチ、LSPステータス等を美しく可視化。
* **UI刷新 ([noice.nvim](https://github.com/folke/noice.nvim) + [nvim-notify](https://github.com/rcarriga/nvim-notify))**: コマンドライン・通知・ポップアップを全面刷新。フォーカスを失った時にシステム通知として転送し、LSPホバーにボーダー表示。
* **分割ウィンドウのファイル名表示 ([incline.nvim](https://github.com/b0o/incline.nvim))**: 複数ウィンドウ分割時に各ウィンドウ右上にファイル名をフローティング表示。
* **集中モード ([zen-mode.nvim](https://github.com/folke/zen-mode.nvim))**: `<leader>z` でステータスライン・サイドバーを非表示にしてコードだけを表示。
* **通知・インジケーター ([fidget.nvim](https://github.com/j-hui/fidget.nvim))**: 画面右下に LSP 起動・インデックス進捗などを控えめにポップアップ表示。
* **UI改善 ([dressing.nvim](https://github.com/stevearc/dressing.nvim))**: Neovim標準のインプット窓や選択メニューを、使いやすいモダンなフローティング窓へ拡張。

#### 📂 ファイル操作・ナビゲーション (Files & Navigation)
* **Yazi 密結合 ([yazi.nvim](https://github.com/mikavilpas/yazi.nvim))**:
  * `<leader>e` で開いているファイルのディレクトリ、`<leader>E` でプロジェクトルート (CWD) を起点に、ターミナルファイラー Yazi をフローティング窓で起動します。
* **バッファ型編集 ([oil.nvim](https://github.com/stevearc/oil.nvim))**:
  * `-` キーでファイルの親ディレクトリを通常のテキストバッファとして開きます。ファイルやフォルダの作成・リネーム・削除を、通常の Vim 編集キー（`dd` や `cw` など）で行い、`:w` で一括保存・適用できます。
* **あいまい検索 ([telescope.nvim](https://github.com/nvim-telescope/telescope.nvim))**:
  * `fzf-native` 拡張（C言語製高速ソーター）を利用。プロジェクトルート検索（`<leader>f/g`）と、craftzdog 流クイックアクセス（`;f` `;r` `\\` `;;` `;e` `;s` `;c`）の2系統を搭載。

#### 💻 コーディング・LSP (Coding & Language Server)
* **構文解析 ([nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter))**: 高度なシンタックスハイライト、インデント調整、コードブロック選択を提供。
* **LSPスタック**: `lspconfig` + `mason.nvim` + `nvim-cmp` + `LuaSnip` の組み合わせ。
  * 自動補完、関数の定義元ジャンプ（Telescope経由・常に新ウィンドウ）、シグネチャヘルプ、静的型チェックが自動で機能します。
* **プレビュー付きリネーム ([inc-rename.nvim](https://github.com/smjonas/inc-rename.nvim))**: `<leader>rn` で変更後の名前をプレビューしながらリネーム。
* **インクリメント強化 ([dial.nvim](https://github.com/monaqa/dial.nvim))**: `<C-a>/<C-x>` が数値だけでなく bool・日付・semver・`let/const` トグルにも対応。
* **カラーコード表示 ([nvim-highlight-colors](https://github.com/brenoprata10/nvim-highlight-colors))**: コード中の `#hex`、`hsl()`、`rgb()`、Tailwind クラスを実際の色で背景着色。
* **自動整形 ([conform.nvim](https://github.com/stevearc/conform.nvim))**: ファイル保存時に適切なフォーマッターを自動実行し、コードスタイルを統一。
* **コメントアウト ([comment.nvim](https://github.com/numToStr/Comment.nvim))**: `gcc`（行単位）や `gc`（選択範囲）で素早くコメントアウト可能。
* **構造アウトライン ([aerial.nvim](https://github.com/stevearc/aerial.nvim))**: `<leader>a` でクラスや関数の一覧をサイドバーに表示し、ジャンプ可能。

#### 🔄 ワークフロー自動化 (Workflow Automation)
* **レジスタを守る操作体系**: `x`・`<leader>d`・`<leader>c` でのテキスト削除・変更はブラックホールレジスタへ送り、`<leader>p` で最後にヤンクしたもの（レジスタ0）を確実にペースト。コピペ中に誤って上書きされる問題を防止。
* **hjkl 連打トレーニング (discipline)**: `hjkl` を連続10回以上押すと "Hold it Cowboy! 🤠" と警告を出し、モーション（`5j` 等）の使用を促す。
* **最後に開いていたファイルの自動復元**:
  * 引数なしで Neovim を起動した際、グローバルで最後に開いていた有効なファイルを自動的に開き、最後にカーソルがあった行から再開します（一時ファイルやコミットメッセージは自動で除外されます）。
* **カーソル位置の自動復元**:
  * 以前開いたことのあるファイルを開き直した際、自動的に**前回閉じたときのカーソル位置に戻る**自動コマンドが組み込まれています。
* **バッファ管理 ([close-buffers.nvim](https://github.com/kazhala/close-buffers.nvim))**: `<leader>th` / `<leader>tu` で不要なバッファを一括クローズ。
* **キーマップ案内 ([which-key.nvim](https://github.com/folke/which-key.nvim))**:
  - `Space` を押してしばらく待つと、入力可能なキー操作の一覧が画面下部にポップアップ表示されます。

#### 🐙 Git & ターミナル (Git & Terminal)
* **シームレスな境界移動 ([vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator))**: Neovimのウィンドウ分割とTmuxのペインをシームレスに行き来。
* **差分レビュー ([difit](https://github.com/yoshiko-pg/difit))**: シェルで `d` を打つとメニューが出て、ワーキングツリー / ブランチ全体（PR 相当）/ 単一コミット / コミット間から対象を選び、ブラウザベースのビューアで差分を開きます（定義は `zsh/functions/git.sh` の `d()`）。
* **差分表示 ([gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim))**: 変更箇所の差分を行番号の左隣にカラーマーカーでリアルタイム表示。
* **ターミナル管理 ([toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim))**:
  * `\` キーでフローティングターミナルをトグル起動。選択範囲のコード（Visualモードで `<leader>ts`）やカーソル行（`<leader>tl`）をターミナルに直接送信して実行できます。

---

### 1.2 Neovim キーマップ一覧

**Leader キー** は **`Space`** にマッピングされています。

#### レジスタ・テキスト操作 (craftzdog 流)
| キーマップ | モード | 役割 |
|---|---|---|
| `x` | Normal | 1文字削除（ヤンクレジスタを汚さない） |
| `dw` | Normal | 単語を後方削除（ヤンクレジスタを汚さない） |
| `<leader>p` (`Space p`) | Normal/Visual | **レジスタ0**（最後ヤンク）からペースト |
| `<leader>P` (`Space P`) | Normal | **レジスタ0**から前方ペースト |
| `<leader>c` (`Space c`) | Normal/Visual | ブラックホールへの change（ペーストバッファを保護） |
| `<leader>d` (`Space d`) | Normal/Visual | ブラックホールへの delete（ペーストバッファを保護） |
| `+` | Normal | 数値インクリメント（dial.nvim 拡張） |
| `<C-a>` / `<C-x>` | Normal | インクリメント/デクリメント（bool・日付・semver 対応） |
| `<leader>o` / `<leader>O` | Normal | 下/上に新行追加（インデントゴミを残さない） |
| `<C-a>` | Normal | 全選択 (`gg<S-v>G`) |

#### ウィンドウ・タブ操作
| キーマップ | モード | 役割 |
|---|---|---|
| `ss` | Normal | 水平分割（上下） |
| `sv` | Normal | 垂直分割（左右） |
| `sh` / `sj` / `sk` / `sl` | Normal | 左/下/上/右のウィンドウへ移動 |
| `<C-w><矢印>` | Normal | ウィンドウサイズ変更 |
| `te` | Normal | 新規タブで開く |
| `<Tab>` / `<S-Tab>` | Normal | 次/前のタブへ |
| `Alt + 矢印キー` | Normal | Neovim ウィンドウまたは隣の Tmux ペインへ移動 |
| `Alt + /` / `Alt + -` | Normal | 垂直/水平分割 |
| `Alt + x` | Normal | ウィンドウ/ペインを閉じる |

#### ファイラー・検索 (Filer & Finder)
| キーマップ | モード | 役割 |
|---|---|---|
| `<leader>e` (`Space e`) | Normal | **開いているファイルのディレクトリ**で Yazi を起動 |
| `<leader>E` (`Space E`) | Normal | **プロジェクトの作業ディレクトリ (CWD)** で Yazi を起動 |
| `-` | Normal | 現在のファイルの**親ディレクトリ**を Oil バッファで開く |
| `<leader>f` / `<leader>F` | Normal | プロジェクトルート / 複数ルートのファイル名検索 |
| `<leader>g` / `<leader>G` | Normal | プロジェクトルート / 複数ルートの Grep 検索 |
| `;f` | Normal | カレントディレクトリのファイル検索（hidden 含む） |
| `;r` | Normal | カレントディレクトリ全文検索（hidden 含む） |
| `\\` | Normal | 開いているバッファ一覧 |
| `;;` | Normal | 前回の Telescope ピッカーを再開 |
| `;e` | Normal | Diagnostics 一覧 |
| `;s` | Normal | Treesitter シンボル一覧（関数・変数等） |
| `;c` | Normal | LSP incoming calls（カーソル下の関数の呼び出し元） |
| `;t` | Normal | help タグ検索 |

#### LSP 開発支援 (LSP)
| キーマップ | モード | 役割 |
|---|---|---|
| `gd` | Normal | カーソル下のシンボルの**定義元へジャンプ**（Telescope経由・常に新ウィンドウ） |
| `K` | Normal | カーソル下のシンボルの**ホバー情報（型・ドキュメント）の表示** |
| `<leader>rn` (`Space rn`) | Normal | **プレビュー付き**一括リネーム（inc-rename） |
| `<leader>ca` (`Space ca`) | Normal | **コードアクション**（自動修正やインポート自動追加など）の実行 |
| `<leader>di` (`Space di`) | Normal | 行内のエラー・警告の詳細をフローティング表示 |
| `<leader>i` (`Space i`) | Normal | Inlay Hints のトグル |
| `<C-j>` | Normal | 次のエラー・警告へジャンプ |

#### バッファ管理
| キーマップ | モード | 役割 |
|---|---|---|
| `<leader>th` | Normal | 非表示バッファを一括クローズ |
| `<leader>tu` | Normal | 名前なしバッファを一括クローズ |

#### ファイルパス・内容コピー (ykts 独自)
| キーマップ | モード | 役割 |
|---|---|---|
| `<leader>cp` (`Space cp`) | Normal | 現在のファイルの**相対パス**（CWD起点）をコピー |
| `<leader>cP` (`Space cP`) | Normal | 現在のファイルの**絶対パス**をコピー |
| `<leader>y` (`Space y`) | Normal | ファイル名ヘッダー付きで**ファイル内容全体**をコピー |
| `<leader>x` (`Space x`) | Normal | 開いているファイルを実行（`.py` ➔ python3, `.sh` ➔ bash） |

#### ターミナル・Git (Terminal & Git)
| キーマップ | モード | 役割 |
|---|---|---|
| `\` | Normal | 開いているファイルのディレクトリでフローティングターミナルを表示/非表示 |
| `<leader>ts` | Visual | 選択した範囲のコードをターミナルに送信して実行 |
| `<leader>tl` | Normal | カーソルがある行のコードをターミナルに送信して実行 |
| `<Esc><Esc>` | Terminal | ターミナルモードを抜けて**ノーマルモード**に入る |

#### 編集・その他 (Editing & Others)
| キーマップ | モード | 役割 |
|---|---|---|
| `gcc` | Normal | 現在の行をコメントアウト/解除 |
| `gc` | Visual | 選択した範囲を一括コメントアウト/解除 |
| `<leader>a` (`Space a`) | Normal | コード構造（クラス・関数）のアウトライン表示をトグル |
| `<leader>z` (`Space z`) | Normal | **Zen Mode**（集中モード）のトグル |

---

## 2. Yazi (Terminal File Manager)

高速な Rust 製ファイラーである `Yazi` を採用し、キーバインドとプラグインを最適化しています。

* **ディレクトリ同期ラッパー (`y` 関数)**:
  Yazi を閉じた際、シェル側の作業ディレクトリを最後に開いていたパスへ自動追従するラッパー関数 `y` を搭載。
* **`fg` プラグイン連携による高速検索 (`keymap.toml`)**:
  * `F f` : `fzf` 経由で高速にファイルを検索
  * `F g` : ファイル中身をあいまい検索 (fuzzy match)
  * `F G` : `ripgrep` (rg) 経由でファイル中身を検索

---

## 3. Tmux (Terminal Multiplexer)

リモートサーバーやローカル開発機をシームレスに繋ぐマルチプレクサ設定。

* **Prefix-less ペイン・ウィンドウ操作**:
  * `Alt` + `矢印キー` のみで瞬時にペイン間（Neovimの分割ウィンドウ含む）をフォーカス移動
  * `Alt` + `/` / `Alt` + `-` で縦横に画面分割（Neovim内ではVimの分割ウィンドウ、Tmux側ではTmuxのペイン分割）
  * `Alt` + `x` で現在のアクティブウィンドウ/ペインを閉じる（Neovim内ではVim分割を閉じ、Tmux側ではペインをクローズ）
  * `Alt` + `t` でカレントパスを維持したまま新しいウィンドウを作成
  * `Alt` + `J` / `Alt` + `K` でウィンドウ間を瞬時に切り替え
* **OSC 52 透過型クリップボード同期**:
  * `set-clipboard on` により、ローカル環境のみならず、SSH越しのリモート環境やコンテナ内からでも OS 側のシステムクリップボードへ双方向に同期。
  * コピーモード (`Alt + v` で起動) は完全な vi-style (`v`, `y`) にマッピング。
* **Neovim / ターミナル最適化**:
  * True Color (RGB) および波線アンダーライン (Undercurls) を有効化し、Neovim の色彩再現性を担保
  * Focus events の有効化により、Neovim バッファへのフォーカス復帰時に自動保存や検知が正常動作
