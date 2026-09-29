# 選択 UI と y/N 確認の共通実装。
# 各関数が fzf 呼び出しと read を個別に書くと、既定値（Enter だけ押したとき）や
# Esc / Ctrl-C の扱いが関数ごとに割れる。破壊的な操作でどちらに転ぶか読めなくなるため1本に寄せる。

# 使い方:
#   choice=$(_pick "prompt" "key1<TAB>label1" "key2<TAB>label2") || return 1
# key と label はタブ区切り。選ばれた key だけが stdout に出る。
_pick() {
  emulate -L zsh
  local prompt="$1"
  shift

  local sel
  sel=$(printf '%s\n' "$@" \
    | fzf --prompt="${prompt}> " \
          --delimiter=$'\t' --with-nth=2..) || return 1
  [[ -z "$sel" ]] && return 1

  printf '%s\n' "${sel%%$'\t'*}"
}

# 使い方:
#   _confirm "delete branch?" || return 0     # 既定 No
#   _confirm "continue?" y || return 0        # 既定 Yes
_confirm() {
  emulate -L zsh
  local msg="$1"
  local default="${2:-n}"

  local hint="[y/N]"
  [[ "$default" == [yY] ]] && hint="[Y/n]"

  local ans
  print -n "${msg} ${hint}: "
  # 読み取り自体が失敗する（Ctrl-D / 非対話）ときは既定値に倒す
  read -r ans || ans=""
  [[ -z "$ans" ]] && ans="$default"

  [[ "$ans" == [yY]* ]]
}
