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
* **通知・インジケーター ([fidget.nvim](https://github.com/j-hui/fidget.nvim))**: 画面右下に LSP 起動・インデックス進捗などを控えめにポップアップ表示。
* **UI改善 ([dressing.nvim](https://github.com/stevearc/dressing.nvim))**: Neovim標準のインプット窓や選択メニューを、使いやすいモダンなフローティング窓へ拡張。

#### 📂 ファイル操作・ナビゲーション (Files & Navigation)
* **Yazi 密結合 ([yazi.nvim](https://github.com/mikavilpas/yazi.nvim))**:
  * `<leader>e` で開いているファイルのディレクトリ、`<leader>E` でプロジェクトルート (CWD) を起点に、ターミナルファイラー Yazi をフローティング窓で起動します。
* **バッファ型編集 ([oil.nvim](https://github.com/stevearc/oil.nvim))**:
  * `-` キーでファイルの親ディレクトリを通常のテキストバッファとして開きます。ファイルやフォルダの作成・リネーム・削除を、通常の Vim 編集キー（`dd` や `cw` など）で行い、`:w` で一括保存・適用できます。
* **あいまい検索 ([telescope.nvim](https://github.com/nvim-telescope/telescope.nvim))**:
  * `fzf-native` 拡張（C言語製高速ソーター）を利用し、プロジェクト内のファイル名や、コード内の文字列を高速にあいまい検索します。

#### 💻 コーディング・LSP (Coding & Language Server)
* **構文解析 ([nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter))**: 高度なシンタックスハイライト、インデント調整、コードブロック選択を提供。
* **LSPスタック**: `lspconfig` + `mason.nvim` + `nvim-cmp` + `LuaSnip` の組み合わせ。
  * 自動補完、関数の定義元ジャンプ、シグネチャヘルプ、静的型チェックが自動で機能します。
* **自動整形 ([conform.nvim](https://github.com/stevearc/conform.nvim))**: ファイル保存時に適切なフォーマッターを自動実行し、コードスタイルを統一。
* **コメントアウト ([comment.nvim](https://github.com/numToStr/Comment.nvim))**: `gcc`（行単位）や `gc`（選択範囲）で素早くコメントアウト可能。
* **構造アウトライン ([aerial.nvim](https://github.com/stevearc/aerial.nvim))**: `<leader>a` でクラスや関数の一覧をサイドバーに表示し、ジャンプ可能。

#### 🔄 ワークフロー自動化 (Workflow Automation)
* **自動セッション復元 ([auto-session](https://github.com/rmagatti/auto-session))**:
  * `:q` や `:wq` で Neovim を閉じた際、開いていたファイルや画面分割などの状態をプロジェクトごとに自動保存。次回そのディレクトリで `nvim` を起動した際に**自動で前回の続きから再開**します。
  - ホームディレクトリ直下（`~/`）などではセッションを作らないように除外設定されています。
* **カーソル位置の自動復元**:
  * 以前開いたことのあるファイルを開き直した際、自動的に**前回閉じたときのカーソル位置に戻る**自動コマンドが組み込まれています。
* **キーマップ案内 ([which-key.nvim](https://github.com/folke/which-key.nvim))**:
  - `Space` を押してしばらく待つと、入力可能なキー操作の一覧が画面下部にポップアップ表示されます。

#### 🐙 Git & ターミナル (Git & Terminal)
* **LazyGit 連携 ([lazygit.nvim](https://github.com/kdheepak/lazygit.nvim))**:
  * `<leader>lg` で Git UI である LazyGit をフローティング窓で起動。Nvim の中でコミットからプッシュまで完結します。
* **差分表示 ([gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim))**: 変更箇所の差分を行番号の左隣にカラーマーカーでリアルタイム表示。
* **ターミナル管理 ([toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim))**:
  * `\` キーでフローティングターミナルをトグル起動。選択範囲のコード（Visualモードで `<leader>ts`）やカーソル行（`<leader>tl`）をターミナルに直接送信して実行できます。

---

### 1.2 Neovim キーマップ一覧

**Leader キー** は **`Space`** にマッピングされています。

#### カスタム・基本操作 (Custom & Basic)
| キーマップ | モード | 役割 |
|---|---|---|
| `<leader>p` (`Space p`) | Normal | 現在のファイルの**相対パス**（CWD起点）をコピー |
| `<leader>P` (`Space P`) | Normal | 現在のファイルの**絶対パス**をコピー |
| `<leader>y` (`Space y`) | Normal | ファイル名ヘッダー付きで**ファイル内容全体**をコピー |
| `<leader>x` (`Space x`) | Normal | 開いているファイルを実行（`.py` ➔ python3, `.sh` ➔ bash） |

#### ファイラー・検索 (Filer & Finder)
| キーマップ | モード | 役割 |
|---|---|---|
| `<leader>e` (`Space e`) | Normal | **開いているファイルのディレクトリ**で Yazi を起動 |
| `<leader>E` (`Space E`) | Normal | **プロジェクトの作業ディレクトリ (CWD)** で Yazi を起動 |
| `-` | Normal | 現在のファイルの**親ディレクトリ**を Oil バッファ（Vim式編集）で開く |
| `<leader>f` (`Space f`) | Normal | プロジェクト配下の**ファイル名検索 (Telescope)** |
| `<leader>F` (`Space F`) | Normal | 複数ルート（`dotfiles`, `projects`等）の**ファイル名検索** |
| `<leader>g` (`Space g`) | Normal | プロジェクト配下の**テキスト検索 (Grep)** |
| `<leader>G` (`Space G`) | Normal | 複数ルートの**テキスト検索 (Grep)** |

#### LSP 開発支援 (LSP)
| キーマップ | モード | 役割 |
|---|---|---|
| `gd` | Normal | カーソル下のシンボルの**定義元へジャンプ** |
| `K` | Normal | カーソル下のシンボルの**ホバー情報（型・ドキュメント）の表示** |
| `<leader>rn` (`Space rn`) | Normal | 変数・関数名などの**一括リネーム** |
| `<leader>ca` (`Space ca`) | Normal | **コードアクション**（自動修正やインポート自動追加など）の実行 |
| `<leader>d` (`Space d`) | Normal | 行内のエラー・警告の詳細をフローティング表示 |

#### ターミナル・Git (Terminal & Git)
| キーマップ | モード | 役割 |
|---|---|---|
| `\` | Normal | カレントディレクトリ (CWD) でフローティングターミナルを表示/非表示 |
| `<leader>ts` | Visual | 選択した範囲のコードをターミナルに送信して実行 |
| `<leader>tl` | Normal | カーソルがある行のコードをターミナルに送信して実行 |
| `<Esc><Esc>` | Terminal | ターミナルモードを抜けて**ノーマルモード**に入る |
| `<leader>lg` (`Space lg`) | Normal | LazyGit をフローティング窓で起動/閉じる |

#### 編集・その他 (Editing & Others)
| キーマップ | モード | 役割 |
|---|---|---|
| `gcc` | Normal | 現在の行をコメントアウト/解除 |
| `gc` | Visual | 選択した範囲を一括コメントアウト/解除 |
| `<leader>a` (`Space a`) | Normal | コード構造（クラス・関数）のアウトライン表示をトグル |

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
  * `Alt` + `矢印キー (または j/k)` のみで瞬時にペイン間をフォーカス移動
  * `Alt` + `/` / `Alt` + `-` で現在のペインカレントパスを引き継いで縦横にウィンドウを分割
  * `Alt` + `t` でカレントパスを維持したまま新しいウィンドウを作成
  * `Alt` + `J` / `Alt` + `K` でウィンドウ間を瞬時に切り替え
* **OSC 52 透過型クリップボード同期**:
  * `set-clipboard on` により、ローカル環境のみならず、SSH越しのリモート環境やコンテナ内からでも OS 側のシステムクリップボードへ双方向に同期。
  * コピーモード (`Alt + v` で起動) は完全な vi-style (`v`, `y`) にマッピング。
* **Neovim / ターミナル最適化**:
  * True Color (RGB) および波線アンダーライン (Undercurls) を有効化し、Neovim の色彩再現性を担保
  * Focus events の有効化により、Neovim バッファへのフォーカス復帰時に自動保存や検知が正常動作
