{ config, lib, ... }:
{
  # 永続メモリの正本をdotfiles配下に置き~/memoryをそこへのシンボリックリンクにする（複数デバイス間の同期と衝突解決をgit経路に乗せる目的、フック類は$HOME/memory参照のまま変更不要）。home.fileでなくactivation scriptなのは既存実体/リンクとの衝突でactivation全体が落ちるのを避けるため（claude.nixと同じ理由）。
  home.activation.memorySymlink = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    src="${config.home.homeDirectory}/dotfiles/memory"
    dst="${config.home.homeDirectory}/memory"

    if [ ! -d "$src" ]; then
      echo "memory.nix: $src が無い。memory/ を作るか、このmoduleをimportsから外すこと。" >&2
    elif [ -L "$dst" ]; then
      ln -sfn "$src" "$dst"
    elif [ -e "$dst" ]; then
      echo "memory.nix: $dst が実体として存在する。$src へ内容を退避・統合してから削除すること。" >&2
    else
      ln -s "$src" "$dst"
    fi
  '';
}
