c() {
  emulate -L zsh

  print "claude — how to launch?"
  print "  1) sonnet mid   claude --model sonnet --effort medium --permission-mode auto"
  print "  2) opus low     claude --model opus --effort low --permission-mode auto"
  print "  3) history      claude-history --resume"
  local choice
  read -r "choice?select> "
  print ""

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
    1) issue-open ;;
    2) issue ;;
    3) issue-finish ;;
    4) issue-abort ;;
    *) print "i: cancelled" >&2; return 1 ;;
  esac
}
