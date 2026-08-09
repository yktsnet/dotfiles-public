{ config, lib, ... }:
let
  # secrets/agents/*.age は Issue/PR の地の文で使うマスク辞書（実値↔プレースホルダ）。
  # グローバル CLAUDE.md の機密マスク規則が参照先をリポジトリ内の secrets-agents/ に固定しているため、
  # /run/secrets ではなくそこへ平文で復号する。復号先は .gitignore 済みで git には乗らない。
  #
  # 以前は平文のまま gitignore していたため辞書は1台にしか存在せず、別デバイスで Issue/PR を書くと
  # 何を伏せるべきか分からないまま書くことになっていた。暗号文を git 経路に乗せ、各機が自分の
  # age 鍵で復号する形にして解消する。
  #
  # devices/secrets.nix（system 側）は agents カテゴリを除外している（二重復号を避けるため）。
  # 本モジュールは macbook・linux-desktop 等、imports した GUI デバイスの home-manager 経由で効く。
  secretsDir = ../../secrets/agents;
  ageFiles =
    if builtins.pathExists secretsDir then
      builtins.filter (lib.hasSuffix ".age")
        (builtins.attrNames (builtins.readDir secretsDir))
    else
      [ ];
  dictDir = "${config.home.homeDirectory}/dotfiles/secrets-agents";
in
{
  sops.secrets = builtins.listToAttrs (map
    (f:
      let stem = lib.removeSuffix ".age" f; in
      {
        name = "agents/${stem}";
        value = {
          sopsFile = secretsDir + "/${f}";
          format = "binary";
          path = "${dictDir}/${stem}";
          mode = "0400";
        };
      })
    ageFiles);
}
