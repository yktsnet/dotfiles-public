#!/usr/bin/env bash
# PreToolUse hook (Bash): Nix 外パッケージマネージャでのインストールを拒否する。
# プレフィックス型 deny ルールと違い、パス付き実行（/tmp/venv/bin/pip 等）や
# 複合コマンド内のインストールも捕捉する。quote 内の文言（commit message 等）は
# 除去してから判定し、コマンド位置（行頭または ; | & ` $( の後）のみマッチさせる。
cmd=$(jq -r '.tool_input.command // ""')
stripped=$(printf '%s' "$cmd" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

pre='(^|[;&|`]|\$\()[[:space:]]*(sudo[[:space:]]+)?(env[[:space:]]+)?([[:alnum:]@/_.~+-]*/)?'
mgr='(pip3?[[:space:]]+install|pipx[[:space:]]+install|python3?[[:space:]]+-m[[:space:]]+pip[[:space:]]+install|uv[[:space:]]+pip[[:space:]]+install|brew[[:space:]]+(install|reinstall|upgrade|tap)|cargo[[:space:]]+install|gem[[:space:]]+install|yarn[[:space:]]+global[[:space:]]+add|(npm|pnpm)[[:space:]]+(install|i|add)[^;|&]*[[:space:]](-g|--global)([[:space:]]|$))'

if printf '%s' "$stripped" | grep -Eq "$pre$mgr"; then
  cat <<'EOF'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"このフリートは全デバイス Nix 管理。pip / brew / npm -g / cargo / gem での直接インストールは禁止（venv 内でも同様）。nix-tool-install スキルを読み、用途に応じて nix run / nix shell / home.nix / リポの shell.nix で導入すること。一時的な Python 依存は例: nix-shell -p \"python3.withPackages (ps: [ ps.pyyaml ps.fastapi ])\" --run '...' を使う。"}}
EOF
fi
exit 0
