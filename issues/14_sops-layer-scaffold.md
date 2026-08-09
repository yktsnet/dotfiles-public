## sops-nix による secret 管理レイヤの土台を敷く
id: 14
branch-slug: sops-layer-scaffold
github_issue:
status: open
type: feat
対象:
- flake.nix
- devices/secrets.nix (新規)
- .sops.yaml.example (新規)
- .gitignore
- docs-agents/repo-guide.md
- docs-agents/repo-guide.en.md
内容: 本リポの README は Foundation の1つとして「機密情報の分離」を挙げているが、公開しているのは分離した**結果**（`secrets-agents/production-server.md` というサンプル）だけで、実値をどう暗号化して各デバイスへ配るかの機構が無い。sops-nix をフレークに足し、カテゴリごとのディレクトリを自動スキャンして secret を登録する層を公開する。暗号文そのもの（`.age`）は公開しない。
確認: `nix flake check`（評価エラーの検出。`secrets/` が空でも評価が通ること）、目視確認（`.gitignore` が `.sops.yaml` の実体を除外していること、`.sops.yaml.example` に実 age 公開鍵が含まれていないこと、`repo-guide` 日英の記述内容が一致すること）。実際の暗号化・復号は user が自分の age 鍵で行う。

---

### 保証
- 新たに宣言する保証:
  - `secrets/` にカテゴリディレクトリが1つも無い状態でも `nix flake check` が通る（空のスキャン結果として扱われ、評価エラーにならない）
  - `secrets/<カテゴリ>/<名前>.age` を置くと、`secrets.nix` の変更なしに `<カテゴリ>/<名前>` という名前の secret として登録される
  - secret の format はファイル名の拡張子から決まる。`.env.age` は dotenv、`.json.age` は json、それ以外は binary
  - `legacyBinaryCategories` に列挙したカテゴリは、拡張子によらず binary として扱われる
  - 本リポに実際の暗号文（`.age`）と `.sops.yaml` の実体はコミットされない
- 維持する保証:
  - 既存の `nixosConfigurations` / `darwinConfigurations` のビルド対象と評価結果を変えない（sops-nix の module を配線するだけで、既存モジュールの挙動を変えない）
  - `flake.lock` の既存 input のリビジョンを、sops-nix 追加に伴う解決以外で動かさない

**テスト欠落について（裁可済み・見送る）**: 「空でも評価が通る」は `nix flake check` が裏付ける。「拡張子から format が決まる」は評価が通るだけでは検証されず（実際に復号して初めて分かる）、本リポに Nix の評価結果を検査するテスト基盤が無いため裏付けテストを含めない。**「空でも評価が通る」は私物側で踏まれたことのない経路なので、実装時に必ず手で確認すること。**

### 背景

README の Foundation は「公開リポジトリ側のコードや Issue ファイルに本番の IP・ポート・実ホスト名を書かない。実値はローカルの `secrets-agents/` に隔離し、地の文では `<PLACEHOLDER>` を用いる」と書いている。読者が再現できるのはここまでで、**実値そのものをどこにどう置くか**が抜けている。

平文をローカルにだけ置くと、デバイスが増えたときに配れない。かといって平文をリポに置けない。そこで sops（age 鍵）で暗号化した状態でコミットし、各デバイスが自分の鍵で復号する形にする。これが無いと、次の Issue で扱う「マスク辞書をどう全機に配るか」も成立しない。

本 Issue は土台だけを敷く。辞書の配布そのものは Issue 15 で扱う。

### 空の `secrets/` は user が用意する（裁可済み）

`devices/secrets.nix` は `builtins.readDir` でカテゴリディレクトリを走査する。`secrets/` が存在しないと評価時にエラーになるため、公開リポでは空のディレクトリを維持する必要がある。git は空ディレクトリを持てないので `secrets/.gitkeep` を置く。

一方、`.claude/settings.json` は `secrets/` 配下の読み書きを deny している（`.json.age` を除く）。**裁可の結果、`secrets/.gitkeep` は user が置く。** Agent に `secrets/` を触らせない原則を崩さないためで、deny に例外を作らない。

したがって実行者は `secrets/.gitkeep` を作らない。それが無いことで `nix flake check` が通らない場合は、**その時点で報告して止まること**（回避のために `secrets.nix` の走査経路を変えない）。

### 仕様

#### flake.nix

`inputs` に sops-nix を足す。既存の input と同じく `inputs.nixpkgs.follows = "nixpkgs"` を付ける。

```
sops-nix = {
  url = "github:Mic92/sops-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

`darwinConfigurations` の modules に `inputs.sops-nix.darwinModules.sops` を、`nixosConfigurations` 側（`devices/flake-edit.nix`）に NixOS 用の module を配線する。**配線先を1箇所に決めず、既存のモジュール列挙の書式に合わせること。**

`flake.lock` は sops-nix の追加に伴って更新される。既存 input のリビジョンを一緒に動かさない（`nix flake lock --add-input` 相当の最小更新に留める）。

#### devices/secrets.nix（新規）

コピー元: `~/dotfiles/devices/secrets.nix`（45行）。カテゴリを自動スキャンして `sops.secrets` を組み立てる。

移植にあたり次を守る。

- **`legacyBinaryCategories` の中身は私物の履歴に固有**（旧方式で binary 固定になっているカテゴリ名が並んでいる）。公開版では空リストにし、「拡張子による自動判定を使わず binary 固定にしたいカテゴリをここに列挙する」という趣旨のコメントを付ける
- 所有者を決める option（私物では `yktsnet.primaryUser`）は、名前空間を本リポの汎用名に置き換える。既定値も汎用のユーザ名にする
- `hmManagedCategories` による `agents` カテゴリの除外は**残す**。除外の理由（home-manager 側で別の場所へ復号するため、system 側で拾うと二重復号になる）はコメントとして残す。実際に使うのは Issue 15 だが、除外の仕組みごと出しておかないと Issue 15 が土台の変更を伴うことになる
- `secrets/` が空（カテゴリディレクトリが0個）のときに評価が通ること。私物では常に中身があるため、この経路は踏まれていない。**必ず確認すること**

#### .sops.yaml.example（新規）

コピー元: `~/dotfiles/.sops.yaml`。**実体はコミットしない。** age の公開鍵は、それ自体は秘密ではないが、デバイス構成の指紋になるため公開版ではプレースホルダに置き換える。

利用者が自分の鍵で埋められるよう、先頭に次を含むコメントを置く。

- このファイルを `.sops.yaml` としてコピーすること
- `age-keygen` で鍵を作り、公開鍵を `creation_rules` の `age:` に列挙すること
- 既存の `.age` に鍵を足したあとは `find secrets -name "*.age" -exec sops updatekeys --yes {} \;` が要ること

#### .gitignore

`.sops.yaml`（実体）と `secrets/**/*.age` を除外に足す。`.sops.yaml.example` と `secrets/.gitkeep` は追跡対象に残すこと。

#### docs-agents/repo-guide.md / repo-guide.en.md

機密管理の節に、sops レイヤの説明を足す。含めること。

- `secrets/<カテゴリ>/<名前>.age` を置けば `secrets.nix` の変更なしに登録される（カテゴリの追加も設定変更不要）
- format は拡張子で決まる（`.env` → dotenv / `.json` → json / それ以外 → binary）
- 平文の secret はリポにもディスクにも置かない。生ファイルは RAM ディスク上でだけ作る
- 新しいデバイスを足すときは「鍵登録 → 既存 secret の再暗号化 → ビルド」の順を守る。順序を誤ると復号できないまま home-manager が壊れる

運用手順そのものは Issue 15 で公開する skill に持たせるので、ここは**方針の説明に留める**。コマンド列を repo-guide に二重化しない。

### 実装順序

1. `flake.nix` に sops-nix input を足し、`nix flake check`（この時点では module 未配線でも通ること）
2. `devices/secrets.nix`（`legacyBinaryCategories` を空に、option 名を汎用化、空スキャン経路の確認）
3. 各 configuration に sops module を配線し、`nix flake check`
4. `.sops.yaml.example` と `.gitignore`
5. `docs-agents/repo-guide.md` → `repo-guide.en.md`
