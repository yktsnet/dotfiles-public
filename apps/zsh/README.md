# apps/zsh

Zsh 関数の実体になる Python スクリプト。シェル関数側は薄いラッパーに留め、分岐やパースが要るものはこちらに置く。

稼働環境では十数本あり、ここにはフリート運用の骨格になる3本を収めている。

| ファイル | 役割 |
|---|---|
| `system_monitor.py` | 単一ホストの load / メモリ / ディスク / IO wait / NTP オフセットを取り、パイプ区切り1行で出す |
| `fleet_monitor.py` | 複数ホストへ `system_monitor.py` を配って回り、結果を1つの表にまとめる |
| `inject.py` | 生ファイルを sops（age）で暗号化して `secrets/<category>/` へ配置し、元の平文を消す |

## リモートへ配らない

`fleet_monitor.py` はリモートに何もインストールしない。ローカルのスクリプトを標準入力から remote python へ流し込んで実行する。

```python
cmd = f"timeout 5 ssh {user}@{host} 'python3 -u -' < {script_path}"
```

エージェントの常駐も、リモート側のバージョン管理も要らなくなる。監視対象に必要なのは python3 と SSH だけで、スクリプトを直せば次の実行から全ホストに反映される。`timeout` を必ず噛ませ、応答しないホストは `DOWN` として表示する。

監視対象は環境変数 `FLEET` で渡す（実ホスト名と SSH ユーザを公開リポに直書きしないため）。

```bash
FLEET=linux-laptop:ops,linux-server-a:ops python3 apps/zsh/fleet_monitor.py
```

## inject.py

`.sops.yaml` から age 公開鍵を全て抜き（`age1\w+` の重複排除）、拡張子から format を判定する（`.env` → dotenv、`.json` → json、その他 → binary）。暗号化に成功した時点で元の平文ファイルを `unlink()` する。

この「成功したら平文を消す」挙動は運用の順序を縛る。Agent には `sops --decrypt` が許可されていないため、`inject` を実行した時点でその回の平文は取り戻せない。secret のローテーションでは、**同期先への配布を全て終えてから最後に `inject` する**。

```bash
python3 apps/zsh/inject.py <生ファイルパス> <カテゴリ名>
```

生ファイルは RAM ディスク上で作る。ディスクバックの領域に平文を置かない。
