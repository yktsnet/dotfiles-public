{ pkgs, ... }:

let
  # modem-dev/hunk にはpackage-lock.jsonが無いため buildNpmPackage は不可。
  # npx ラッパーでバージョン固定し Nix 管理下に置く。
  hunk = pkgs.writeShellScriptBin "hunk" ''
    exec ${pkgs.nodejs}/bin/npx --yes hunkdiff@0.17.3 "$@"
  '';
in
{
  home.packages = [ hunk ];
}
