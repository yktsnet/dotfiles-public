{ pkgs, lib, ... }:
# Mac (nix-darwin) 向け zsh エントリポイント。
# 共通ベース + macOS 固有の差分。home-manager モジュールとして import する。
{
  imports = [
    ./common.nix
  ];

  programs.zsh.initContent = lib.mkBefore ''
    # pure-prompt を fpath に追加（nix-darwin では site-functions が自動で乗らない）
    fpath+=("${pkgs.pure-prompt}/share/zsh/site-functions")
  '';
}
