import os
import subprocess
import sys

HIST_FILE = os.path.expanduser("~/.local/share/ranger/fzf_history")


def save(path):
    if not path or not os.path.exists(path):
        return
    lines = []
    if os.path.exists(HIST_FILE):
        with open(HIST_FILE, "r") as f:
            lines = [l.strip() for l in f.readlines() if l.strip()]

    if path in lines:
        lines.remove(path)
    lines.insert(0, path)

    os.makedirs(os.path.dirname(HIST_FILE), exist_ok=True)
    with open(HIST_FILE, "w") as f:
        f.write("\n".join(lines[:100]))


def pick():
    if not os.path.exists(HIST_FILE):
        return None

    cmd = f"cat {HIST_FILE} | fzf --exact --height 70% --reverse --preview 'bat --color=always --style=numbers --line-range=:500 {{}}'"
    try:
        selected = subprocess.check_output(cmd, shell=True).decode().strip()
        return selected
    except subprocess.CalledProcessError:
        return None


if __name__ == "__main__":
    if len(sys.argv) > 2 and sys.argv[1] == "save":
        save(sys.argv[2])
    else:
        selected = pick()
        if selected:
            print(selected)
