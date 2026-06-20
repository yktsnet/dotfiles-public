{ lib, ... }:
# x86 / NixOS（Mac 以外）向け zsh エントリポイント。
# 共通ベース + Linux 固有の差分。home-manager モジュールとして import する。
{
  imports = [
    ./common.nix
  ];

  programs.zsh.initContent = lib.mkBefore ''
    # ssh-agent を起動し、未ロードなら鍵を追加する
    if [ -z "$SSH_AUTH_SOCK" ]; then
      eval "$(ssh-agent -s)" > /dev/null
    fi
    if ! ssh-add -l > /dev/null 2>&1; then
      ssh-add ~/.ssh/id_ed25519 2>/dev/null
    fi
  '';
}
