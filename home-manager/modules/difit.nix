{ pkgs, ... }:

let
  # yoshiko-pg/difit にはpackage-lock.jsonが無いため buildNpmPackage は不可。
  # npx ラッパーでバージョン固定し Nix 管理下に置く。
  difit = pkgs.writeShellScriptBin "difit" ''
    exec ${pkgs.nodejs}/bin/npx --yes difit@5.0.2 "$@"
  '';
in
{
  home.packages = [ difit ];
}
