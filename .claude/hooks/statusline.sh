#!/usr/bin/env bash
# statusLine: cwd/branch, context usage, 5h/7d rate-limit usage
input=$(cat)

get() { jq -r "$1 // empty" <<<"$input"; }

model=$(get '.model.display_name')
dir=$(get '.workspace.current_dir')
[ -z "$dir" ] && dir=$(get '.cwd')
dir_name=$(basename "${dir:-.}")
branch=$(git -C "${dir:-.}" branch --show-current 2>/dev/null)

ctx_pct=$(get '.context_window.used_percentage')
five_pct=$(get '.rate_limits.five_hour.used_percentage')
five_reset=$(get '.rate_limits.five_hour.resets_at')
week_pct=$(get '.rate_limits.seven_day.used_percentage')
week_reset=$(get '.rate_limits.seven_day.resets_at')

remain() {
  local reset="$1"
  [ -z "$reset" ] && return
  local diff=$(( reset - $(date +%s) ))
  (( diff < 0 )) && diff=0
  local days=$(( diff / 86400 ))
  local hours=$(( (diff % 86400) / 3600 ))
  local mins=$(( (diff % 3600) / 60 ))
  if (( days > 0 )); then
    printf '%dd%02dh' "$days" "$hours"
  else
    printf '%dh%02dm' "$hours" "$mins"
  fi
}

# poimandres theme: green/yellow/red by usage tier
color_for() {
  local pct="${1%.*}"
  if (( pct >= 90 )); then printf '#[fg=#d0679d]'
  elif (( pct >= 70 )); then printf '#[fg=#fffac2]'
  else printf '#[fg=#5de4c7]'
  fi
}
default_style='#[fg=#a6accd]'

line="${dir_name}${branch:+:${branch}} [${model:-?}]"
[ -n "$ctx_pct" ] && line="${line} ctx:${ctx_pct%.*}%"
[ -n "$five_pct" ] && line="${line} 5h:${five_pct%.*}%($(remain "$five_reset"))"
[ -n "$week_pct" ] && line="${line} 7d:${week_pct%.*}%($(remain "$week_reset"))"

echo "$line"

# tmux status-right 用: 5h/7d(アカウント単位)だけ色付きでキャッシュする
if [ -n "$five_pct" ] || [ -n "$week_pct" ]; then
  cache_dir="$HOME/.cache/claude"
  mkdir -p "$cache_dir"
  tmux_line=""
  if [ -n "$five_pct" ]; then
    tmux_line="$(color_for "$five_pct")5h ${five_pct%.*}%${default_style} ($(remain "$five_reset"))"
  fi
  if [ -n "$week_pct" ]; then
    week_part="$(color_for "$week_pct")7d ${week_pct%.*}%${default_style} ($(remain "$week_reset"))"
    tmux_line="${tmux_line:+${tmux_line}  }${week_part}"
  fi
  echo "$tmux_line" > "$cache_dir/tmux-status.txt.tmp" && mv "$cache_dir/tmux-status.txt.tmp" "$cache_dir/tmux-status.txt"
fi
