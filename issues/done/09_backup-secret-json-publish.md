## PR記録: feat: secrets バックアップ用 PreToolUse フック backup-secret-json.sh を公開反映
issue: 09 (09_backup-secret-json-publish.md)
PR: https://github.com/yktsnet/dotfiles-public/pull/32
Merged: d0caed71e90055b4cb0623e723877c39dd1a00fc

## 変更内容
私物 `~/dotfiles` の `.claude/hooks/backup-secret-json.sh`（`secrets/**/*.json.age` を Edit/Write で上書きする直前にバックアップを取る PreToolUse フック）を dotfiles-public に反映した。`.claude/settings.json` の `hooks.PreToolUse`（`Edit|Write` マッチャー、既存の `block-live-claude-config-edit.sh` / `block-project-scoped-memory.sh` と並ぶブロック）に配線を追加し、`docs-agents/harness-guide.md` / `.en.md` のフック一覧表に1行ずつ追記した。

## 保証
なし（フックスクリプト追加であり、動作保証は user が実際の `secrets/**/*.json.age` 編集時に目視確認する。裏付けるテストはリポに存在せず、`zsh -n` は構文チェックのみ）

## 静的確認結果
- `zsh -n .claude/hooks/backup-secret-json.sh`: 構文OK
- `python3 -m json.tool .claude/settings.json`: JSON構文OK、配線位置は既存2件（`block-live-claude-config-edit.sh` / `block-project-scoped-memory.sh`）と同じ `Edit|Write` ブロック内に追加
- `harness-guide.md` / `.en.md`: 表の末尾（`opus-scope-and-concision.sh` 行の後）に既存行と同じ書式・文体で追記済み
- `nix flake check`: 対象外（Nix ファイル変更なし）
- `git diff --name-only --cached`:
  .claude/hooks/backup-secret-json.sh
  .claude/settings.json
  docs-agents/harness-guide.en.md
  docs-agents/harness-guide.md
  → issue の「対象」フィールドと完全一致

## 検証手順
実際の `secrets/**/*.json.age` 編集時にバックアップ（`*.bak.<timestamp>`、直近5世代保持）が生成されることを user が目視確認する。
