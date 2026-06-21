# dotfiles-public 開発規約

コードの書き方・編集の共通ルール（どう書くか）。ディレクトリ構成は `structure.md` を参照。

## 1. 技術スタック
- **Nix Flakes**: macOS（nix-darwin）と NixOS（ヘッドレス VPS 含む）を統一管理。
- **home-manager**: ユーザ環境（TUI ツールチェーン・dotfiles）を宣言的に管理。
- **Zsh**: Issue 駆動ワークフローのシェルマクロ（`zsh/functions/`）。

## 2. コードスタイル
- Nix は `nix fmt`（フォーマッタ）で統一する。属性セットは用途ごとにモジュール分割し、`home-manager/modules/` に配置する。
- デバイス固有設定は `devices/gui/`・`devices/headless/` に分け、共通モジュールを import して組み立てる。
- Zsh 関数は1機能1ファイルを基本とし、`zsh/functions/` に置く。

## 3. ファイル編集戦略
- **広範囲の書き換え**: 変更箇所が多い場合（目安: 10箇所以上、またはファイルの20%超）、`str_replace` の繰り返しではなく `bash` でファイル全体を一括書き出す（`cat > path << 'EOF'` 等）。
- **局所的修正**: 数行以内の修正に限定してツールを使用。
- **静的チェック**: Nix 変更時は `nix flake check` で評価エラーを検出する。Zsh 変更時は `zsh -n <file>` で構文チェックする。
- **適用しない**: `nixos-rebuild` / `darwin-rebuild` / `home-manager switch` 等の実適用コマンドは実行しない（user が各デバイスで実施）。`flake.lock` は編集しない。
- **機密**: `secrets-agents/` の実値は読み書きしない。人間が読む地の文・PR・コミットに固有接続情報を直書きせず、`secrets-agents/` の辞書で定義された `<PLACEHOLDER>` を用いる。
