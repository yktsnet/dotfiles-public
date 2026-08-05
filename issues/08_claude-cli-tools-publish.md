## Claude Code 補助CLI3種（ctx / tmux-claude-session-manager / claude-history）を公開反映する
id: 08
branch-slug: claude-cli-tools-publish
github_issue:
status: open
type: feat
対象:
- flake.nix
- home-manager/modules/ctx.nix (新規)
- home-manager/modules/tmux.nix
- devices/gui/macbook/home.nix
- devices/gui/linux-desktop/home.nix
- .claude/skills/ctx-history-search/SKILL.md (新規)
- docs/tui_environment.md
内容: 私物 `~/dotfiles` で使っている Claude Code 補助ツールのうち `hunk` は既に公開済み。残る3つ（`ctx`・`tmux-claude-session-manager`・`claude-history`）と、`ctx` の使い方を示す workflow skill `ctx-history-search` を dotfiles-public に反映し、`docs/tui_environment.md` で紹介する。
確認: `nix flake check`（新規input・新規パッケージ・tmux.nix変更の評価エラー検出）、目視確認（docs/tui_environment.md の記述整合性、SKILL.md の frontmatter 形式が既存skillと一致するか）。実際の動作確認（ctxのビルド成否・tmuxキーバインドの挙動）は user が該当デバイスで `home-manager switch` 後に行う。

---

### 保証
- 保証: なし（個人環境設定の Nix モジュール・docs 変更であり、動作保証は user が各デバイスでの switch 適用時に目視確認する。裏付けるテストは存在しない。`nix flake check` は評価エラー検出のみ）

### 背景

相談者セッションで私物 `~/dotfiles` を調査し、Claude Code 用の補助CLIが4つあることを確認した。`hunk`（diff レビューTUI）は既に `home-manager/modules/hunk.nix` として公開済みで `docs/tui_environment.md` §2.6 でも紹介されている。残り3つは未反映。

- `ctx`（[ctxrs/ctx](https://github.com/ctxrs/ctx)）: Claude Code のセッション履歴をSQLでクエリできる形にインデックスするCLI。人間が直接叩くのではなく、Agent（Claude自身）が過去セッションを検索する用途で使う。
- `tmux-claude-session-manager`（[craftzdog/tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager)）: tmux プラグイン。popup で新規 Claude セッションを起動し、バックグラウンドで走らせたまま他のセッションへ切り替えられる。
- `claude-history`（[raine/claude-history](https://github.com/raine/claude-history)）: 過去のConversationをfzf風のTUIで検索・再開するCLI。`ctx`とは対照的に人間が対話的に使う。

`ctx` は private 側でも `ctx-history-search` skill 経由でしか使われていない。skill なしで `ctx.nix` だけ公開しても、何のためのツールか伝わらないため、skill も併せて移植する。

### 仕様

#### flake.nix

`inputs` に以下を追加する（`github:raine/claude-history` は既にOSS公開されているツールなので伏せる理由はない）:

```nix
claude-history = {
  url = "github:raine/claude-history";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

#### home-manager/modules/ctx.nix（新規）

コピー元: `~/dotfiles/home-manager/modules/ctx.nix`。`rustPlatform.buildRustPackage` で `ctxrs/ctx` をソースビルドしており、secrets依存やマスク対象の固有情報は含まれていないため、ほぼそのまま移植できる。ONNX Runtime の動的リンク回避策（`ORT_LIB_LOCATION` / `ORT_PREFER_DYNAMIC_LINK`）のコメントも含めて維持する。

#### home-manager/modules/tmux.nix

private版（`~/dotfiles/home-manager/modules/tmux.nix`）から以下を移植する:

- `claude-session-manager` プラグイン定義（`pkgs.tmuxPlugins.mkTmuxPlugin` で `craftzdog/tmux-claude-session-manager` を取得）
- `claudeLaunchVariant`（popup で新規Claudeセッションを起動するシェルスクリプト）
- `M-y` / `M-Y`（Sonnet/Opusでの起動）・`M-u`（セッションピッカー）バインド
- `agentStatus`（`claude agents --json` を集計してstatus-rightに表示するステータス文字列）
- `sessionizer`（リポ選択→専用tmuxセッション切替、`M-s`）

**host gate の置き換え**: private版は `hasClaudeSessionManager = builtins.elem host [ "neo" "sv6" ]` という私物ホスト名で絞っている。本リポでは既に `devices/gui/macbook/system.nix` の `networking.hostName = "macbook"`、`devices/gui/linux-desktop/system.nix` の `networking.hostName = "linux-desktop"` が実体のホスト名なので、置き換え先は `[ "macbook" "linux-desktop" ]` になる（`devices/gui/linux-laptop` は対象外。private側に対応機がなく、可搬機でtmuxセッション常駐管理をする用途は薄いため）。

**sessionizer のパス一般化**: private版は `$HOME/dotfiles` と `$HOME/github-public` / `$HOME/github-private` / `$HOME/github-clone` を直接列挙している。これは本人の私物ディレクトリ構成であり、本リポは他者が使う汎用テンプレートでもあるため、そのまま移植せず「`$HOME` 直下と `$HOME/github-public` 等の1階層下を横断的にfzfへ流す」という汎用的な列挙ロジックに書き換える（存在しないディレクトリは無視する形は維持）。列挙対象の具体的なディレクトリ名は実装者判断でよい。

#### devices/gui/macbook/home.nix

- `imports` に `../../../home-manager/modules/ctx.nix` を追加
- `home.packages` に `inputs.claude-history.packages.${pkgs.stdenv.hostPlatform.system}.default` を追加

#### devices/gui/linux-desktop/home.nix

- 現状 `{ config, pkgs, lib, ... }:` で `inputs` を受け取っていないため、関数引数に `inputs` を追加する
- `imports` に `../../../home-manager/modules/ctx.nix` を追加
- `home.packages` に `inputs.claude-history.packages.${pkgs.stdenv.hostPlatform.system}.default` を追加

#### .claude/skills/ctx-history-search/SKILL.md（新規）

コピー元: `~/dotfiles/.claude/skills/ctx-history-search/SKILL.md`。`plugins/public-skills/`（marketplace配布側）ではなく `.claude/skills/`（本リポ内部のワークフローskill）に置く。

private版は対象リポを「`dotfiles` / `github-private` / `github-public` の3リポ」と本人固有の構成で固定記述している。本リポは汎用テンプレートなので、この決め打ちは一般化する（例:「対象は運用しているリポのうち相談者セッションが動くもの。`--workspace` フィルタで実行者セッション（`-wt-` を含むディレクトリ名）を除外する」といった記述に変える）。SQLクエリ自体（`ctx sql` / `ctx search` / `ctx show`）はツール仕様そのものなので変更不要。機密マスク要否は `secrets-agents/` の辞書と照合すること（現状該当する固有接続情報は無い見込み）。

#### docs/tui_environment.md

- §1 Tmux のキー表（ペイン・ウィンドウ節の下）に `M-y` / `M-Y` / `M-u` の行を追加する。既存の `Alt + p`（スクラッチターミナルpopup）などと同じ表・同じ文体に合わせる
- 「設計上のポイント」箇条書きに、`tmux-claude-session-manager` へのリンクを一文追加する（§2.6の hunk 紹介文と同じ書き方: `[tmux-claude-session-manager](https://github.com/craftzdog/tmux-claude-session-manager)` のようにリンクし、popup起動・バックグラウンド常駐・ピッカー復帰という役割を一文で説明）
- 新設の小節（`## 3. Claude Code 補助 CLI` 等、既存の `## 1. tmux` `## 2. Neovim` と同じ見出しレベル）で `ctx` と `claude-history` を紹介する。両者とも「セッション履歴を検索する」点は共通だが、`ctx` はAgent（skill経由）がSQLで検索する用途、`claude-history` は人間がTUIで対話的に探す用途、という違いを一文で明示する。それぞれ該当GitHubリンクを付ける

### 実装順序

1. `flake.nix`（input追加）
2. `home-manager/modules/ctx.nix`（新規）
3. `home-manager/modules/tmux.nix`（プラグイン・バインド統合）
4. `devices/gui/macbook/home.nix` / `devices/gui/linux-desktop/home.nix`（import・package追加）
5. `nix flake check` で評価エラーがないことを確認
6. `.claude/skills/ctx-history-search/SKILL.md`（新規・一般化）
7. `docs/tui_environment.md`（3箇所の追記）
