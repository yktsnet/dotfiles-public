# SOPS・秘密情報・デバイス追加 運用マニュアル（Linux版）

## 設計の前提

- `secrets/` 配下のファイルはすべて `sops` で暗号化してからコミットする
- `inject` コマンドで暗号化・配置を一括処理する
- `devices/secrets.nix` がディレクトリを自動スキャンして全secretを登録する
- format はカテゴリ単位で決まる（新カテゴリは拡張子で自動判定）

---

## 1. secretを追加する（通常運用）

### 手順
```bash
# 1. RAMディスク上で生ファイルを作成・編集
hx /dev/shm/filename.env   # または .json / その他

# 2. 暗号化してdotfilesに配置（.age拡張子が自動で付く）
python3 ~/dotfiles/apps/zsh/inject.py /dev/shm/filename.env <カテゴリ名>
# → secrets/<カテゴリ名>/filename.env.age が生成される

# 3. 生成確認
ls ~/dotfiles/secrets/<カテゴリ名>/
# filename.env.age が存在すること（.env のみでは不可）

# 4. dotfilesにコミット
cd ~/dotfiles && git add -A && git commit -m "..."
```

### カテゴリとformat対応

| カテゴリ | format | 備考 |
|---|---|---|
| `legacyBinaryCategories`（`devices/secrets.nix`）所属 | binary | 拡張子によらず binary 固定 |
| それ以外の全カテゴリ | 拡張子で自動判定 | `.env`→dotenv, `.json`→json, その他→binary |

### 新カテゴリを追加するとき

`devices/secrets.nix` の変更は不要。`inject` で新カテゴリに入れるだけで自動登録される。

ただし新カテゴリが `legacyBinaryCategories` に含まれていないことを確認する：

```bash
grep "legacyBinaryCategories" ~/dotfiles/devices/secrets.nix
```

---

## 2. 復号確認
```bash
# dotenv形式
sops --decrypt --input-type dotenv --output-type dotenv secrets/<カテゴリ>/<ファイル名>.env.age

# binary形式（legacyBinaryCategories 所属カテゴリ）
sops --decrypt --output-type binary secrets/<カテゴリ>/<ファイル名>.age
```

---

## 3. 新デバイスを追加する

### 前提：失敗パターンを知る

新デバイス追加時にビルドは通るが起動後にユーザ環境の初期化が壊れる原因は**SOPSのデッドロック**。

```
新デバイスの公開鍵 → .sops.yaml未登録
→ secretが復号できない
→ Home Managerのsecret参照モジュールが失敗
→ GUI/シェル設定が壊れてTTY送り
```

これを避けるために**鍵登録 → 既存secret再暗号化 → ビルド**の順を守る。

### 手順

#### A. ディスクの初期化

```bash
sudo wipefs -af /dev/nvme0n1
sudo partprobe /dev/nvme0n1
```

#### B. 手動パーティション構築（TRIM回避）

特定SSDはTRIM要求でハングすることがあるため `--nodiscard` を使う。

```bash
sudo mkfs.btrfs -f --nodiscard /dev/disk/by-partlabel/disk-main-root

sudo mount /dev/disk/by-partlabel/disk-main-root /mnt
sudo btrfs subvolume create /mnt/root
sudo btrfs subvolume create /mnt/home
sudo btrfs subvolume create /mnt/nix
sudo umount /mnt

sudo mount -t btrfs -o subvol=/root /dev/disk/by-partlabel/disk-main-root /mnt
sudo mkdir -p /mnt/{home,nix,boot}
sudo mount -t btrfs -o subvol=/home /dev/disk/by-partlabel/disk-main-root /mnt/home
sudo mount -t btrfs -o subvol=/nix,compress=zstd,noatime /dev/disk/by-partlabel/disk-main-root /mnt/nix
sudo mount /dev/disk/by-partlabel/disk-main-ESP /mnt/boot
```

#### C. SOPSの鍵を先に焼き付ける（重要）

OSインストール前にこれをやらないとユーザ環境が壊れる。

```bash
sudo mkdir -p /mnt/var/lib/sops-nix
nix-shell -p ssh-to-age --run \
  "sudo cat /etc/ssh/ssh_host_ed25519_key | ssh-to-age -private-key" \
  | sudo tee /mnt/var/lib/sops-nix/key.txt > /dev/null
sudo chmod 600 /mnt/var/lib/sops-nix/key.txt
```

#### D. 管理用 Linux 機からリモートビルドでインストール

```bash
# 管理用 Linux 機（linux-desktop 等）から実行
nix run github:nix-community/nixos-anywhere -- \
  --flake ".#<hostname>" \
  --phases install \
  root@<target_ip>
```

#### E. 新デバイスの公開鍵を信頼の輪に追加

新デバイス起動後、SSHホスト鍵からage公開鍵を取得する：

```bash
# 新デバイス上で
nix-shell -p ssh-to-age --run \
  "cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age"
```

取得した公開鍵を `.sops.yaml` に追加：

```yaml
keys:
  - &newdevice age1xxxx...
creation_rules:
  - path_regex: secrets/.*$
    key_groups:
      - age:
          - *newdevice
          # 既存キーも全部残す
```

#### F. 既存secretを全て再暗号化（重要）

`.sops.yaml` を更新しただけでは既存ファイルに新デバイスの鍵が含まれない。必ず再暗号化する：

```bash
cd ~/dotfiles
find secrets -name "*.age" -exec sops updatekeys --yes {} \;
```

#### G. dotfilesをコミットして新デバイスに反映

```bash
git add -A && git commit -m "add <hostname> to sops"
```

新デバイスは `git pull` した上でビルドすれば secret を復号できる（ビルド自体は user が実施）。

---

## 4. トラブルシューティング

### secretが `/run/secrets/` に出ない

```bash
# manifestに登録されているか確認
sudo cat $(sudo cat /run/current-system/activate | grep manifest | grep -o '/nix/store/[^ ]*') \
  | python3 -m json.tool | grep -A6 "問題のカテゴリ"

# formatが正しいか確認
grep "legacyBinaryCategories\|detectFormat" ~/dotfiles/devices/secrets.nix
```

### `cannot parse dotenv` エラー

原因: binary形式で暗号化されたファイルをdotenvとして読もうとしている。

対処: そのカテゴリを `legacyBinaryCategories` に追加するか、ファイルをdotenv形式で再暗号化する。

### `unexpected end of JSON input`

原因: 暗号化ファイルが0バイト。

対処: `inject` を再実行して上書きする。

### `access to absolute path '/run' is forbidden`

原因: Pure evaluation中に絶対パスを参照した。

対処: `config.lib.file.mkOutOfStoreSymlink` を使って遅延評価させる。

---

## 5. Home ManagerでのSecret参照

システム側secretをHome Managerから参照する場合は `osConfig` を経由する：

```nix
home.file.".ssh/id_ed25519".source =
  config.lib.file.mkOutOfStoreSymlink
    osConfig.sops.secrets."common/id_ed25519.txt".path;
```

`/run/secrets/...` を直接文字列で書いてはいけない。必ず `config.sops.secrets.KEY.path` を使う。
