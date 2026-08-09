## PR記録: feat: マスク辞書の配布機構（secrets-agents.nix）と sops-secrets skill を公開する
issue: 15 (15_secrets-agents-dictionary.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/44
Merged: e9acb3ae4a7feb3c27b7f2571948e2edc4093f9e

## 変更内容
Issue 14 で敷いた sops レイヤの上に、マスク辞書（`secrets-agents/`）を全デバイスへ配る機構を載せた。README は「実値はローカルの `secrets-agents/` に隔離する」と書いているが、辞書がローカルにしか無いとデバイスを移った途端に「何を伏せるべきか分からないまま」Issue / PR を書くことになる。暗号文を git 経路に載せ、各機が自分の age 鍵で復号する形にした。あわせて、その運用手順である `sops-secrets` skill を公開した。

- `home-manager/modules/secrets-agents.nix`（新規）: `secrets/agents/*.age` を走査し `sops.secrets` を組み立てる。`secrets/agents/` が無くても空スキャンとして評価が通る（`builtins.pathExists` ガード）
- `devices/gui/macbook/home.nix` / `devices/gui/home.nix`: 上記 module を imports に追加（`devices/headless/home.nix` は対象外）
- `.claude/skills/sops-secrets/`（新規3ファイル）: 私物 `~/dotfiles` の運用手順を移植・一般化。実デバイス名（neo/het/T14等）は役割名（macbook/linux-desktop等）に、私物固有のカテゴリ名は一般形に置き換え、本リポに無いクロスビルド委譲の記述は削除した。frontmatter は自動発火のまま（`disable-model-invocation` は付けない）
- `README.md` / `README.en.md`: Foundation の「機密情報の分離」に、辞書を暗号化して git 経路で配る旨を1項目内で追記

### 実装中に見つかった2点の前提欠落（user 裁可済み、対象外だったが追加）
- `.gitignore`: `secrets-agents/*` を追加。復号先ディレクトリが gitignore 済みという新規保証を満たすため。既存の追跡済みサンプル（`secrets-agents/production-server.md`）はこのルールの影響を受けない
- `flake.nix`: `home-manager.sharedModules = [ inputs.sops-nix.homeManagerModules.sops ];` を nixosConfigurations / darwinConfigurations.macbook に追加。Issue 14 では system 側の sops module しか配線されておらず、home-manager 側の `sops.secrets` オプション自体が存在しないため `nix flake check` が失敗していた

## 保証
- 復号先が `.gitignore` 済みで平文の辞書が git に乗らない → 裏付けテストなし（Issue の「テスト欠落について」で裁可済み。`.gitignore` 追加で担保）
- `secrets/agents/` 配下の `.age` は module 変更なしに1つずつ復号先へ配置される → 裏付けテストなし（同上。`builtins.pathExists` ガードは `nix flake check` で確認済み）
- 復号先はリポジトリ内の `secrets-agents/` である → 裏付けテストなし（同上）
- 復号ファイルのパーミッションは `0400` → 裏付けテストなし（同上。`secrets-agents.nix` にハードコード）
- system 側と home-manager 側で同一カテゴリが二重復号されない → 裏付けテストなし（同上。Issue 14 の `hmManagedCategories = [ "agents" ]` による除外を目視確認済み）
- 維持する保証（Issue 14 の secret 登録規則・暗号文非コミット方針・`secrets/` への settings.json deny）は変更していない

## 静的確認結果
- `nix flake check`: 成功（darwinConfigurations.macbook を含む全 nixosConfigurations の評価が通った。事前のワーカー確認では home-manager 側 sops module 未配線でエラーになったが、上記 flake.nix 修正後に解消）
- 目視確認: skill 本文・references 2本に固有デバイス名（neo/het/T14/sv6/rpi3）・私物カテゴリ名（ops/ntf/common/keepass/kissfx）が残っていないことを grep で確認済み。`references/linux.md`・`references/macos.md` への相対リンクは解決する。README.md / README.en.md の追記内容は対応関係が一致
- caller・import整合性: `devices/gui/macbook/home.nix` と `devices/gui/home.nix`（`linux-desktop`・`linux-laptop` から import される共通ファイル）の imports に `secrets-agents.nix` を追加し、いずれも評価成功
- 観察事項（Issue 15 の対象外、対応不要と判断）: `.claude/settings.json` は現状 `secrets-agents/**` の Read/Edit deny のみを持ち、`secrets/**` 全般の deny と `secrets/**/*.json.age` の allow 例外は未配線（Issue 09 の背景に「dotfiles-public はまだ `secrets/*.json.age` を置いていない」とあり、追跡済みの意図的な未着手と判断）。今回公開した `sops-secrets` skill 本文はこの安全網の"設計意図"を説明しており、実際に `secrets/*.json.age` を使い始める際は settings.json 側の配線が別途必要
- `git diff --name-only --cached`: .claude/skills/sops-secrets/SKILL.md, .claude/skills/sops-secrets/references/linux.md, .claude/skills/sops-secrets/references/macos.md, .gitignore, README.en.md, README.md, devices/gui/home.nix, devices/gui/macbook/home.nix, flake.nix, home-manager/modules/secrets-agents.nix（Issue の対象8ファイル + user 裁可済みの.gitignore/flake.nixの計10ファイルで一致）

## 検証手順
- macbook で `git pull` → `darwin-rebuild switch --flake ~/dotfiles#macbook` を実施し、secrets/agents/ が空でも rebuild が壊れないことを確認する
- 実際に `secrets/agents/*.age` を1件置いた状態で、macbook / linux-desktop それぞれで rebuild し、`~/dotfiles/secrets-agents/<stem>` がパーミッション `0400` で復号されることを確認する（暗号文の作成自体は本 PR の範囲外）
