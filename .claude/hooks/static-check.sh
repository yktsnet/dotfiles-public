#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|NotebookEdit): 編集直後にその1ファイルだけ構文検査する。
#
# 各リポの CLAUDE.md は py_compile / nix-instantiate --parse を「静的チェックの手段」として
# 挙げているが、実行はモデルの裁量任せで、忘れても誰も気付かない。壊れた .nix を掴んだまま
# セッションが終わると、次に気付くのは CI（nix-eval）か user の rebuild になる。
# その1往復を編集直後に前倒しする。
#
# 検査に失敗したときだけ exit 2（stderr がモデルに戻る）。成功時は無言。
input=$(cat)
file_path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""')

[ -n "$file_path" ] || exit 0
[ -f "$file_path" ] || exit 0

fail() {
  printf 'static-check: %s\n%s\n' "$1" "$2" >&2
  exit 2
}

case "$file_path" in
  *.py)
    command -v python3 >/dev/null 2>&1 || exit 0
    # __pycache__ をリポに落とさない
    out=$(PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/claude-pycache" python3 -m py_compile "$file_path" 2>&1) \
      || fail "python3 -m py_compile が失敗（$file_path）" "$out"
    ;;
  *.nix)
    command -v nix-instantiate >/dev/null 2>&1 || exit 0
    out=$(nix-instantiate --parse "$file_path" 2>&1 >/dev/null) \
      || fail "nix-instantiate --parse が失敗（$file_path）" "$out"
    ;;
  *.sh)
    # zsh 用と bash 用で通る構文が違う。shebang が無い場合は dotfiles/zsh 配下のみ
    # zsh とみなし、判断できないものは検査しない（誤検出で偽の修正を誘発しないため）
    shebang=$(head -n 1 "$file_path")
    case "$shebang:$file_path" in
      *zsh*:*) shell=zsh ;;
      *bash*:*) shell=bash ;;
      *:*/dotfiles/zsh/*) shell=zsh ;;
      *) exit 0 ;;
    esac
    command -v "$shell" >/dev/null 2>&1 || exit 0
    out=$("$shell" -n "$file_path" 2>&1) \
      || fail "$shell -n が失敗（$file_path）" "$out"
    ;;
esac

exit 0
