## PR記録: fix: tmux のエージェント表示と M-u ピッカーで status `shell` を idle として扱う
issue: 20 (20_tmux-agent-shell-status.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/75

## 変更内容
Claude Code はターンを終えてバックグラウンドのシェルやサブエージェントだけが残っている状態を `claude agents --json` の `status: "shell"` で報告する。user の番なのに、status-right のチップは作業中の色（赤系）になり、M-u ピッカーは未知の状態として灰色の `?` を出していた。どちらも `shell` を idle と同じ扱いにした。

- `agentStatus`（status-right）: `rank` と `chip` の両方で `shell` を idle と同じ分岐に入れた。チップの色・区別は付けない（既存のチップ幅を動かさない要件のため）。
- `claudeSessionManager`: `postInstall` で `scripts/agents.sh` に `--replace-fail` を使い `shell` の分岐を追加し、緑の `idle+sh`（既存ラベルと同じ7文字）として rank 1 で表示する。

対象外: status-right 以外の `claude agents` の利用箇所（nudge ピッカーは status を文字列のまま表示するだけ）。プラグインの rev 更新。

## 保証
- status-right で `status: "shell"` のエージェントのチップが idle と同じ色・並び順（waiting の後、作業中の前）になる → jq での手動確認（下記）
- M-u ピッカーで `status: "shell"` のエージェントが緑の `● idle+sh` として idle と同じ順位に並ぶ → `--replace-fail` の対象文字列をプラグイン rev `ac3470e` の実ファイルから取得し、一致・置換結果を手動確認（下記）
- 維持する保証（waiting・idle・busy の色と並び順、status 無しセッションの非表示、未知 status の扱い）→ 自動テスト無し。このリポに tmux 表示を検査する仕組みが無いため

自動テストは無い（tmux の表示を検査する仕組みがこのリポに無い）。

## 静的確認結果
- `nix flake check`: ✅ darwinConfigurations.macbook（評価のみ、build skipped・既存の挙動）。パス外の pre-existing deprecation warning のみ
- caller/import 整合性: `claudeSessionManager` / `agentStatus` は `home-manager/modules/tmux.nix` 内でのみ参照される（他ファイルからの参照なし、grep で確認）
- jq 確認: `shell` を含むサンプル JSON（waiting/idle/shell/busy/null status）を status-right の jq 式に通し、`shell` のチップが idle と同じ色 `#5de4c7` で waiting の後・busy の前に並ぶことを確認
- agents.sh の置換確認: プラグイン rev `ac3470e` の実ファイルを取得し、`--replace-fail` の対象文字列 `else if ($3 == "busy")` が一意に1箇所存在すること、置換後も `bash -n` で構文エラーが無いこと、awk の分岐を抽出して `shell` → `rank=1` / 緑アイコン `idle+sh`（既存ラベルと同じ7文字幅）になることを確認
- crit によるレビュー: 指摘なしで approve

変更ファイル: home-manager/modules/tmux.nix

## 検証手順
- macbook で rebuild したあと、Claude にバックグラウンドのコマンド（例: `sleep 60` を `run_in_background` で）を走らせてターンを終えさせる
- その間、status-right のチップが idle の色になり、M-u に `● idle+sh` と出ることを目視で確かめる

---

## tmux のエージェント表示と M-u ピッカーで、status `shell` を idle として扱う
id: 20
branch-slug: tmux-agent-shell-status
github_issue:
status: close
type: fix
対象:
- home-manager/modules/tmux.nix（L8-18 の `claudeSessionManager`、L144-166 の `agentStatus`）
内容: Claude Code はターンを終えてバックグラウンドのシェルやサブエージェントだけが残っている状態を `claude agents --json` の `status: "shell"` で報告する。user の番なのに、status-right のチップは作業中の色（赤系）になり、M-u ピッカーは未知の状態として灰色の `?` を出す。どちらも `shell` を idle と同じ扱いにする。
対象外: status-right 以外の `claude agents` の利用箇所（L110 付近の nudge ピッカーは status を文字列のまま表示するだけなので触らない）。プラグインの rev 更新。
仮定: status-right のチップには `shell` を区別する印を付けない。既存のコメントが「状態が変わってもチップ幅が動かない」ことを求めているため、区別は M-u ピッカーの表示（`idle+sh`）で行う。
確認: `nix flake check`。あわせて、下の jq 式に `shell` を含むサンプル JSON を流し、`shell` のチップが idle の色で idle と同じ順位に並ぶことを確かめる。

---

### 保証
- 新たに宣言する保証:
  - status-right で、`status: "shell"` のエージェントのチップが idle と同じ色で表示され、並び順も idle と同じ位置（waiting の後、作業中の前）になる
  - M-u ピッカーで、`status: "shell"` のエージェントが緑の `● idle+sh` として表示され、idle と同じ順位に並ぶ
- 維持する保証:
  - waiting・idle・busy の色と並び順は変わらない
  - status を持たないセッション（Remote Control）は、引き続きどちらの表示にも出ない
  - waiting・idle・busy・shell 以外の未知の status は、status-right では作業中の色、M-u では灰色の `?` のままになる

自動テストは無い（tmux の表示を検査する仕組みがこのリポに無い）。上の jq の確認と、user の rebuild 後の目視で確かめる。

### `agentStatus`（L150-166）

`rank` と `chip` の両方で `shell` を idle と同じ分岐に入れる。`else`（作業中扱い）に落とさない。L144 からのコメントに、`shell` が何を表すか（ターンを終え、バックグラウンドの作業だけが残っている状態）を1行足す。

### `claudeSessionManager`（L8-18）

`postInstall` を足し、プラグインの `scripts/agents.sh` の状態判定に `shell` の分岐を入れる。`--replace-fail` は一致しないとビルドが落ちるので、文字列は次のとおりにする（プラグインの rev `ac3470e` の `agents.sh` で一致を確認済み）。

```nix
    # `shell` はターンを終えてバックグラウンドの作業だけが残っている状態で、user の番である。
    # プラグインは知らない状態として灰色の ? にするので、idle と同じ扱いの分岐を足す。
    postInstall = ''
      substituteInPlace $target/scripts/agents.sh \
        --replace-fail 'else if ($3 == "busy")' 'else if ($3 == "shell")   { icon = "\033[32m●\033[0m idle+sh"; rank = 1 } else if ($3 == "busy")'
    '';
```

`idle+sh` は既存のラベル（`waiting` / `idle   ` / `working`）と同じ7文字なので、列はずれない。

## 検証手順（PR 本文用）
- macbook で rebuild したあと、Claude にバックグラウンドのコマンド（例: `sleep 60` を `run_in_background` で）を走らせてターンを終えさせる
- その間、status-right のチップが idle の色になり、M-u に `● idle+sh` と出ることを目視で確かめる
