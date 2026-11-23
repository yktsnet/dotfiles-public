#!/usr/bin/env bash
# PostToolUse hook (Edit|Write|NotebookEdit): 編集直後にその1ファイルの構文と機械検査できる規約を調べる。
#
# 各リポの CLAUDE.md は py_compile / nix-instantiate --parse を「静的チェックの手段」として
# 挙げているが、実行はモデルの裁量任せで、忘れても誰も気付かない。壊れた .nix を掴んだまま
# セッションが終わると、次に気付くのは CI（nix-eval）か user の rebuild になる。
# その1往復を編集直後に前倒しし、CLAUDE.md のうち誤検知なく機械判定できる規約もここで止める。
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

check_zsh_conventions() {
  local f="$1"
  case "$f" in
    */00archive/*|*/tests/*|*/os.sh) return 0 ;;
    */home-manager/modules/zsh/functions/*.sh) ;;
    *) return 0 ;;
  esac

  local n=0 line=""
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n + 1))
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ (^|[^[:alnum:]_])(uname|xdg-open)($|[^[:alnum:]_]) ]] \
      || [[ "$line" =~ (^|[^[:alnum:]_])sed[[:space:]]+-i ]] \
      || [[ "$line" == *'$OSTYPE'* ]]; then
      fail "zsh 規約違反（$f:$n）" \
        "OS 差は os.sh のシム（_is_darwin / _sed_i / _open / _linux_only）を通す。関数本体に uname / \$OSTYPE / sed -i / xdg-open を直接書かない。"
    fi
  done < "$f"
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
    # zsh 用と bash 用で通る構文が違う。shebang が無い場合は home-manager/modules/zsh 配下のみ
    # zsh とみなし、判断できないものは検査しない（誤検出で偽の修正を誘発しないため）
    shebang=$(head -n 1 "$file_path")
    case "$shebang:$file_path" in
      *zsh*:*) shell=zsh ;;
      *bash*:*) shell=bash ;;
      *:*/home-manager/modules/zsh/*) shell=zsh ;;
      *) shell="" ;;
    esac
    if [ -n "$shell" ] && command -v "$shell" >/dev/null 2>&1; then
      out=$("$shell" -n "$file_path" 2>&1) \
        || fail "$shell -n が失敗（$file_path）" "$out"
    fi
    check_zsh_conventions "$file_path"
    ;;
esac

exit 0
