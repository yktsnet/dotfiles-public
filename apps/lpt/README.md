# apps/lpt

フリート横断で保証台帳（`docs/guarantees.md`）を1箇所に集約する道具の置き場。

保証台帳は各リポの `docs/guarantees.md` に正本があり、複数リポを並行して回すと散らばる。ここに置くスクリプトは、複数のディレクトリを走査して見つけた台帳への symlink を1つのディレクトリへ張ることで、フリート全体で今何を約束しているかを一望できるようにする。

稼働環境ではリモート同期・ブラウザ経由の抽出など固有の接続情報を含むスクリプトが同居しているが、それらは公開しない。ここには公開できる `link_guarantees.py` のみを置く。

| ファイル | 役割 |
|---|---|
| `link_guarantees.py` | 走査対象を優先順位付きで見て、見つかった `docs/guarantees.md` への symlink を集約先へ張る |

## link_guarantees.py

実体はコピーせず symlink を張る。正本は各リポに残したまま、集約先だけを見ればフリート全体の保証を一望できるようにするため。

環境変数3つでパスを受け取る。コード内にはハードコードされた個人のディレクトリ名を持たない。

| 環境変数 | 意味 | 既定値 |
|---|---|---|
| `GUARANTEES_TARGET_DIR` | symlink を集める先 | `~/guarantees` |
| `GUARANTEES_SEARCH_DIRS` | 走査対象。`:` 区切り。**列挙の順序がそのまま優先順位になる**（同名リポが複数の走査対象で見つかったとき、先に書いた方が接頭辞なしの名前を取り、後の方には走査元ディレクトリ名の接頭辞が付く） | `$HOME` のみ |
| `GUARANTEES_CACHE_FILE` | 前回の集約状態（リンク名 → パスと mtime）を記録するキャッシュ | `~/.cache/lpt_guarantees_state.json` |

前回実行時から台帳の集合と各ファイルの mtime のどちらも変わっていなければ、symlink を張り直さずに終了する。

ローカルでは環境変数を渡して直接実行する。

```bash
GUARANTEES_TARGET_DIR=~/guarantees GUARANTEES_SEARCH_DIRS=~/github-public:~/github-private python3 apps/lpt/link_guarantees.py
```

home-manager では `home-manager/modules/guarantees.nix` が rebuild のたびにこのスクリプトを呼ぶ。
