c() {
  emulate -L zsh

  print "claude — how to launch?"
  print "  1) sonnet mid   claude --model sonnet --effort medium --permission-mode auto"
  print "  2) opus low     claude --model opus --effort low --permission-mode auto"
  print "  3) history      claude-history --resume"
  local choice
  read -r "choice?select> "
  print ""

  # 画面レイアウトの責務は持たず、今いるペインで起動する（並行させたい場合は M-/ や M-t で
  # 場所を先に作る）。裏に回った Claude へは M-u のピッカーが loose ペインとして拾ってくれる。
  case "$choice" in
    1) claude --model sonnet --effort medium --permission-mode auto ;;
    2) claude --model opus --effort low --permission-mode auto ;;
    3) claude-history --resume ;;
    *) print "c: cancelled" >&2; return 1 ;;
  esac
}

i() {
  emulate -L zsh

  print "issue — which step?"
  print "  1) open    issue-open   (draft → open)"
  print "  2) run     issue        (open → implement)"
  print "  3) finish  issue-finish (implement → PR)"
  print "  4) abort   issue-abort  (discard in-progress issue)"
  local choice
  read -r "choice?select> "
  print ""

  case "$choice" in
    1)
      issue-open || return $?
      local run_now
      read -r "run_now?continue to implement? [y/N] "
      [[ "$run_now" == [yY]* ]] && issue -a
      ;;
    2) issue -a ;;
    3) issue-finish ;;
    4) issue-abort ;;
    *) print "i: cancelled" >&2; return 1 ;;
  esac
}
