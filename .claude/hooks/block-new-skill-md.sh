#!/usr/bin/env bash
# PreToolUse hook (Write): 新規 SKILL.md がフリートの規約を満たしているか検査する。
#
# 目的は「規約に沿った skill を作らせること」であって、特定ツールの経由を強制すること
# ではない。以前は skill-creator の呼び出しを必須にしていたが、当該プラグインは未
# インストールでも動作する環境があり、規約を満たしていても通れない状態になっていた。
# そのため、経路ではなく内容を検査する方式に変更した。
#
# 検査するのは Write による新規作成のみ。既存 SKILL.md の修正は Edit 経由なので対象外。
# ただしシェル経由（cat > SKILL.md 等）だと Write を通らず検査を素通りするため、Bash も見る。
# stdin は一度しか読めないので、先に全体を受けてから個別に取り出す
payload=$(cat)
tool_name=$(printf '%s' "$payload" | jq -r '.tool_name // ""')
file_path=$(printf '%s' "$payload" | jq -r '.tool_input.file_path // ""')
content=$(printf '%s' "$payload" | jq -r '.tool_input.content // ""')

decide() {
  jq -n --arg d "$1" --arg reason "$2" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: $d,
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}
deny() { decide deny "$1"; }
ask() { decide ask "$1"; }

if [ "$tool_name" = "Bash" ]; then
  cmd=$(printf '%s' "$payload" | jq -r '.tool_input.command // ""')
  printf '%s' "$cmd" | grep -Eq '(>|tee|cp|mv|install)[^|&;]*SKILL\.md' || exit 0
  deny "$(cat <<'EOF'
SKILL.md をシェル経由で作成・上書きしない。Write / Edit ツールを使うこと。

このフリートでは skill の配置先（global = ~/dotfiles/.claude/skills/ か、repo-local か）と
frontmatter の規約を PreToolUse hook が検査している。シェル経由の書き込みはその検査を
素通りするため、規約違反や配布先（~/.claude/skills/）への直接作成を止められない。
EOF
)"
fi

case "$file_path" in
  */SKILL.md|SKILL.md) ;;
  *) exit 0 ;;
esac

# ~/.claude/skills/ は home-manager が ~/dotfiles/.claude/skills/ から rebuild のたびに
# 丸ごと上書き配布する場所であり正本ではない（正本に直接書いても次回 rebuild で消える）。
# 新規ファイルはここへの直接作成を禁止し、正本側に作らせる。
case "$file_path" in
  "$HOME"/.claude/skills/*)
    deny "$(cat <<'EOF'
~/.claude/skills/ への直接の新規作成は禁止。ここは home-manager が
~/dotfiles/.claude/skills/ から rebuild のたびに丸ごと上書き配布する場所で、正本ではない
（直接書いても次回 rebuild で消える）。

全リポ横断で使う skill なら ~/dotfiles/.claude/skills/<name>/SKILL.md に作成すること。
リポ固有の skill なら、そのリポの .claude/skills/<name>/SKILL.md に作成すること。
EOF
)"
    ;;
esac

# 既存ファイルの上書きは対象外
if [ -f "$file_path" ]; then
  exit 0
fi

# repo-local への新規作成は禁止ではないが、既定は global（~/dotfiles/.claude/skills/）。
# 「そのリポでしか意味を持たないか」の判断は機械的に決められないので user に投げる。
case "$file_path" in
  "$HOME"/dotfiles/.claude/skills/*) ;;
  */.claude/skills/*)
    ask "$(cat <<EOF
repo-local な場所に新規 skill を作ろうとしている:
  ${file_path}

このフリートの既定は global（~/dotfiles/.claude/skills/<name>/SKILL.md）で、そこに置けば
全リポから使える。repo-local が正しいのは、そのリポの構造・ツールチェーンに依存していて
他リポで動かない場合だけ。判断の基準は skill-dev skill を参照。

このまま repo-local に作ってよいか確認すること。
EOF
)"
    ;;
esac

# frontmatter を取り出す（先頭 --- から次の --- まで）
frontmatter=$(printf '%s\n' "$content" | awk '
  NR==1 && $0=="---" { inside=1; next }
  inside && $0=="---" { exit }
  inside { print }
')

if [ -z "$frontmatter" ]; then
  deny "SKILL.md に YAML frontmatter がない。先頭に --- で囲んだ name / description を書くこと。"
fi

printf '%s\n' "$frontmatter" | grep -q '^name:' \
  || deny "frontmatter に name: がない。skill 名（ディレクトリ名と一致させる）を書くこと。"

printf '%s\n' "$frontmatter" | grep -q '^description:' \
  || deny "frontmatter に description: がない。何をする skill か・いつ使うかを書くこと（発火判定に使われる）。"

# フリート既定: 明示呼び出し専用にする。
# 自動発火させたい場合は user が明示的に指示したうえで、この行を外して作成する。
if ! printf '%s\n' "$frontmatter" | grep -qE '^(disable-model-invocation|manual):[[:space:]]*true'; then
  deny "$(cat <<'EOF'
frontmatter に disable-model-invocation: true がない。

このフリートでは skill は明示呼び出し専用を既定とする。自動発火させたい場合のみ、
user に確認したうえでこの行を外して作成すること。

あわせて、作成前に以下を満たしているか確認する:
(1) global (~/dotfiles/.claude/skills) と repo-local (該当リポの .claude/skills) の
    両方を検索し、類似 skill が無いこと
(2) 手続き型・チェックリスト型 skill（客観的に検証可能な出力を持たないもの）は
    テストケース作成・評価ループを省略し、ドラフトをそのまま使ってよい
EOF
)"
fi

exit 0
