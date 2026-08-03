{ lib, ... }:
{
  # `~/.claude` 配下（settings.json / CLAUDE.md / skills / hooks）は本リポの
  # `.claude/` を正本とし、activation script で実体コピーして配置する。
  # symlink ではなく実体コピーにしているのは、WSL 環境では Nix ストアへの
  # シンボリックリンクが Windows 側（\\wsl.localhost\）から読めないため。
  #
  # この配置方式の帰結として `~/.claude` 側は生成物になる。Agent が
  # `~/.claude/settings.json` 等を直接編集しても次回の switch で消えるため、
  # `.claude/hooks/block-live-claude-config-edit.sh` が編集を拒否し、
  # 生成元（本リポの `.claude/`）へ誘導する。
  home.activation.claude-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    rm -rf "$HOME/.claude/settings.json" "$HOME/.claude/CLAUDE.md" "$HOME/.claude/skills" "$HOME/.claude/hooks"
    install -Dm644 "$HOME/dotfiles/.claude/settings.json" "$HOME/.claude/settings.json"
    install -Dm644 "$HOME/dotfiles/.claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
    cp -rL "$HOME/dotfiles/.claude/skills" "$HOME/.claude/skills"
    cp -rL "$HOME/dotfiles/.claude/hooks" "$HOME/.claude/hooks"
    chmod -R u+x "$HOME/.claude/hooks"
  '';
}
