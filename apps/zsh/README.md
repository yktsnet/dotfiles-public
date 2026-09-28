# apps/zsh

運用の Python スクリプト。分岐やパースが要る処理をシェルに書かず、こちらに置く。

稼働環境では十数本あり、ここには機密の分離を支える1本を収めている。

| ファイル | 役割 |
|---|---|
| `inject.py` | 生ファイルを sops（age）で暗号化して `secrets/<category>/` へ配置し、元の平文を消す |

## inject.py

`.sops.yaml` から age 公開鍵を全て抜き（`age1\w+` の重複排除）、拡張子から format を判定する（`.env` → dotenv、`.json` → json、その他 → binary）。暗号化に成功した時点で元の平文ファイルを `unlink()` する。

この「成功したら平文を消す」挙動は運用の順序を縛る。Agent には `sops --decrypt` が許可されていないため、`inject` を実行した時点でその回の平文は取り戻せない。secret のローテーションでは、**同期先への配布を全て終えてから最後に `inject` する**。

```bash
python3 apps/zsh/inject.py <生ファイルパス> <カテゴリ名>
```

生ファイルは RAM ディスク上で作る。ディスクバックの領域に平文を置かない。

## digest

はてブ・Zenn・GitHub Trending の記事を Telegram へ届ける日次 digest は、[yktsnet/tg-dev-digest](https://github.com/yktsnet/tg-dev-digest) に切り出した。
