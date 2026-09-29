# dotfiles-public 開発規約

コードの書き方・編集の共通ルール（どう書くか）。ディレクトリ構成は `structure.md` を参照。

## 1. 技術スタック
- **Nix Flakes**: NixOS（GUI・ヘッドレス VPS）と macOS（nix-darwin）を統一管理。
- **home-manager**: ユーザ環境（TUI ツールチェーン・dotfiles）を宣言的に管理。
- **Zsh**: Issue 駆動ワークフローのシェルマクロ（`home-manager/modules/zsh/functions/`）。

## 2. コードスタイル
- Nix は `nix fmt`（フォーマッタ）で統一する。属性セットは用途ごとにモジュール分割し、`home-manager/modules/` に配置する。
- デバイス固有設定は `devices/<device>/` に置き、共通モジュールを import して組み立てる。
- Zsh 関数は1機能1ファイルを基本とし、`home-manager/modules/zsh/functions/` に置く。
- OS 差は `home-manager/modules/zsh/functions/os.sh` のシム（`_is_darwin` / `_sed_i` / `_open` / `_linux_only`）を通す。関数本体に `uname` / `$OSTYPE` / `sed -i` / `xdg-open` を直接書かない。Linux のハードウェア・systemd を直に叩く関数は冒頭で `_linux_only '依存先' || return 1`。

## 3. ファイル編集戦略
- **広範囲の書き換え**: 変更箇所が多い場合（目安: 10箇所以上、またはファイルの20%超）、`str_replace` の繰り返しではなく `bash` でファイル全体を一括書き出す（`cat > path << 'EOF'` 等）。
- **局所的修正**: 数行以内の修正に限定してツールを使用。
- **静的チェック**: Nix 変更時は `nix flake check` で評価エラーを検出する。Zsh 変更時は `zsh -n <file>` で構文チェックする。
- **適用しない**: `nixos-rebuild` / `darwin-rebuild` / `home-manager switch` 等の実適用コマンドは実行しない（user が各デバイスで実施）。`flake.lock` は編集しない。
- **機密**: `secrets-agents/` の実値は読み書きしない。人間が読む地の文・PR・コミットに固有接続情報を直書きせず、`secrets-agents/` の辞書で定義された `<PLACEHOLDER>` を用いる。
