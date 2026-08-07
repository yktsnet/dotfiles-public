#!/usr/bin/env bash
# PreToolUse hook (Edit|Write): secrets/**/*.json.age を上書きする直前にバックアップを取る。
# settings.json は secrets/ 配下を deny しているが、JSON 形式（*.json.age）だけは
# Read/Edit/Write を許可している（常に sops の暗号文であり平文が見えないため）。
# その例外を踏むのがこのフック。Agent が暗号文を壊す編集をしても、
# *.json.age.bak.<timestamp> から復元できる状態を保つ。
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
