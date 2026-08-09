[🇯🇵 日本語](repo-guide.md) | [🇬🇧 English](repo-guide.en.md)

# Repo Guide

リポジトリの組成・衛生ガイド。新規リポを作るとき、および push / 公開前に点検するときに適用する。
「repo に何のファイルが存在し、何が存在してはいけないか」だけを扱う。

他ガイドと責務を分ける（重複させない）。

| 管轄 | ガイド |
|---|---|
| `.claude/` 配下（settings.json・CLAUDE.md・context/・skills） | `harness-guide.md` |
| README の中身 | `readme-guide.md` |
| デプロイ方式・ホスト側 `.env`（本番値） | `cicd-guide.md` |
| ブランチ・Issue・コミットのプロセス | `issue-driven-workflow.md` |
| **repo ルートの組成・ファイル衛生**（本書） | `repo-guide.md` |

設計意図は1点。**全リポ一律の衛生ラインを1本持つ**。軽い repo でも最低ラインは必ず満たす。成熟度で分岐させない。

---

## 1. ファイル衛生（存在のルール）

- **0 バイト／プレースホルダだけのファイルを残さない。** 中身が無いものは commit しない。枠だけ作って放置しない。
- **成果物を tracking しない。** ビルドバイナリ・`dist/`・`*.db`・`node_modules/`・`.env` は `.gitignore` で除外する。「ローカルに在ってよいが repo に入ってはいけない」を徹底する。
- **生成物と原本を分離する。** 原本（設定の JSON 等）は tracking、そこから生成される DB・ビルド資産は ignore。
- **LICENSE を必ず置く。** 公開 repo に license が無いと法的に全権留保（誰も使えない）になるため、社会的運用の有無に関わらず法的明示の最低ラインとして置く。`Copyright` の年・owner が正しいことまで確認する（コピペ放置をしない）。

---

## 2. `.gitignore` の基準

- **そのスタックに必要な行だけを書く。** 他スタックの boilerplate（無関係な WordPress / Python / Docker 等）をテンプレ流用のまま残さない。流用したら必ず掃除する。
- 重複行を残さない（同じパスを複数回書かない）。
- 最低限カバーする対象: OS ファイル / 依存（`node_modules` 等）/ ビルド成果物 / ローカル DB / `.env`。

---

## 3. シークレット（repo 面）

- `.env` は ignore し、**`.env.example` を必ず置く**（実値なし、キーのみ）。
- 人間が読む地の文に固有接続情報を直書きしない（マスク規約は `issue-driven-workflow.md` の情報セキュリティ節）。
- ホスト側に置く本番 `.env` は repo の管轄外（`cicd-guide.md`）。

### sops レイヤ（実値の暗号化配布）

`.env.example` は「repo にキーだけ置く」までを扱う。実値そのものを各デバイスへどう配るかは sops-nix（age 鍵による暗号化）の管轄で、方針は次の通り。

- `secrets/<カテゴリ>/<名前>.age` を置けば、設定ファイル側の変更なしに `<カテゴリ>/<名前>` という secret として登録される。カテゴリの追加も設定変更不要。
- format はファイル名の拡張子で決まる（`.env` → dotenv / `.json` → json / それ以外 → binary）。
- 平文の secret は repo にもディスクにも置かない。生ファイルは RAM ディスク上でだけ作られる。
- 新しいデバイスを足すときは「鍵登録 → 既存 secret の再暗号化 → ビルド」の順を守る。順序を誤ると復号できないまま home-manager が壊れる。

暗号文（`.age`）と `.sops.yaml` の実体は repo にコミットしない。運用コマンドは skill 側の管轄で、本書はここまで（方針の説明）に留める。

---

## 4. 公開前チェックリスト

push / 公開前に走らせる。

```
[ ] 0 バイト/プレースホルダのみのファイルがない
[ ] tracking 済みに成果物(バイナリ/dist/db/node_modules)が無い  (git ls-files で確認)
[ ] .gitignore に無関係スタックの残骸・重複行が無い
[ ] .env が tracking されておらず、.env.example がある
[ ] LICENSE が存在し、年/owner が正しい
[ ] 地の文にシークレット直書きが無い
```
