skill() {
  emulate -L zsh

  local skills_dir="$HOME/dotfiles/.claude/skills"
  local candidates=()
  local f name

  for f in "$skills_dir"/*/SKILL.md(N); do
    grep -q '^manual: true' "$f" || continue
    name=$(grep '^name:' "$f" | head -1 | sed 's/^name:[[:space:]]*//')
    candidates+=("$name")
  done

  if [[ ${#candidates[@]} -eq 0 ]]; then
    echo "No manual skills found" >&2
    return 1
  fi

  local selected
  selected=$(printf '%s\n' "${candidates[@]}" \
    | fzf --prompt="Skill: " \
          --preview="cat $skills_dir/{}/SKILL.md")

  [[ -z "$selected" ]] && return 0

  claude "/${selected}"
}
