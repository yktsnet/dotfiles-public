handle_event() {
  WS_DATA=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | "\(.specialWorkspace.name) \(.activeWorkspace.id)"')
  
  SPECIAL_WS=$(echo "$WS_DATA" | cut -d' ' -f1)
  ACTIVE_WS_ID=$(echo "$WS_DATA" | cut -d' ' -f2)

  COLOR_TEAL="rgba(5de4c7ff)"
  COLOR_S="rgba(fffac2ff)"
  COLOR_DEF="rgba(a6accdff)"

  # 特殊ワークスペース判定（s1, s2, s3, s4 すべてを対象）
  if [ -n "$SPECIAL_WS" ] && [ "$SPECIAL_WS" != "null" ] && [ "$SPECIAL_WS" != "" ]; then
    hyprctl keyword general:col.active_border "$COLOR_S"
  else
    # メインワークスペース（4, 5, 6, 7）判定
    case "$ACTIVE_WS_ID" in
      4|5|6|7)
        hyprctl keyword general:col.active_border "$COLOR_TEAL"
        ;;
      *)
        hyprctl keyword general:col.active_border "$COLOR_DEF"
        ;;
    esac
  fi
}

handle_event

SOCAT_PATH="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"

socat -U - UNIX-CONNECT:"$SOCAT_PATH" | while read -r line; do
  case "$line" in
    "workspace>>"*) handle_event ;;
    "activespecial>>"*) handle_event ;;
    "focusedmon>>"*) handle_event ;;
  esac
done
