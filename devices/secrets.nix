{ lib, config, ... }:
let
  secretsRoot = ../secrets;
  catDirs = lib.filterAttrs (name: type: type == "directory") (builtins.readDir secretsRoot);
  # agents（マスク辞書）は /run/secrets ではなく home-manager 側の別の場所へ復号する必要があり、
  # home-manager 側のモジュールが別途宣言する。
  # ここで拾うと同じ secret を system 側でも復号してしまい二重復号になるので除外する。
  # 実際に使うのは Issue 15（マスク辞書配布）。
  hmManagedCategories = [ "agents" ];
  categories = lib.subtractLists hmManagedCategories (builtins.attrNames catDirs);
  # 拡張子による自動判定を使わず binary 固定にしたいカテゴリをここに列挙する。
  legacyBinaryCategories = [ ];
  detectFormat = cat: filename:
    if builtins.elem cat legacyBinaryCategories then "binary"
    else
      let stem = lib.removeSuffix ".age" filename;
      in
      if lib.hasSuffix ".env" stem then "dotenv"
      else if lib.hasSuffix ".json" stem then "json"
      else "binary";
  genSecretAttrs = cat:
    let
      catDir = secretsRoot + "/${cat}";
      files = builtins.attrNames (builtins.readDir catDir);
      ageFiles = builtins.filter (f: lib.hasSuffix ".age" f) files;
    in
    builtins.listToAttrs (map
      (f: {
        name = "${cat}/${lib.removeSuffix ".age" f}";
        value = {
          sopsFile = catDir + "/${f}";
          format = detectFormat cat f;
          owner = config.secrets.primaryUser;
        };
      })
      ageFiles);
in
{
  options.secrets.primaryUser = lib.mkOption {
    type = lib.types.str;
    default = "user";
    description = "sops secret の復号先所有者となるプライマリユーザ";
  };

  config.sops.secrets =
    lib.foldl (acc: cat: acc // (genSecretAttrs cat)) { } categories;
}
