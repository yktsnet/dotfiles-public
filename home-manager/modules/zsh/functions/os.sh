# OS 差の吸収。関数の中からだけ呼ぶ（initContent の連結順に依存させない）。
# NixOS と macOS で実質的に割れるのは BSD/GNU の sed -i 書式、既定アプリでの開き方、
# そして Linux のハードウェア・systemd を直に叩く関数だけである。その差をここに閉じ込め、
# functions/ の他のファイルは両 OS が同一のものを読む。
_is_darwin() {
  [[ "$OSTYPE" == darwin* ]]
}

# sed -i: GNU は引数なし、BSD は空文字のバックアップ拡張子が要る
_sed_i() {
  if _is_darwin; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

# URL・ファイルを既定アプリで開く
_open() {
  if _is_darwin; then
    open "$@"
  else
    xdg-open "$@"
  fi
}

# Linux のハード・systemd・NetworkManager を直に叩く関数の冒頭で使う。
# darwin では黙って壊れず、何に依存しているかを出して抜ける。引数はその依存先
_linux_only() {
  if _is_darwin; then
    print -u2 "${funcstack[2]}: Linux 専用（$1）"
    return 1
  fi
}
