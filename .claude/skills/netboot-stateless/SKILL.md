---
name: netboot-stateless
description: NixOS のディスクレス機を netboot（PXE / pixiecore）で配信・起動する運用手順。無状態（tmpfs root）デバイスを追加・再配信・ビルドするとき、initrd の肥大化やカーネルパニック等の netboot 系エラーを対処するときに使用する。
---

# netboot-stateless

ディスクレス機はストレージを使わず、ルートを RAM（tmpfs）に展開する完全無状態運用。NixOS の世代保持をあえて捨て、最新1世代のみを配給する。ビルドは GUI 機で行い、ターゲットは PXE で受信・展開することに専念する。

構成は `devices/headless/diskless/` にある。tmpfs root・`boot.loader.grub.enable = false`・initrd 圧縮の指定は `diskless/system.nix` に集約し、機体固有の設定は `diskless/<device>/` に置く。

## 構成の選び方

| ベース | 対象 | 特徴 |
|---|---|---|
| `devices/gui/` | GUI ありのディスクレス機 | Hyprland・Waybar 等を含むフルセット |
| `devices/headless/diskless/` | CLI のみのディスクレス機 | 最小構成。システムツール・Python・Zsh・Git のみ |

新規ディスクレス機は `devices/headless/diskless/system.nix` をベースに、機体ごとの `hardware.nix` を組み合わせる。

## 配信フロー

`toplevel` だけでは配給できない。kernel / initrd / ipxe スクリプトを個別にビルドする。

```bash
host=<device>
nix build ".#nixosConfigurations.${host}.config.system.build.toplevel"
nix build ".#nixosConfigurations.${host}.config.system.build.netbootIpxeScript" --out-link result-ipxe
nix build ".#nixosConfigurations.${host}.config.system.build.netbootRamdisk"    --out-link result-initrd
nix build ".#nixosConfigurations.${host}.config.system.build.kernel"            --out-link result-kernel
```

`init=` のパスはビルドごとに変わる。固定値を書かず `result-ipxe/netboot.ipxe` から動的に抽出し、`toplevel/kernel-params` の内容と併せて `--cmdline` に渡す。

```bash
sudo nix run nixpkgs#pixiecore -- boot \
  result-kernel/bzImage result-initrd/initrd \
  --cmdline "${kernel_params} ${init_path} ip=dhcp" --dhcp-no-bind --debug
```

ターゲットは BIOS で PXE Boot を最優先にして電源投入する。

## 制約と地雷（4GB RAM 機）

- **initrd は 1GB 未満が絶対条件**。`boot.initrd.compressorArgs = [ "-19" "-T0" ]`（`diskless/system.nix`）は最適化ではなく生存条件で、怠ると展開時に No space left on device でカーネルパニックになる
- RAM の配分は `RAM合計 > initrd + 実行時ワークスペース` で見る。イメージが重いと起動はしても作業領域が残らない
- GUI 構成から headless を派生させると `sops.secrets` 等の Duplicate definition が出やすい。不要な secret・サービスは明示的に除外する
- 再配信ではターゲットが旧世代のまま稼働し続ける。配信スクリプトに SSH 経由の強制 reboot を組み込み、必ずタイムアウトを設定する（応答しない機体で待ち続けないため）

## ホスト側の注意

pixiecore は DHCP / TFTP を扱うため、配信中はビルドホストのファイアウォールを一時停止する。停止したまま放置しないよう、配信の完了・失敗の両方で復帰させる。
