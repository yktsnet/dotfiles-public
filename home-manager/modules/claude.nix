{ lib, config, ... }:
let
  # コピー元はストアパスで持つ。`"${config.home.homeDirectory}/dotfiles"` のような生の
  # パス文字列にすると、配る中身が変わっても activation script の文字列が変わらない。
  # home-manager の世代が同一になり、nixos-rebuild switch は変化のないユニットを
  # 再起動しないため home-manager-<user>.service が動かず、変更が ~/.claude へ届かない。
  # ストアパスなら内容がハッシュに乗るので、世代が変わって必ず配り直される。
  claudeSrc = ../../.claude;
  guideDir = ../config/claude;
  guides = [ "common.md" ] ++ config.claude.extraGuides;
  guidePaths = lib.concatMapStringsSep " " (g: ''"${guideDir}/${g}"'') guides;
in
{
  options.claude.extraGuides = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    description = ''
      common.md の後ろに連結する追加ガイド（home-manager/config/claude/ 配下のファイル名）。
      フリート固有の規約は、それが意味を持たない機へ配らないよう分離する。
    '';
  };

  # `~/.claude` 配下（settings.json / CLAUDE.md / skills / hooks / agents）は本リポの
  # `.claude/` と `home-manager/config/claude/` を正本とし、activation script で
  # 実体コピーして配置する。symlink ではなく実体コピーにしているのは、WSL 環境では
  # Nix ストアへのシンボリックリンクが Windows 側（\\wsl.localhost\）から読めないため。
  #
  # この配置方式の帰結として `~/.claude` 側は生成物になる。Agent が
  # `~/.claude/settings.json` 等を直接編集しても次回の switch で消えるため、
  # `.claude/hooks/block-live-claude-config-edit.sh` が編集を拒否し、
  # 生成元（本リポの `.claude/`）へ誘導する。
  config.home.activation.claude-config = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    dst="$HOME/.claude"
    rm -rf "$dst/settings.json" "$dst/CLAUDE.md" "$dst/skills" "$dst/hooks" "$dst/agents"
    install -Dm644 "${claudeSrc}/settings.json" "$dst/settings.json"
    # 生成元を .claude/ の外に置くのは、本リポ自身で作業するとき
    # グローバル指示とプロジェクト指示として同一内容が二重に読まれるため
    cat ${guidePaths} > "$dst/CLAUDE.md"
    chmod 644 "$dst/CLAUDE.md"
    cp -rL "${claudeSrc}/skills" "$dst/skills"
    cp -rL "${claudeSrc}/hooks" "$dst/hooks"
    cp -rL "${claudeSrc}/agents" "$dst/agents"
    chmod -R u+w "$dst/skills" "$dst/hooks" "$dst/agents"
    chmod -R u+x "$dst/hooks"
  '';
}
