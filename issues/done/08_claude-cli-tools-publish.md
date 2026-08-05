## PR記録: feat(claude-cli-tools): ctx / tmux-claude-session-manager / claude-history を公開反映
issue: 08 (08_claude-cli-tools-publish.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/30
Merged: 66a6a216ff87665579a7e4a353f3d8b1d94d33ad

## 変更内容
私物 `~/dotfiles` で使っている Claude Code 補助ツールのうち `hunk` は既に公開済み。
残る3つ（`ctx`・`tmux-claude-session-manager`・`claude-history`）と、`ctx` の使い方を示す
workflow skill `ctx-history-search` を dotfiles-public に反映し、`docs/tui_environment.md`
で紹介した。

- `flake.nix`: `claude-history`（`github:raine/claude-history`）input を追加
- `home-manager/modules/ctx.nix`（新規）: `ctxrs/ctx` を `rustPlatform.buildRustPackage` でソースビルド。ONNX Runtime 動的リンク回避策込みでほぼそのまま移植
- `home-manager/modules/tmux.nix`: `claude-session-manager` プラグイン・`claudeLaunchVariant`（popup起動）・`M-y`/`M-Y`/`M-u` バインド・`agentStatus`（status-right）・`sessionizer`（`M-s`）を移植。host gate は私物ホスト名 `[ "neo" "sv6" ]` から本リポの実ホスト名 `[ "macbook" "linux-desktop" ]` に置き換え。sessionizer は私物パス決め打ちをやめ、`$HOME` 直下 + `$HOME/github-*` クラスタの1階層下を横断列挙する汎用ロジックに書き換え
- `devices/gui/macbook/home.nix` / `devices/gui/linux-desktop/home.nix`: `ctx.nix` の import と `claude-history` パッケージを追加
- `.claude/skills/ctx-history-search/SKILL.md`（新規）: 私物版の「dotfiles/github-private/github-public の3リポ固定」記述を、「運用しているリポの相談者セッション（`-wt-` を含む実行者セッションは `--workspace` フィルタで除外）」という汎用記述に一般化して移植
- `docs/tui_environment.md`: §1 キー表に `M-y`/`M-Y`/`M-u` を追加、設計ポイントに `tmux-claude-session-manager` の紹介文を追加、新設 `## 3. Claude Code 補助 CLI` で `ctx`（Agent用途）と `claude-history`（人間用途）を紹介

### 対象フィールドからの逸脱（2件、実装上必須のため追加）
- `devices/gui/system.nix`: `home-manager.extraSpecialArgs = { inherit inputs; osConfig = config; };` を追加。既存の `home-manager.users.yktsnet = import ./home.nix;` には `inputs` が配線されておらず（macbook の darwin 側は既に配線済みだが、linux-desktop/linux-laptop が乗る NixOS gui 側は未配線だった）、このままでは `linux-desktop/home.nix` の `inputs.claude-history...` 参照が評価エラーになることを `nix eval` で実証した（`error: attribute 'inputs' missing`）。macbook/headless 側と同じパターンで最小追加
- `flake.lock`: `claude-history` input 追加に伴う `nix flake check` 実行時の自動更新（新規追加分のみ。既存 input のバージョンは変えていない）

## 保証
なし（個人環境設定の Nix モジュール・docs 変更であり、動作保証は user が各デバイスでの switch 適用時に目視確認する。裏付けるテストは存在しない。`nix flake check` は評価エラー検出のみ）

## 静的確認結果
- `nix flake check`: darwinConfigurations.macbook ビルド成功（既存の deprecation 警告のみ、新規エラーなし）。nixosConfigurations は x86_64-linux のためビルドはスキップされる仕様
- `nix eval` による linux-desktop/linux-laptop の深掘り評価: `home-manager.extraSpecialArgs` 追加後、`config.home-manager.users.yktsnet.home.packages`（80件）・`programs.tmux.plugins`（linux-desktop=1件、linux-laptop=0件でhost gate動作確認）が評価成功
- macbook側: `home.packages`（37件）・`programs.tmux.plugins`（1件）も評価成功
- caller/import整合性: ctx.nix・tmux.nix はいずれも既存の `home-manager/modules/` 内モジュールと同形式（`{ pkgs, lib, ... }` 系引数）で構文互換。SKILL.md frontmatter は既存 skill（`disable-model-invocation: true` を持つ `pr-workflow` 等）と同形式
- git diff --name-only --cached:
  .claude/skills/ctx-history-search/SKILL.md
  devices/gui/linux-desktop/home.nix
  devices/gui/macbook/home.nix
  devices/gui/system.nix
  docs/tui_environment.md
  flake.lock
  flake.nix
  home-manager/modules/ctx.nix
  home-manager/modules/tmux.nix

## 検証手順
1. 対象デバイス（macbook / linux-desktop）で `home-manager switch`（または `darwin-rebuild switch` / `nixos-rebuild switch`）を適用
2. `ctx --version` と `claude-history --version`（または `--help`）がビルド・起動できることを確認
3. tmux で `Alt+y` / `Alt+Y` から Claude Code セッションが popup で起動し、`Alt+u` でピッカーに戻れることを確認
4. tmux status-right にエージェント状態インジケータ（`agentStatus`）が表示されることを確認
5. `Alt+s` でセッショナイザーが起動し、`$HOME` 直下・`$HOME/github-*` 配下のリポが一覧に出ることを確認
