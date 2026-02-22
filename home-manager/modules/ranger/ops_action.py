import subprocess


def execute_target(fm, target_path):
    ext = target_path.split(".")[-1] if "." in target_path else ""
    cmd = ""
    if ext == "py":
        cmd = f"$(nix-build --no-out-link -E 'with import <nixpkgs> {{}}; python3.withPackages (ps: with ps; [ pandas numpy requests ])')/bin/python3 '{target_path}'"
    elif ext == "sh":
        cmd = f"chmod +x '{target_path}' && '{target_path}'"
    elif ext == "nix":
        cmd = f"sudo nixos-rebuild dry-activate --flake .#$(hostname -s) 2>&1 | grep -E 'would activate|Done|error:' && echo 'Nix Configuration: Valid'"
    else:
        cmd = f"echo 'No rule for {target_path}'"

    full_cmd = f"clear; echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'; echo ' 🚀 Execution / Analysis: {target_path}'; echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'; {cmd}; echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'; read -n 1 -s -p 'Press any key to return...'"

    fm.ui.suspend()
    try:
        subprocess.run(["/bin/sh", "-c", full_cmd])
    finally:
        fm.ui.initialize()


def sync_targets(fm, selection):
    if not selection:
        fm.notify("Error: No files selected. Use [Space].", bad=True)
        return

    files_str = " ".join(f"'{f.path}'" for f in selection)
    cmd = f"rsync -avzPL --exclude='.git' --exclude='.direnv' {files_str} <REMOTE_USER>@<REMOTE_HOST>:~/dotfiles/"
    full_cmd = f"clear; echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'; echo ' 🚀 Syncing to remote...'; {cmd}; echo '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━'; read -n 1 -s -p 'Press any key to return...'"

    fm.ui.suspend()
    try:
        subprocess.run(["/bin/sh", "-c", full_cmd])
    finally:
        fm.ui.initialize()
