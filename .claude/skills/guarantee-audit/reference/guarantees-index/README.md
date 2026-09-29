# guarantees-index

フリート横断で保証台帳（`docs/guarantees.md`）の索引を作る道具の置き場。

保証台帳は各リポの `docs/guarantees.md` に正本があり、複数リポを並行して回すと散らばる。ここに置くスクリプトは GitHub API で各リポを調べ、台帳を持つリポへの GitHub 上のリンクを1枚の Markdown に並べる。端末のディレクトリ配置に依存せず、GitHub 上でそのまま読める。

| ファイル | 役割 |
|---|---|
| `guarantees-index.sh` | トークンの持ち主が所有するリポ（archive・fork を除く）から台帳を探し、索引を書き出す |
| `workflow.yml` | 週1回と手動でスクリプトを走らせ、索引が変わったときだけコミットする GitHub Actions の雛形 |

## 使い方

1. 索引を置くリポを決め、`guarantees-index.sh` を `.github/scripts/`、`workflow.yml` を `.github/workflows/guarantees-index.yml` にコピーする
2. Fine-grained token を作る。Repository access は All repositories、Permissions は Contents の Read-only
3. そのリポの Actions secret に `GUARANTEES_TOKEN` として登録する
4. `gh workflow run guarantees-index` で1回走らせ、`guarantees/README.md` ができることを確かめる

出力先は環境変数 `GUARANTEES_OUT` で変えられる（既定 `guarantees/README.md`）。

ローカルでは `gh` にログインした状態で直接実行できる。

```bash
bash .claude/skills/guarantee-audit/reference/guarantees-index/guarantees-index.sh
```
