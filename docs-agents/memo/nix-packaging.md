# nixpkgs に無いツールを Nix 管理で入れる

「便利ツールを突発的に入れたい。でも `npx` / `pip install` 直叩きは他が全部 Nix 管理なのに一貫性を欠く」——その時の定石。
原則: **nixpkgs に在ればそれを使う。無ければ derivation を書いて `home.packages` に載せる。** 素の `npx` 常用やグローバル npm/pip は避ける（再現性が壊れる）。

最初に在庫確認:

```sh
nix eval nixpkgs#<pkg> --raw 2>&1 | head   # 在れば即採用
npm view <pkg> version bin                  # npm 製か・bin 名の確認
```

---

## Python ツール — 手本 `apps/env-context.nix` の `notebooklm-py`

`fetchFromGitHub` + 固定 hash + `buildPythonApplication`。

```nix
pkgs.python3Packages.buildPythonApplication rec {
  pname = "...";
  version = "x.y.z";
  pyproject = true;
  src = pkgs.fetchFromGitHub {
    owner = "..."; repo = "..."; rev = "vx.y.z";
    hash = "sha256-...";   # 初回は lib.fakeHash → エラーに出る実値を埋める
  };
  build-system = with pkgs.python3Packages; [ hatchling ];
  dependencies = with pkgs.python3Packages; [ httpx click ];
  doCheck = false;
}
```

ランタイムにブラウザ等の外部資産が要る場合は `symlinkJoin` + `makeWrapper` でラップ（同ファイルの `notebooklm-wrapped` 参照）。

---

## npm / node ツール — `buildNpmPackage`

Python 版の node 版。`package-lock.json` が要る。

```nix
pkgs.buildNpmPackage rec {
  pname = "...";
  version = "x.y.z";
  src = pkgs.fetchFromGitHub {
    owner = "..."; repo = "..."; rev = "vx.y.z";
    hash = "sha256-...";
  };
  npmDepsHash = "sha256-...";   # FOD。初回 lib.fakeHash → ビルドエラーの実値を埋める
  dontNpmBuild = false;         # ビルド要否はパッケージ次第
}
```

`npmDepsHash` は src の `package-lock.json` から計算される固定出力。lock が無いタグだと通らない → 下のフォールバックへ。

---

## フォールパック — `writeShellScriptBin` で npx ラップ

lockfile が無い／derivation 化が重すぎる時。純粋性は落ちるがバージョン固定の Nix 管理は保てる。
既存例: `home-manager/modules/waybar.nix`・`desktop/swww-random.nix`。

```nix
pkgs.writeShellScriptBin "<name>" ''
  exec ${pkgs.nodejs}/bin/npx --yes <pkg>@x.y.z "$@"
''
```

---

## 配線（どこに載せるか）

- 単独ツールは `home-manager/modules/<name>.nix` を新規作成し、その中で derivation 定義 + `home.packages = [ pkg ];`。
- それを必要なデバイスに import する。経路は2つ:
  - GUI 共通: `home-manager/modules/desktop/gui-bundle.nix` の `imports`。
  - デバイス個別: `devices/gui/<host>/home.nix` の `imports` か `home.packages` 直書き。
- どのホストで使うかを決めてから配線する（全ホストに撒かない）。

## 静的チェック

`nix-instantiate --parse <file>`（構文）。実ビルド確認（`home-manager build` / `nix flake check`）は user に委ねる。
hash 解決は実ビルドが要るので、初回 `lib.fakeHash` 埋め直しは検証手順に明記して渡す。
