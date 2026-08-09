## PR記録: feat: sops-nix による secret 管理レイヤの土台を敷く
issue: 14 (14_sops-layer-scaffold.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/42
Merged: 99c1252e3971fc0e3de97de0cd1219f45d9f48e6

## 変更内容
- `flake.nix`: `sops-nix` input を追加。`nixosConfigurations` は `devices/flake-edit.nix` の出力に `builtins.mapAttrs` + `extendModules` で `inputs.sops-nix.nixosModules.sops` と `./devices/secrets.nix` を横断的に配線（`devices/flake-edit.nix` 自体は Issue の対象外のため無編集）。`darwinConfigurations.macbook` には `inputs.sops-nix.darwinModules.sops` を追加。
- `devices/secrets.nix`（新規）: `secrets/<カテゴリ>/` を自動スキャンして `sops.secrets` を組み立てる層。`legacyBinaryCategories` は空リストに汎用化（private 側の履歴固有の中身を除去）、所有者オプションは `options.secrets.primaryUser`（既定値 `"user"`）に汎用化。`hmManagedCategories = [ "agents" ]` による二重復号回避の除外は理由コメット付きで維持（Issue 15 で使用）。
- `.sops.yaml.example`（新規）: 実 age 公開鍵はプレースホルダに置換。先頭にコピー手順・鍵生成・re-encrypt コマンドの案内コメントを付与。
- `.gitignore`: `.sops.yaml`（実体）と `secrets/**/*.age` を除外に追加。`.sops.yaml.example` と `secrets/.gitkeep` は対象外（追跡継続）。
- `docs-agents/repo-guide.md` / `repo-guide.en.md`: 機密管理の節に sops レイヤの方針（自動登録・format 判定・平文を置かない・デバイス追加の順序）を追記。運用コマンドは skill 側の管轄として二重化していない。

## 保証
- 「`secrets/` にカテゴリディレクトリが1つも無い状態でも `nix flake check` が通る」→ `nix eval .#nixosConfigurations.linux-laptop.config.sops.secrets --json` を強制評価し `{}` を返すことを確認（`nix flake check` は `config.sops.secrets` を遅延評価のため通過するだけでは検証にならず、直接評価で確認した）。テスト基盤が無いため自動テストは追加していない（Issue に記載の裁可済み欠落）。
- 「`secrets/<カテゴリ>/<名前>.age` を置くと `secrets.nix` の変更なしに登録される」「format はファイル名拡張子で決まる」「`legacyBinaryCategories` は拡張子によらず binary」→ なし（実際に復号して初めて分かるため、Issue で裁可済みのテスト欠落）
- 「本リポに実際の暗号文と `.sops.yaml` の実体はコミットされない」→ `git check-ignore` で `.sops.yaml` / `secrets/**/*.age` が除外対象であることを確認。今回のコミットに `.age` ファイルと `.sops.yaml` の実体は含まれない
- 「既存の nixosConfigurations / darwinConfigurations のビルド対象と評価結果を変えない」→ `nix flake check` で全 nixosConfigurations（linux-laptop / linux-desktop / linux-server-a / linux-server-b / linux-netboot）と darwinConfigurations.macbook が変更前と同じ集合で評価に成功
- 「flake.lock の既存 input のリビジョンを、sops-nix 追加に伴う解決以外で動かさない」→ `git diff -- flake.lock` で `sops-nix` エントリの追加のみであることを確認（既存 input の rev は無変更）

## 静的確認結果
- `nix flake check --no-build`: 成功（nixosConfigurations 5件 + darwinConfigurations.macbook すべて評価成功、warning のみで error 無し）
- `nix eval .#nixosConfigurations.linux-laptop.config.sops.secrets --json`: `{}`（secrets/ が空でも評価エラーにならないことを直接確認）
- `nix eval .#darwinConfigurations.macbook.config.sops.package`: 評価成功（sops モジュールが darwin 側にも配線されていることを確認）
- `.sops.yaml.example` に実 age 公開鍵が含まれないことを目視確認（プレースホルダのみ）
- `repo-guide.md` / `repo-guide.en.md` の追記内容が日英で一致することを目視確認
- caller/import 整合性: `devices/secrets.nix` は `flake.nix` からのみ import され、`config.secrets.primaryUser` と `config.sops.secrets` はいずれも sops-nix モジュールが提供するので未定義参照は無し
- `nix fmt`: このリポジトリに `formatter` output が定義されておらず変更前から実行不可（今回の変更が原因ではない）
- `git diff --name-only --cached`: `.gitignore` / `.sops.yaml.example` / `devices/secrets.nix` / `docs-agents/repo-guide.en.md` / `docs-agents/repo-guide.md` / `flake.lock` / `flake.nix`
  - Issue の「対象」一覧と一致。`flake.lock` のみ一覧に無いが、`sops-nix` input 追加に伴う `nix flake check` の不可避な副作用であり、ユーザーの了承を得たうえで含めている
  - `secrets/.gitkeep` は本コミットに含まない（Issue の指示通り user が別コミットで用意済み：`ca7011d`）

## 検証手順
実際の暗号化・復号は各デバイスの age 鍵で user が行う。
1. `.sops.yaml.example` を `.sops.yaml` としてコピーし、`age-keygen` で生成した公開鍵を列挙する
2. `secrets/<カテゴリ>/<名前>.age` を1件置き、対象デバイスで `home-manager switch` / `nixos-rebuild switch` を実行して復号・配置を確認する
