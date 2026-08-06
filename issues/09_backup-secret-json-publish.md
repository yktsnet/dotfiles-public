## secrets バックアップ用 PreToolUse フック backup-secret-json.sh を公開反映する
id: 09
branch-slug: backup-secret-json-publish
github_issue:
status: open
type: feat
対象:
- .claude/hooks/backup-secret-json.sh (新規)
- .claude/settings.json
- docs-agents/harness-guide.md
- docs-agents/harness-guide.en.md
内容: 私物 `~/dotfiles` の `.claude/hooks/backup-secret-json.sh`（`secrets/**/*.json.age` を Edit/Write で上書きする直前にバックアップを取る PreToolUse フック）を dotfiles-public に未公開のまま使っていたため、本リポに反映する。`.claude/settings.json` の配線と、`docs-agents/harness-guide.md`／`.en.md` のフック一覧表に追記する。
確認: `zsh -n .claude/hooks/backup-secret-json.sh`（構文チェック）、目視確認（`.claude/settings.json` の JSON 構文・配線位置、`harness-guide.md`／`.en.md` の表記整合性）。`nix flake check` は対象外（Nix ファイル変更なし）。

---

### 保証
- 保証: なし（フックスクリプト追加であり、動作保証は user が実際の `secrets/**/*.json.age` 編集時に目視確認する。裏付けるテストはリポに存在せず、`zsh -n` は構文チェックのみ）

### 背景

私物 `~/dotfiles` の `.claude/hooks/backup-secret-json.sh` は、`settings.json` が `secrets/**/*.json.age` の Read/Edit を例外的に許可している（常に sops の暗号文で平文が見えないため）ことを前提に、Agent が暗号文を壊す編集をしても復元できるよう、上書き直前に `.bak.<timestamp>` を作るバックアップフック。内容にドメイン実値・固有パス等の機密は含まれておらず、汎用的なフックとしてそのまま公開できる。

dotfiles-public 自体は現時点で `secrets-agents/`（機密辞書、読み書き禁止）のみを持ち、sops で暗号化した `secrets/*.json.age` は置いていない。本フックは「他者がこのリポをテンプレートとして自分の `secrets/` 運用を組んだときに効く」ハーネス部品として公開する（`docs-agents/` 配下の他ドキュメントと同じ、テンプレート/ガイド層としての位置づけ）。

### 仕様

#### .claude/hooks/backup-secret-json.sh（新規）

コピー元: `~/dotfiles/.claude/hooks/backup-secret-json.sh`。全28行、固有情報なしのためそのまま移植する。

```sh
#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): secrets/**/*.json.age を上書きする直前にバックアップを取る。
#
# settings.json は secrets/ 配下を deny しているが、JSON 形式（*.json.age）だけは
# Read/Edit/Write を許可している（常に sops の暗号文であり平文が見えないため）。
# その例外を踏むのがこのフック。Agent が暗号文を壊す編集をしても、
# *.json.age.bak.<timestamp> から復元できる状態を保つ。
#
# 遮断はしない。バックアップに失敗しても編集自体は通す（安全網であって関門ではない）。
file_path=$(jq -r '.tool_input.file_path // ""')

case "$file_path" in
  */secrets/*.json.age) ;;
  *) exit 0 ;;
esac

# 新規作成なら退避するものがない
[ -f "$file_path" ] || exit 0

cp -p "$file_path" "${file_path}.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null

# 世代が無限に増えないよう、直近5世代だけ残す
ls -1t "${file_path}".bak.* 2>/dev/null | tail -n +6 | while IFS= read -r old; do
  rm -f "$old"
done

exit 0
```

実行権限（`chmod +x`）を他の `.claude/hooks/*.sh` と同様に付与すること。

#### .claude/settings.json

`hooks.PreToolUse` 内、既存の `matcher: "Edit|Write"` エントリ（`block-live-claude-config-edit.sh` と `block-project-scoped-memory.sh` が並んでいるブロック）の `hooks` 配列に、以下を1エントリ追加する（私物 `~/dotfiles/.claude/settings.json` の配線と同じ形。挿入順は任意でよいが、既存2件との並びを崩さないこと）:

```json
{
  "type": "command",
  "command": "$CLAUDE_PROJECT_DIR/.claude/hooks/backup-secret-json.sh",
  "timeout": 10,
  "statusMessage": "secret上書き前にバックアップ中"
}
```

#### docs-agents/harness-guide.md

95行目以降の「### 3.5 フック（`.claude/hooks/`）」節、103〜108行目のフック一覧表に1行追加する。既存行（`block-project-scoped-memory.sh` の行など）と同じ書式・文体で、以下の内容を表す行を追記する:

| フック | トリガー | 何を防ぐか |
| --- | --- | --- |
| `backup-secret-json.sh` | PreToolUse `Edit\|Write` | `secrets/**/*.json.age` の上書き前にバックアップ（遮断ではなく安全網。直近5世代のみ保持） |

挿入位置は表の末尾（`opus-scope-and-concision.sh` の行の後）でよい。

#### docs-agents/harness-guide.en.md

対応する英語版の表（103〜108行目相当）にも同内容を英訳して追記する。他の行の英訳文体（simple, direct）に合わせること。例:

| Hook | Trigger | What it prevents |
| --- | --- | --- |
| `backup-secret-json.sh` | PreToolUse `Edit\|Write` | Backs up `secrets/**/*.json.age` before it gets overwritten (a safety net, not a block; keeps only the last 5 generations) |

### 実装順序

1. `.claude/hooks/backup-secret-json.sh`（新規、実行権限付与）
2. `zsh -n .claude/hooks/backup-secret-json.sh` で構文確認
3. `.claude/settings.json`（配線追加、JSON 構文を目視確認）
4. `docs-agents/harness-guide.md`（表に1行追加）
5. `docs-agents/harness-guide.en.md`（対応する英訳を1行追加）
