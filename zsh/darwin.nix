{ ... }:
# Mac (nix-darwin) 向け zsh エントリポイント。
# 共通ベース + macOS 固有の差分。home-manager モジュールとして import する。
{
  imports = [
    ./common.nix
  ];
}
